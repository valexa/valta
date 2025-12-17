/**
 * Firebase Cloud Functions for sending push notifications
 *
 * Deploy with: firebase deploy --only functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// MARK: - Helpers

/**
 * Asserts that the user is authenticated.
 * @param {Object} context The callable context.
 * @throws {functions.https.HttpsError} If not authenticated.
 */
function assertAuthenticated(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated",
    );
  }
}

/**
 * Checks that required fields are present in data.
 * @param {Object} data The input data.
 * @param {Array<string>} fields List of required field names.
 * @throws {functions.https.HttpsError} If a field is missing.
 */
function checkRequired(data, fields) {
  for (const field of fields) {
    if (!data[field]) {
      throw new functions.https.HttpsError(
          "invalid-argument",
          "Missing required fields",
      );
    }
  }
}

/**
 * Standardized error handling.
 * @param {Error} error The error object.
 * @throws {functions.https.HttpsError} Always throws internal error.
 */
function handleError(error) {
  console.error("❌ Error sending notification:", error);
  if (error.stack) {
    console.error("Stack trace:", error.stack);
  }
  throw new functions.https.HttpsError(
      "internal",
      "Failed to send notification: " + error.message,
      error,
  );
}

/**
 * Fetches and filters valid FCM tokens for a list of member IDs.
 * @param {admin.firestore.Firestore} db Firestore instance.
 * @param {Array<string>} memberIds Array of member IDs.
 * @return {Promise<Array<string>>} Array of valid tokens.
 */
async function getTokensForMembers(db, memberIds) {
  const tokens = [];
  for (const memberId of memberIds) {
    try {
      const tokenDoc = await db.collection("fcmTokens").doc(memberId).get();
      if (tokenDoc.exists) {
        const t = tokenDoc.data().token;
        if (t) {
          tokens.push(t);
        }
      }
    } catch (e) {
      console.warn(`Failed to fetch token for member ${memberId}:`, e);
    }
  }
  return tokens;
}

/**
 * 1. Sends notification when manager assigns activity to team member
 * Recipient: Assigned team member
 */
exports.sendActivityAssignedNotification = functions.https.onCall(
    async (data, context) => {
      assertAuthenticated(context);
      checkRequired(data, ["activityId", "assignedMemberEmail", "assignedMemberName", "message"]);

      const {
        activityId,
        assignedMemberEmail,
        assignedMemberName,
        priority,
        message,
        activityName,
      } = data;

      try {
        const db = admin.firestore();
        console.log(`🔍 Looking up FCM token for member email: ${assignedMemberEmail}`);

        const tokens = await getTokensForMembers(db, [assignedMemberEmail]);

        if (tokens.length === 0) {
          console.warn(`No FCM token found for member: ${assignedMemberEmail}`);
          return {
            success: false,
            error: "No FCM token found for member",
          };
        }

        const payload = {
          notification: {
            title: "New Activity Assigned",
            body: message,
          },
          data: {
            type: "activity_assigned",
            activityId: activityId,
            assignedMemberEmail: assignedMemberEmail,
            assignedMemberName: assignedMemberName || "",
            priority: priority || "",
            activityName: activityName || "",
          },
          token: tokens[0],
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        };

        const response = await admin.messaging().send(payload);
        console.log(`✅ Notification sent: ${response}`);

        return {
          success: true,
          messageId: response,
        };
      } catch (error) {
        handleError(error);
      }
    },
);

/**
 * 2. Sends notification when team member starts activity
 * Recipient: Manager
 */
exports.sendActivityStartedNotification = functions.https.onCall(
    async (data, context) => {
      assertAuthenticated(context);
      checkRequired(data, ["activityId", "managerEmail", "message"]);

      const {
        activityId,
        managerEmail,
        memberName,
        priority,
        message,
        activityName,
      } = data;

      try {
        const db = admin.firestore();
        console.log(`🔍 Looking up FCM token for manager: ${managerEmail}`);

        const tokens = await getTokensForMembers(db, [managerEmail]);

        if (tokens.length === 0) {
          console.warn(`No FCM token found for manager: ${managerEmail}`);
          return {
            success: false,
            error: "No FCM token found for manager",
          };
        }

        const payload = {
          notification: {
            title: "Activity Started",
            body: message,
          },
          data: {
            type: "activity_started",
            activityId: activityId,
            memberName: memberName || "",
            priority: priority || "",
            activityName: activityName || "",
          },
          token: tokens[0],
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        };

        const response = await admin.messaging().send(payload);
        console.log(`✅ Notification sent to manager: ${response}`);

        return {
          success: true,
          messageId: response,
        };
      } catch (error) {
        handleError(error);
      }
    },
);

