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

// Create swipe
router.post('/', authenticate, async (req, res) => {
  try {
    const { taskId, direction } = req.body;
    const workerId = req.user.userId;

    // Validate direction
    if (!['left', 'right'].includes(direction)) {
      return res.status(400).json({ error: 'Invalid direction. Must be left or right' });
    }

    // Check if task exists
    const taskDoc = await admin.firestore()
      .collection('tasks')
      .doc(taskId)
      .get();

    if (!taskDoc.exists) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const task = taskDoc.data();

    // Check if user already swiped on this task
    const existingSwipe = await admin.firestore()
      .collection('swipes')
      .where('taskId', '==', taskId)
      .where('workerId', '==', workerId)
      .limit(1)
      .get();

    if (!existingSwipe.empty) {
      return res.status(400).json({ error: 'Already swiped on this task' });
    }

    const swipeRef = admin.firestore().collection('swipes').doc();
    const swipeData = {
      id: swipeRef.id,
      taskId,
      workerId,
      direction,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await swipeRef.set(swipeData);

    // Check for match if right swipe
    let match = null;
    if (direction === 'right') {
      // Check if client also swiped right on this worker
      const clientSwipe = await admin.firestore()
        .collection('swipes')
        .where('taskId', '==', taskId)
        .where('workerId', '==', task.clientId)
        .where('direction', '==', 'right')
        .limit(1)
        .get();

      if (!clientSwipe.empty) {
        // Create match
        const matchRef = admin.firestore().collection('matches').doc();
        const matchData = {
          id: matchRef.id,
          taskId,
          workerId,
          clientId: task.clientId,
          status: 'active',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await matchRef.set(matchData);
        match = matchData;

        // Update task status to matched
        await admin.firestore()
          .collection('tasks')
          .doc(taskId)
          .update({
            status: 'matched',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
      }
    }

    res.status(201).json({
      success: true,
      data: {
        swipe: swipeData,
        match: match,
      },
    });
  } catch (error) {
    console.error('Create swipe error:', error);
    res.status(500).json({ error: 'Failed to create swipe' });
  }
});

// Get swipes for user
router.get('/', authenticate, async (req, res) => {
  try {
    const userId = req.user.userId;

    const snapshot = await admin.firestore()
      .collection('swipes')
      .where('workerId', '==', userId)
      .orderBy('createdAt', 'desc')
      .get();

    const swipes = [];
    snapshot.forEach(doc => {
      swipes.push({ id: doc.id, ...doc.data() });
    });

    res.json({
      success: true,
      data: { swipes },
    });
  } catch (error) {
    console.error('Get swipes error:', error);
    res.status(500).json({ error: 'Failed to fetch swipes' });
  }
});

// Get swipe status for specific task
router.get('/task/:taskId', authenticate, async (req, res) => {
  try {
    const { taskId } = req.params;
    const userId = req.user.userId;

    const swipeDoc = await admin.firestore()
      .collection('swipes')
      .where('taskId', '==', taskId)
      .where('workerId', '==', userId)
      .limit(1)
      .get();

    if (swipeDoc.empty) {
      return res.json({
        success: true,
        data: { swipe: null },
      });
    }

    const swipe = { id: swipeDoc.docs[0].id, ...swipeDoc.docs[0].data() };

    res.json({
      success: true,
      data: { swipe },
    });
  } catch (error) {
    console.error('Get swipe status error:', error);
    res.status(500).json({ error: 'Failed to fetch swipe status' });
  }
});

module.exports = router;