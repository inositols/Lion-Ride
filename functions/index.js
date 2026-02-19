const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggered when a new ride is created in the 'rides' collection.
 * Sends a push notification to all online riders.
 */
exports.notifyRidersOnNewRequest = functions.firestore
    .document("rides/{rideId}")
    .onCreate(async (snapshot, context) => {
      const rideData = snapshot.data();
      const rideId = context.params.rideId;

      // 1. Check if the ride status is 'searching'
      if (rideData.status !== "searching") {
        console.log(`Ride ${rideId} created with status: ${rideData.status}. Skipping notification.`);
        return null;
      }

      console.log(`Processing new ride request: ${rideId}`);

      try {
        // 2. Extract ride details
        const pickupAddress = rideData.pickup_address || "Unknown Location";
        const dropoffAddress = rideData.dropoff_address || "Unknown Location";
        const cost = rideData.cost || 0;

        // 3. Fetch all online riders with FCM tokens
        const ridersSnapshot = await admin.firestore()
            .collection("users")
            .where("role", "==", "rider")
            .where("is_online", "==", true)
            .get();

        if (ridersSnapshot.empty) {
          console.log("No online riders available at the moment.");
          return null;
        }

        const fcmTokens = [];
        ridersSnapshot.forEach((doc) => {
          const riderData = doc.data();
          if (riderData.fcm_token) {
            fcmTokens.push(riderData.fcm_token);
          }
        });

        if (fcmTokens.length === 0) {
          console.log("Online riders found, but none have FCM tokens.");
          return null;
        }

        console.log(`Sending notifications to ${fcmTokens.length} riders.`);

        // 4. Construct the multicast message
        const message = {
          notification: {
            title: "🔔 New Ride Request!",
            body: `Pickup at ${pickupAddress} for ₦${cost}`,
          },
          data: {
            rideId: rideId,
            type: "new_ride_request",
            pickup: pickupAddress,
            dropoff: dropoffAddress,
          },
          tokens: fcmTokens,
        };

        // 5. Send message multicast
        const response = await admin.messaging().sendEachForMulticast(message);

        console.log(`${response.successCount} messages were sent successfully.`);
        
        if (response.failureCount > 0) {
          console.log(`${response.failureCount} messages failed.`);
          
          // Cleanup invalid tokens if necessary
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const error = resp.error;
              if (error.code === 'messaging/invalid-registration-token' ||
                  error.code === 'messaging/registration-token-not-registered') {
                console.log(`Token at index ${idx} is no longer valid.`);
                // Note: You could delete the token from Firestore here if needed
              } else {
                console.error(`Error sending to token at index ${idx}:`, error);
              }
            }
          });
        }

        return null;
      } catch (error) {
        console.error("Critical error in notifyRidersOnNewRequest:", error);
        return null;
      }
    });

/**
 * Optional: Delete stale tokens
 * Note: Decided not to implement automatic deletion in this MVP for safety.
 * Logging is provided instead.
 */
