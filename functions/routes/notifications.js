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

// Get notifications for user
router.get('/', authenticate, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { page = 1, limit = 20 } = req.query;

    const snapshot = await admin.firestore()
      .collection('notifications')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(parseInt(limit))
      .get();

    const notifications = [];
    snapshot.forEach(doc => {
      notifications.push({ id: doc.id, ...doc.data() });
    });

    res.json({
      success: true,
      data: {
        notifications,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          hasMore: notifications.length === parseInt(limit),
        },
      },
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

// Mark notification as read
router.put('/:notificationId/read', authenticate, async (req, res) => {
  try {
    const { notificationId } = req.params;
    const userId = req.user.userId;

    // Check ownership
    const notificationDoc = await admin.firestore()
      .collection('notifications')
      .doc(notificationId)
      .get();

    if (!notificationDoc.exists) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    const notification = notificationDoc.data();
    if (notification.userId !== userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    await admin.firestore()
      .collection('notifications')
      .doc(notificationId)
      .update({
        read: true,
        readAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    res.json({
      success: true,
      message: 'Notification marked as read',
    });
  } catch (error) {
    console.error('Mark notification read error:', error);
    res.status(500).json({ error: 'Failed to mark notification as read' });
  }
});

// Mark all notifications as read
router.put('/read-all', authenticate, async (req, res) => {
  try {
    const userId = req.user.userId;

    const batch = admin.firestore().batch();

    const snapshot = await admin.firestore()
      .collection('notifications')
      .where('userId', '==', userId)
      .where('read', '==', false)
      .get();

    snapshot.forEach(doc => {
      batch.update(doc.ref, {
        read: true,
        readAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();

    res.json({
      success: true,
      message: 'All notifications marked as read',
    });
  } catch (error) {
    console.error('Mark all notifications read error:', error);
    res.status(500).json({ error: 'Failed to mark notifications as read' });
  }
});

// Delete notification
router.delete('/:notificationId', authenticate, async (req, res) => {
  try {
    const { notificationId } = req.params;
    const userId = req.user.userId;

    // Check ownership
    const notificationDoc = await admin.firestore()
      .collection('notifications')
      .doc(notificationId)
      .get();

    if (!notificationDoc.exists) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    const notification = notificationDoc.data();
    if (notification.userId !== userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    await admin.firestore()
      .collection('notifications')
      .doc(notificationId)
      .delete();

    res.json({
      success: true,
      message: 'Notification deleted successfully',
    });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({ error: 'Failed to delete notification' });
  }
});

module.exports = router;