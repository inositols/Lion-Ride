const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

/**
 * PHASE 2: SETTLEMENT LOGIC
 * Automatically triggers a Paystack bank transfer when a withdrawal is logged.
 */
exports.processWithdrawalSettlement = functions.firestore
  .document("transactions/{txId}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    const txId = context.params.txId;

    // Only process pending debit withdrawals
    if (data.type !== "debit" || data.status !== "pending") {
      return null;
    }

    console.log(`[Settlement] Processing withdrawal for txId: ${txId}`);

    try {
      const secretKey = process.env.PAYSTACK_SECRET_KEY || functions.config().paystack.key;
      if (!secretKey) {
        throw new Error("Paystack Secret Key not found in Environment.");
      }

      const bankDetails = data.metadata.bank_details; // Format expected: "Name | Account | BankCode"
      const [accountName, accountNumber, bankCode] = bankDetails.split("|").map(s => s.trim());

      // 1. Create Transfer Recipient
      const recipientResponse = await axios.post(
        "https://api.paystack.co/transferrecipient",
        {
          type: "nuban",
          name: accountName,
          account_number: accountNumber,
          bank_code: bankCode,
          currency: "NGN",
        },
        { headers: { Authorization: `Bearer ${secretKey}` } }
      );

      const recipientCode = recipientResponse.data.data.recipient_code;

      // 2. Initiate Transfer
      const transferResponse = await axios.post(
        "https://api.paystack.co/transfer",
        {
          source: "balance",
          amount: data.amount * 100, // Paystack uses Kobo
          recipient: recipientCode,
          reason: `Withdrawal for transaction ${txId}`,
        },
        { headers: { Authorization: `Bearer ${secretKey}` } }
      );

      const transferData = transferResponse.data.data;

      // 3. Update transaction as 'processing'
      return snapshot.ref.update({
        status: "processing",
        paystack_reference: transferData.reference,
        paystack_transfer_code: transferData.transfer_code,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

    } catch (error) {
      console.error(`[Settlement Error] ${txId}:`, error.response ? error.response.data : error.message);
      return snapshot.ref.update({
        status: "failed",
        error_message: error.response ? JSON.stringify(error.response.data) : error.message,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

/**
 * PAYSTACK WEBHOOK
 * Listens for Paystack's confirmation of the bank transfer status.
 */
exports.paystackWebhook = functions.https.onRequest(async (req, res) => {
  // TODO: Verify Paystack Signature for Production
  const event = req.body;

  if (event.event === "transfer.success" || event.event === "transfer.failed") {
    const transferData = event.data;
    const reference = transferData.reference;

    console.log(`[Webhook] Received ${event.event} for reference: ${reference}`);

    const txQuery = await admin.firestore()
      .collection("transactions")
      .where("paystack_reference", "==", reference)
      .limit(1)
      .get();

    if (txQuery.empty) {
      console.warn(`[Webhook] Transaction not found for reference: ${reference}`);
      return res.status(404).send("Transaction not found");
    }

    const txDoc = txQuery.docs[0];
    const newStatus = event.event === "transfer.success" ? "success" : "failed";

    await txDoc.ref.update({
      status: newStatus,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`[Webhook] txId ${txDoc.id} updated to ${newStatus}`);
  }

  return res.status(200).send("Event processed");
});

/**
 * ORIGINAL NOTIFICATION LOGIC
 */
exports.notifyRidersOnNewRequest = functions.firestore
  .document("rides/{rideId}")
  .onCreate(async (snapshot, context) => {
    const rideData = snapshot.data();
    const rideId = context.params.rideId;

    if (rideData.status !== "searching") return null;

    try {
      const pickupAddress = rideData.pickup_address || "Unknown Location";
      const cost = rideData.cost || 0;

      const ridersSnapshot = await admin.firestore()
        .collection("users")
        .where("role", "==", "rider")
        .where("is_online", "==", true)
        .get();

      if (ridersSnapshot.empty) return null;

      const fcmTokens = [];
      ridersSnapshot.forEach((doc) => {
        if (doc.data().fcm_token) fcmTokens.push(doc.data().fcm_token);
      });

      if (fcmTokens.length === 0) return null;

      const message = {
        notification: {
          title: "🔔 New Ride Request!",
          body: `Pickup at ${pickupAddress} for ₦${cost}`,
        },
        data: {
          rideId: rideId,
          type: "new_ride_request",
        },
        tokens: fcmTokens,
      };

      await admin.messaging().sendEachForMulticast(message);
      return null;
    } catch (error) {
      console.error("Critical error in notifyRidersOnNewRequest:", error);
      return null;
    }
  });
