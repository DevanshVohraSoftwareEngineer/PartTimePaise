const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');

admin.initializeApp();

// Initialize Express app
const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Import our route handlers (we'll create these)
const authRoutes = require('./routes/auth');
const taskRoutes = require('./routes/tasks');
const swipeRoutes = require('./routes/swipes');
const matchRoutes = require('./routes/matches');
const notificationRoutes = require('./routes/notifications');

// API routes
app.use('/auth', authRoutes);
app.use('/tasks', taskRoutes);
app.use('/swipes', swipeRoutes);
app.use('/matches', matchRoutes);
app.use('/notifications', notificationRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Export the Express app as a Firebase Function
exports.api = functions.https.onRequest(app);

// Real-time triggers for Firestore
exports.onMatchCreated = functions.firestore
  .document('matches/{matchId}')
  .onCreate(async (snap, context) => {
    const match = snap.data();
    const matchId = context.params.matchId;

    // Send notification to worker
    if (match.workerId) {
      await admin.firestore().collection('notifications').add({
        userId: match.workerId,
        type: 'match',
        title: 'New Match!',
        message: 'You have a new task match. Start chatting!',
        matchId: matchId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Send notification to client
    if (match.clientId) {
      await admin.firestore().collection('notifications').add({
        userId: match.clientId,
        type: 'match',
        title: 'Match Found!',
        message: 'Someone is interested in your task!',
        matchId: matchId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

exports.onMessageSent = functions.firestore
  .document('matches/{matchId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const matchId = context.params.matchId;

    // Get match details
    const matchDoc = await admin.firestore().collection('matches').doc(matchId).get();
    const match = matchDoc.data();

    if (match) {
      // Determine recipient
      const recipientId = message.senderId === match.workerId ? match.clientId : match.workerId;

      // Send notification
      await admin.firestore().collection('notifications').add({
        userId: recipientId,
        type: 'message',
        title: 'New Message',
        message: `New message in your conversation`,
        matchId: matchId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });