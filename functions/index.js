const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

function chunk(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

exports.onNewChatMessage = functions.firestore
  .document("chatRooms/{roomId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};

    const senderId = (data.senderId || "").toString();
    const content = (data.content || "").toString();
    const msgId = data.msgId != null ? String(data.msgId) : context.params.messageId;
    const roomId = (context.params.roomId || "").toString();

    // Collect all FCM tokens for users and separate sender from recipients.
    const usersSnap = await admin.firestore().collection("users").get();
    const recipientTokens = new Set();
    const senderTokens = new Set();

    usersSnap.forEach((doc) => {
      const fcmTokens = doc.get("fcmTokens");
      if (!Array.isArray(fcmTokens)) return;
      for (const t of fcmTokens) {
        const token = (t || "").toString().trim();
        if (!token) continue;
        if (doc.id === senderId) {
          senderTokens.add(token);
        } else {
          recipientTokens.add(token);
        }
      }
    });

    let tokenList = Array.from(recipientTokens);
    if (tokenList.length === 0 && senderTokens.size > 0) {
      // Useful for solo testing where only the sender has a valid token.
      tokenList = Array.from(senderTokens);
      console.log("No recipient tokens found; using sender tokens for fallback delivery.");
    }

    if (tokenList.length === 0) {
      console.log("No FCM tokens available for delivery.");
      return null;
    }

    const title = "New chat message";
    const body = content || "You received a new message";

    const messageBase = {
      notification: {
        title,
        body,
      },
      data: {
        senderId,
        msgId,
        roomId,
        title,
        body,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "chat_messages",
        },
      },
    };

    // Multicast limit is 500 tokens per request.
    const tokenChunks = chunk(tokenList, 500);
    const results = [];
    const failedTokens = [];

    for (const tokenChunk of tokenChunks) {
      const res = await admin.messaging().sendEachForMulticast({
        ...messageBase,
        tokens: tokenChunk,
      });
      results.push({
        successCount: res.successCount,
        failureCount: res.failureCount,
      });

      res.responses.forEach((response, index) => {
        if (!response.success) {
          failedTokens.push({
            token: tokenChunk[index],
            errorCode: response.error?.code || "unknown",
            errorMessage: response.error?.message || "unknown",
          });
        }
      });
    }

    console.log("FCM results:", results);
    if (failedTokens.length > 0) {
      console.log("FCM failed tokens:", failedTokens);
    }
    return null;
  });

