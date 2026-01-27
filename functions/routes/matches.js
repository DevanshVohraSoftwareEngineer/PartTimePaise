const express = require('express');
const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');

const router = express.Router();

// Middleware to verify JWT token
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'default-secret');
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Get matches for user
router.get('/', authenticate, async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get matches where user is either worker or client
    const workerMatches = await admin.firestore()
      .collection('matches')
      .where('workerId', '==', userId)
      .where('status', '==', 'active')
      .get();

    const clientMatches = await admin.firestore()
      .collection('matches')
      .where('clientId', '==', userId)
      .where('status', '==', 'active')
      .get();

    const matches = [];

    // Process worker matches
    for (const doc of workerMatches.docs) {
      const match = { id: doc.id, ...doc.data() };

      // Get task details
      const taskDoc = await admin.firestore()
        .collection('tasks')
        .doc(match.taskId)
        .get();

      if (taskDoc.exists) {
        match.task = { id: taskDoc.id, ...taskDoc.data() };
      }

      // Get client details
      const clientDoc = await admin.firestore()
        .collection('users')
        .doc(match.clientId)
        .get();

      if (clientDoc.exists) {
        const clientData = clientDoc.data();
        match.client = {
          id: clientDoc.id,
          name: clientData.name,
          email: clientData.email,
          profilePicture: clientData.profilePicture,
          rating: clientData.rating,
        };
      }

      matches.push(match);
    }

    // Process client matches
    for (const doc of clientMatches.docs) {
      const match = { id: doc.id, ...doc.data() };

      // Get task details
      const taskDoc = await admin.firestore()
        .collection('tasks')
        .doc(match.taskId)
        .get();

      if (taskDoc.exists) {
        match.task = { id: taskDoc.id, ...taskDoc.data() };
      }

      // Get worker details
      const workerDoc = await admin.firestore()
        .collection('users')
        .doc(match.workerId)
        .get();

      if (workerDoc.exists) {
        const workerData = workerDoc.data();
        match.worker = {
          id: workerDoc.id,
          name: workerData.name,
          email: workerData.email,
          profilePicture: workerData.profilePicture,
          rating: workerData.rating,
        };
      }

      matches.push(match);
    }

    res.json({
      success: true,
      data: { matches },
    });
  } catch (error) {
    console.error('Get matches error:', error);
    res.status(500).json({ error: 'Failed to fetch matches' });
  }
});

// Get match by ID
router.get('/:matchId', authenticate, async (req, res) => {
  try {
    const { matchId } = req.params;
    const userId = req.user.userId;

    const matchDoc = await admin.firestore()
      .collection('matches')
      .doc(matchId)
      .get();

    if (!matchDoc.exists) {
      return res.status(404).json({ error: 'Match not found' });
    }

    const match = { id: matchDoc.id, ...matchDoc.data() };

    // Check if user is part of this match
    if (match.workerId !== userId && match.clientId !== userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    // Get task details
    const taskDoc = await admin.firestore()
      .collection('tasks')
      .doc(match.taskId)
      .get();

    if (taskDoc.exists) {
      match.task = { id: taskDoc.id, ...taskDoc.data() };
    }

    // Get other user details
    const otherUserId = match.workerId === userId ? match.clientId : match.workerId;
    const otherUserDoc = await admin.firestore()
      .collection('users')
      .doc(otherUserId)
      .get();

    if (otherUserDoc.exists) {
      const otherUserData = otherUserDoc.data();
      match.otherUser = {
        id: otherUserDoc.id,
        name: otherUserData.name,
        email: otherUserData.email,
        profilePicture: otherUserData.profilePicture,
        rating: otherUserData.rating,
      };
    }

    res.json({
      success: true,
      data: match,
    });
  } catch (error) {
    console.error('Get match error:', error);
    res.status(500).json({ error: 'Failed to fetch match' });
  }
});

// Update match status
router.put('/:matchId', authenticate, async (req, res) => {
  try {
    const { matchId } = req.params;
    const { status } = req.body;
    const userId = req.user.userId;

    // Validate status
    if (!['active', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const matchDoc = await admin.firestore()
      .collection('matches')
      .doc(matchId)
      .get();

    if (!matchDoc.exists) {
      return res.status(404).json({ error: 'Match not found' });
    }

    const match = matchDoc.data();

    // Check if user is part of this match
    if (match.workerId !== userId && match.clientId !== userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    await admin.firestore()
      .collection('matches')
      .doc(matchId)
      .update({
        status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // If completed, update task status
    if (status === 'completed') {
      await admin.firestore()
        .collection('tasks')
        .doc(match.taskId)
        .update({
          status: 'completed',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    res.json({
      success: true,
      message: 'Match updated successfully',
    });
  } catch (error) {
    console.error('Update match error:', error);
    res.status(500).json({ error: 'Failed to update match' });
  }
});

// Get messages for a match
router.get('/:matchId/messages', authenticate, async (req, res) => {
  try {
    const { matchId } = req.params;
    const userId = req.user.userId;

    // Verify user is part of this match
    const matchDoc = await admin.firestore()
      .collection('matches')
      .doc(matchId)
      .get();

    if (!matchDoc.exists) {
      return res.status(404).json({ error: 'Match not found' });
    }

    const match = matchDoc.data();
    if (match.workerId !== userId && match.clientId !== userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const messagesSnapshot = await admin.firestore()
      .collection('matches')
      .doc(matchId)
      .collection('messages')
      .orderBy('createdAt', 'asc')
      .get();

    const messages = [];
    messagesSnapshot.forEach(doc => {
      messages.push({ id: doc.id, ...doc.data() });
    });

    res.json({
      success: true,
      data: { messages },
    });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
});

// Send message in a match
router.post('/:matchId/messages', authenticate, async (req, res) => {
  try {
    const { matchId } = req.params;
    const { content, messageType = 'text' } = req.body;
    const senderId = req.user.userId;

    // Verify user is part of this match
    const matchDoc = await admin.firestore()
      .collection('matches')
      .doc(matchId)
      .get();

    if (!matchDoc.exists) {
      return res.status(404).json({ error: 'Match not found' });
    }

    const match = matchDoc.data();
    if (match.workerId !== senderId && match.clientId !== senderId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const messageRef = admin.firestore()
      .collection('matches')
      .doc(matchId)
      .collection('messages')
      .doc();

    const messageData = {
      id: messageRef.id,
      senderId,
      content,
      messageType,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    };

    await messageRef.set(messageData);

    // Update match's last message timestamp
    await admin.firestore()
      .collection('matches')
      .doc(matchId)
      .update({
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    res.status(201).json({
      success: true,
      data: messageData,
    });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

module.exports = router;