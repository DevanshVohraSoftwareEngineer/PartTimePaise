const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');

const router = express.Router();

// Helper function to generate tokens
const generateTokens = (user) => {
  const payload = {
    userId: user.id,
    email: user.email,
    role: user.role
  };

  const accessToken = jwt.sign(payload, process.env.JWT_SECRET || 'default-secret', {
    expiresIn: '15m'
  });
  const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH_SECRET || 'default-refresh', {
    expiresIn: '7d'
  });

  return { accessToken, refreshToken };
};

// Register user
router.post('/register', async (req, res) => {
  try {
    const { email, password, firstName, lastName, role, college } = req.body;

    // Check if user exists
    const existingUser = await admin.firestore()
      .collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (!existingUser.empty) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Create user
    const userRef = admin.firestore().collection('users').doc();
    const userData = {
      id: userRef.id,
      email,
      password: hashedPassword,
      firstName,
      lastName,
      role,
      college: college || null,
      profileImage: null,
      bio: null,
      skills: [],
      hourlyRate: null,
      rating: null,
      totalReviews: 0,
      isVerified: false,
      isEmailVerified: false,
      walletBalance: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await userRef.set(userData);

    // Generate tokens
    const tokens = generateTokens(userData);

    res.status(201).json({
      message: 'User registered successfully',
      user: {
        id: userData.id,
        email: userData.email,
        firstName: userData.firstName,
        lastName: userData.lastName,
        role: userData.role,
      },
      tokens,
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Failed to register user' });
  }
});

// Login user
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const userSnapshot = await admin.firestore()
      .collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (userSnapshot.empty) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const userDoc = userSnapshot.docs[0];
    const user = { id: userDoc.id, ...userDoc.data() };

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate tokens
    const tokens = generateTokens(user);

    res.json({
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
        isEmailVerified: user.isEmailVerified,
      },
      tokens,
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Failed to login' });
  }
});

// Get current user profile
router.get('/me', async (req, res) => {
  try {
    // In Firebase functions, we need to verify the token from headers
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'default-secret');

    const userDoc = await admin.firestore()
      .collection('users')
      .doc(decoded.userId)
      .get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = userDoc.data();

    res.json({
      id: userDoc.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      college: user.college,
      profileImage: user.profileImage,
      bio: user.bio,
      skills: user.skills,
      hourlyRate: user.hourlyRate,
      rating: user.rating,
      totalReviews: user.totalReviews,
      isVerified: user.isVerified,
      walletBalance: user.walletBalance,
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
});

module.exports = router;