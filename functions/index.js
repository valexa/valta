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
 * Sends notification when manager assigns activity to team member
 */
exports.sendActivityAssignedNotification = functions.https.onCall(
    async (data, context) => {
      assertAuthenticated(context);
      checkRequired(data, ["activityId", "assignedMemberId", "assignedMemberName", "message"]);

      const {
        activityId,
        assignedMemberId,
        assignedMemberName,
        priority,
        message,
        activityName,
      } = data;

      try {
        const db = admin.firestore();
        console.log(`🔍 Looking up FCM token for member ID: ${assignedMemberId}`);

        const tokens = await getTokensForMembers(db, [assignedMemberId]);

        if (tokens.length === 0) {
          console.warn(`No FCM token found for member: ${assignedMemberId}`);
          return {
            success: false,
            error: "No FCM token found for member",
          };
        }

        // Prepare notification payload
        const payload = {
          notification: {
            title: "New Activity Assigned",
            body: message,
          },
          data: {
            type: "activity_assigned",
            activityId: activityId,
            assignedMemberId: assignedMemberId,
            assignedMemberName: assignedMemberName || "",
            priority: priority || "",
            activityName: activityName || "",
          },
          token: tokens[0],
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        // Send notification
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
 * Sends notification when team member starts activity
 * (to all team members)
 */
exports.sendActivityStartedNotification = functions.https.onCall(
    async (data, context) => {
      assertAuthenticated(context);
      checkRequired(data, ["activityId", "teamId", "message"]);

      const {
        activityId,
        teamId,
        memberName,
        priority,
        message,
        activityName,
      } = data;

      try {
        const db = admin.firestore();
        const teamDoc = await db.collection("teams").doc(teamId).get();

        if (!teamDoc.exists) {
          throw new functions.https.HttpsError("not-found", "Team not found");
        }

        const teamData = teamDoc.data();
        const memberIds = teamData.members || [];

        const tokens = await getTokensForMembers(db, memberIds);

        if (tokens.length === 0) {
          console.warn(`No FCM tokens found for team: ${teamId}`);
          return {
            success: false,
            error: "No FCM tokens found",
          };
        }

        // Prepare multicast message
        const multicastMessage = {
          notification: {
            title: "Activity Started",
            body: message,
          },
          data: {
            type: "activity_started",
            activityId: activityId,
            teamId: teamId,
            memberName: memberName || "",
            priority: priority || "",
            activityName: activityName || "",
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
          tokens: tokens,
        };

        // Send multicast notification
        const response = await admin
            .messaging()
            .sendEachForMulticast(multicastMessage);
        console.log(
            `✅ Sent ${response.successCount} notifications, ` +
        `${response.failureCount} failed`,
        );

        return {
          success: true,
          successCount: response.successCount,
          failureCount: response.failureCount,
        };
      } catch (error) {
        handleError(error);
      }
    },
);

/**
 * Sends notification when team member requests completion approval
 * (to manager)
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
        managerId,
      } = data;

      try {
        let token = null;

        // 1. Try targeted lookup if managerId is provided
        if (managerId) {
          console.log(`🔍 Looking up FCM token for manager: ${managerId}`);
          const db = admin.firestore();
          const tokens = await getTokensForMembers(db, [managerId]);
          if (tokens.length > 0) {
            token = tokens[0];
          } else {
            console.warn(`⚠️ No FCM token found for manager: ${managerId}`);
          }
        }

        // 2. Prepare payload
        const payload = {
          notification: {
            title: "Completion Request",
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
                badge: 1,
              },
            },
          },
        };

        // 3. Send notification
        let response;
        if (token) {
        // Send to specific device
          payload.token = token;
          response = await admin.messaging().send(payload);
          console.log(`✅ Targeted notification sent to manager ${managerId}: ${response}`);
        } else {
        // Fallback to topic if no managerId or token found
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
 * Sends notification when manager completes/approves activity
 * (to all team members)
 */
exports.sendActivityCompletedNotification = functions.https.onCall(
    async (data, context) => {
      assertAuthenticated(context);
      checkRequired(data, ["activityId", "teamId", "message"]);

      const {
        activityId,
        teamId,
        memberName,
        priority,
        outcome,
        statusColor,
        message,
        activityName,
      } = data;

      try {
        const db = admin.firestore();
        const teamDoc = await db.collection("teams").doc(teamId).get();

        if (!teamDoc.exists) {
          throw new functions.https.HttpsError("not-found", "Team not found");
        }

        const teamData = teamDoc.data();
        const memberIds = teamData.members || [];

        const tokens = await getTokensForMembers(db, memberIds);

        if (tokens.length === 0) {
          console.warn(`No FCM tokens found for team: ${teamId}`);
          return {
            success: false,
            error: "No FCM tokens found",
          };
        }

        // Prepare multicast message
        const multicastMessage = {
          notification: {
            title: "Activity Completed",
            body: message,
          },
          data: {
            type: "activity_completed",
            activityId: activityId,
            teamId: teamId,
            memberName: memberName || "",
            priority: priority || "",
            outcome: outcome || "",
            statusColor: statusColor || "",
            activityName: activityName || "",
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
          tokens: tokens,
        };

        // Send multicast notification
        const response = await admin
            .messaging()
            .sendEachForMulticast(multicastMessage);
        console.log(
            `✅ Sent ${response.successCount} notifications, ` +
        `${response.failureCount} failed`,
        );

        return {
          success: true,
          successCount: response.successCount,
          failureCount: response.failureCount,
        };
      } catch (error) {
        handleError(error);
      }
    },
);
