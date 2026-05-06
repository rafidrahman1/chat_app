const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendChatNotification = onDocumentCreated(
  "chatRooms/global_chat_room/messages/{messageId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("No message snapshot found in trigger event.");
      return;
    }

    const message = snapshot.data();
    if (!message) {
      logger.warn("Message payload is empty.");
      return;
    }

    const senderId = message.senderId ? String(message.senderId) : "";
    const content = message.content ? String(message.content) : "";
    const preview = content.length > 120 ? `${content.substring(0, 117)}...` : content;

    const usersSnap = await admin
      .firestore()
      .collection("users")
      .where("fcmToken", "!=", null)
      .get();

    const tokens = [];
    for (const doc of usersSnap.docs) {
      if (doc.id === senderId) continue;
      const token = doc.get("fcmToken");
      if (typeof token === "string" && token.trim().length > 0) {
        tokens.push(token);
      }
    }

    if (tokens.length === 0) {
      logger.info("No recipient FCM tokens found.");
      return;
    }

    const multicastMessage = {
      tokens,
      notification: {
        title: "New chat message",
        body: preview || "You received a new message",
      },
      data: {
        type: "chat_message",
        screen: "chat",
        senderId,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "chat_messages",
        },
      },
      apns: {
        headers: {
          "apns-priority": "10",
        },
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(multicastMessage);
    logger.info("Chat push send result", {
      successCount: response.successCount,
      failureCount: response.failureCount,
    });

    if (response.failureCount > 0) {
      response.responses.forEach((r, i) => {
        if (!r.success) {
          logger.warn("Token send failed", { token: tokens[i], error: r.error?.message });
        }
      });
    }
  }
);
