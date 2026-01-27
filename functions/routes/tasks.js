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

// Create task
router.post('/', authenticate, async (req, res) => {
  try {
    const { title, description, category, budget, estimatedHours, deadline, requiredSkills, location } = req.body;
    const clientId = req.user.userId;

    const taskRef = admin.firestore().collection('tasks').doc();
    const taskData = {
      id: taskRef.id,
      title,
      description,
      category,
      budget: parseFloat(budget),
      estimatedHours: estimatedHours ? parseInt(estimatedHours) : null,
      deadline: deadline ? new Date(deadline) : null,
      requiredSkills: requiredSkills || [],
      location: location ? {
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        radius: location.radius,
      } : null,
      clientId,
      status: 'open',
      priority: 'medium',
      attachments: [],
      viewCount: 0,
      likeCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await taskRef.set(taskData);

    res.status(201).json({
      success: true,
      data: taskData,
    });
  } catch (error) {
    console.error('Create task error:', error);
    res.status(500).json({ error: 'Failed to create task' });
  }
});

// Get tasks (available for workers)
router.get('/', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, category } = req.query;
    const userId = req.user.userId;

    let query = admin.firestore()
      .collection('tasks')
      .where('status', '==', 'open')
      .where('clientId', '!=', userId) // Don't show user's own tasks
      .orderBy('createdAt', 'desc')
      .limit(parseInt(limit));

    if (category) {
      query = query.where('category', '==', category);
    }

    const snapshot = await query.get();
    const tasks = [];

    snapshot.forEach(doc => {
      tasks.push({ id: doc.id, ...doc.data() });
    });

    res.json({
      success: true,
      data: {
        tasks,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          hasMore: tasks.length === parseInt(limit),
        },
      },
    });
  } catch (error) {
    console.error('Get tasks error:', error);
    res.status(500).json({ error: 'Failed to fetch tasks' });
  }
});

// Get user's tasks
router.get('/my-tasks', authenticate, async (req, res) => {
  try {
    const userId = req.user.userId;

    const snapshot = await admin.firestore()
      .collection('tasks')
      .where('clientId', '==', userId)
      .orderBy('createdAt', 'desc')
      .get();

    const tasks = [];
    snapshot.forEach(doc => {
      tasks.push({ id: doc.id, ...doc.data() });
    });

    res.json({
      success: true,
      data: { tasks },
    });
  } catch (error) {
    console.error('Get my tasks error:', error);
    res.status(500).json({ error: 'Failed to fetch tasks' });
  }
});

// Get task by ID
router.get('/:taskId', authenticate, async (req, res) => {
  try {
    const { taskId } = req.params;

    const taskDoc = await admin.firestore()
      .collection('tasks')
      .doc(taskId)
      .get();

    if (!taskDoc.exists) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const task = { id: taskDoc.id, ...taskDoc.data() };

    // Increment view count
    await admin.firestore()
      .collection('tasks')
      .doc(taskId)
      .update({
        viewCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    res.json({
      success: true,
      data: task,
    });
  } catch (error) {
    console.error('Get task error:', error);
    res.status(500).json({ error: 'Failed to fetch task' });
  }
});

// Update task
router.put('/:taskId', authenticate, async (req, res) => {
  try {
    const { taskId } = req.params;
    const userId = req.user.userId;

    // Check ownership
    const taskDoc = await admin.firestore()
      .collection('tasks')
      .doc(taskId)
      .get();

    if (!taskDoc.exists) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const task = taskDoc.data();
    if (task.clientId !== userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const updates = {
      ...req.body,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await admin.firestore()
      .collection('tasks')
      .doc(taskId)
      .update(updates);

    const updatedTaskDoc = await admin.firestore()
      .collection('tasks')
      .doc(taskId)
      .get();

    res.json({
      success: true,
      data: { id: updatedTaskDoc.id, ...updatedTaskDoc.data() },
    });
  } catch (error) {
    console.error('Update task error:', error);
    res.status(500).json({ error: 'Failed to update task' });
  }
});

// Delete task
router.delete('/:taskId', authenticate, async (req, res) => {
  try {
    const { taskId } = req.params;
    const userId = req.user.userId;

    // Check ownership
    const taskDoc = await admin.firestore()
      .collection('tasks')
      .doc(taskId)
      .get();

    if (!taskDoc.exists) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const task = taskDoc.data();
    if (task.clientId !== userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    await admin.firestore()
      .collection('tasks')
      .doc(taskId)
      .delete();

    res.json({
      success: true,
      message: 'Task deleted successfully',
    });
  } catch (error) {
    console.error('Delete task error:', error);
    res.status(500).json({ error: 'Failed to delete task' });
  }
});

module.exports = router;