/**
 * 3. Sends notification when team member completes activity (requests approval)
 * Recipient: Manager
 */
exports.sendCompletionRequestedNotification = functions.https.onCall(
    async (data, context) => {
      assertAuthenticated(context);
      checkRequired(data, ["activityId", "message"]);

      const {
        activityId,
        memberName,
        priority,
        message,
        activityName,
        managerEmail,
      } = data;

      try {
        let token = null;

        if (managerEmail) {
          console.log(`🔍 Looking up FCM token for manager: ${managerEmail}`);
          const db = admin.firestore();
          const tokens = await getTokensForMembers(db, [managerEmail]);
          if (tokens.length > 0) {
            token = tokens[0];
          } else {
            console.warn(`⚠️ No FCM token found for manager: ${managerEmail}`);
          }
        }

        const payload = {
          notification: {
            title: "Activity Completed",
            body: message,
          },
          data: {
            type: "completion_requested",
            activityId: activityId,
            memberName: memberName || "",
            priority: priority || "",
            activityName: activityName || "",
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        };

        let response;
        if (token) {
          payload.token = token;
          response = await admin.messaging().send(payload);
          console.log(`✅ Targeted notification sent to manager ${managerEmail}: ${response}`);
        } else {
          console.log("⚠️ Falling back to 'managers' topic");
          payload.topic = "managers";
          response = await admin.messaging().send(payload);
          console.log(`✅ Topic notification sent: ${response}`);
        }

        return {
          success: true,
          messageId: response,
        };
      } catch (error) {
        handleError(error);
      }
    },
);

/**
 * 4. Sends notification when manager approves activity completion
 * Recipient: Assigned team member
 */
exports.sendActivityApprovedNotification = functions.https.onCall(
    async (data, context) => {
      assertAuthenticated(context);
      checkRequired(data, ["activityId", "recipientEmail", "message"]);

      const {
        activityId,
        recipientEmail,
        memberName,
        message,
        activityName,
      } = data;

      try {
        const db = admin.firestore();
        console.log(`🔍 Looking up FCM token for recipient: ${recipientEmail}`);
        const tokens = await getTokensForMembers(db, [recipientEmail]);

        if (tokens.length === 0) {
          console.warn(`No FCM token found for recipient: ${recipientEmail}`);
          return {
            success: false,
            error: "No FCM token found for recipient",
          };
        }

        const payload = {
          notification: {
            title: "Activity Approved",
            body: message,
          },
          data: {
            type: "activity_approved",
            activityId: activityId,
            memberName: memberName || "",
            activityName: activityName || "",
          },
          token: tokens[0],
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        };

        const response = await admin.messaging().send(payload);
        console.log(`✅ Approval notification sent to recipient: ${response}`);

        return {
          success: true,
          messageId: response,
        };
      } catch (error) {
        handleError(error);
      }
    },
);

/**
 * 5. Sends notification when manager rejects activity completion
 * Recipient: Assigned team member
 */
exports.sendActivityRejectedNotification = functions.https.onCall(
    async (data, context) => {
      assertAuthenticated(context);
      checkRequired(data, ["activityId", "recipientEmail", "message"]);

      const {
        activityId,
        recipientEmail,
        memberName,
        message,
        activityName,
      } = data;

      try {
        const db = admin.firestore();
        console.log(`🔍 Looking up FCM token for recipient: ${recipientEmail}`);
        const tokens = await getTokensForMembers(db, [recipientEmail]);

        if (tokens.length === 0) {
          console.warn(`No FCM token found for recipient: ${recipientEmail}`);
          return {
            success: false,
            error: "No FCM token found for recipient",
          };
        }

        const payload = {
          notification: {
            title: "Activity Sent Back",
            body: message,
          },
          data: {
            type: "activity_rejected",
            activityId: activityId,
            memberName: memberName || "",
            activityName: activityName || "",
          },
          token: tokens[0],
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        };

        const response = await admin.messaging().send(payload);
        console.log(`✅ Rejection notification sent to recipient: ${response}`);

        return {
          success: true,
          messageId: response,
        };
      } catch (error) {
        handleError(error);
      }
    },
);
