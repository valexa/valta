/**
 * Firebase Cloud Functions for sending push notifications
 *
 * Deploy with: firebase deploy --only functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Sends notification when manager assigns activity to team member
 */
exports.sendActivityAssignedNotification = functions.https.onCall(
    async (data, context) => {
      // Verify authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated",
        );
      }

      const {activityId, assignedMemberId, priority, message, activityName} =
        data;

      // Validate input
      if (!activityId || !assignedMemberId || !message) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required fields",
        );
      }

      try {
        // Get FCM token for assigned member
        const db = admin.firestore();
        const tokenDoc = await db
            .collection("fcmTokens")
            .doc(assignedMemberId)
            .get();

        if (!tokenDoc.exists) {
          console.warn(`No FCM token found for member: ${assignedMemberId}`);
          return {success: false, error: "No FCM token found"};
        }

        const tokenData = tokenDoc.data();
        const fcmToken = tokenData.token;

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
            priority: priority || "",
            activityName: activityName || "",
          },
          token: fcmToken,
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

        return {success: true, messageId: response};
      } catch (error) {
        console.error("❌ Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification",
            error,
        );
      }
    },
);

/**
 * Sends notification when team member starts activity
 * (to all team members)
 */
exports.sendActivityStartedNotification = functions.https.onCall(
    async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated",
        );
      }

      const {activityId, teamId, memberName, priority, message, activityName} =
        data;

      if (!activityId || !teamId || !message) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required fields",
        );
      }

      try {
        // Get all team members' FCM tokens
        const db = admin.firestore();
        const teamDoc = await db.collection("teams").doc(teamId).get();

        if (!teamDoc.exists) {
          throw new functions.https.HttpsError("not-found", "Team not found");
        }

        const teamData = teamDoc.data();
        const memberIds = teamData.members || [];

        // Get FCM tokens for all team members
        const tokens = [];
        for (const memberId of memberIds) {
          const tokenDoc = await db.collection("fcmTokens").doc(memberId).get();
          if (tokenDoc.exists) {
            tokens.push(tokenDoc.data().token);
          }
        }

        if (tokens.length === 0) {
          console.warn(`No FCM tokens found for team: ${teamId}`);
          return {success: false, error: "No FCM tokens found"};
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
        console.error("❌ Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification",
            error,
        );
      }
    },
);

/**
 * Sends notification when team member requests completion approval
 * (to manager)
 */
exports.sendCompletionRequestedNotification = functions.https.onCall(
    async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated",
        );
      }

      const {activityId, memberName, priority, message, activityName} = data;

      if (!activityId || !message) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required fields",
        );
      }

      try {
        // Get manager's FCM token
        // For now, we'll need to determine manager ID from activity/team
        // This is a placeholder - you'll need to implement manager lookup
        // For example: Get team from activity, then get manager from team
        // For now, we'll use a topic or store manager tokens separately

        // Placeholder: Send to a manager topic
        const topic = "managers";

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
          topic: topic,
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        const response = await admin.messaging().send(payload);
        console.log(`✅ Notification sent: ${response}`);

        return {success: true, messageId: response};
      } catch (error) {
        console.error("❌ Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification",
            error,
        );
      }
    },
);

/**
 * Sends notification when manager completes/approves activity
 * (to all team members)
 */
exports.sendActivityCompletedNotification = functions.https.onCall(
    async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated",
        );
      }

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

      if (!activityId || !teamId || !message) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required fields",
        );
      }

      try {
        // Get all team members' FCM tokens
        const db = admin.firestore();
        const teamDoc = await db.collection("teams").doc(teamId).get();

        if (!teamDoc.exists) {
          throw new functions.https.HttpsError("not-found", "Team not found");
        }

        const teamData = teamDoc.data();
        const memberIds = teamData.members || [];

        // Get FCM tokens for all team members
        const tokens = [];
        for (const memberId of memberIds) {
          const tokenDoc = await db.collection("fcmTokens").doc(memberId).get();
          if (tokenDoc.exists) {
            tokens.push(tokenDoc.data().token);
          }
        }

        if (tokens.length === 0) {
          console.warn(`No FCM tokens found for team: ${teamId}`);
          return {success: false, error: "No FCM tokens found"};
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
        console.error("❌ Error sending notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification",
            error,
        );
      }
    },
);
