/**
 * Simple Backend Server Example
 * 
 * This is a simple Node.js + Express server for testing the Flutter app
 * 
 * Setup:
 * 1. Install Node.js from https://nodejs.org/
 * 2. In a terminal, run: npm init -y
 * 3. Install dependencies: npm install express cors
 * 4. Create this file as server.js
 * 5. Run: node server.js
 * 6. Server will run on http://localhost:3000
 */

const express = require('express');
const cors = require('cors');
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage (for testing only)
// In production, use a database like MongoDB
const users = {};

console.log('🚀 Server Starting...\n');

// ============================================
// AUTH ROUTES
// ============================================

// Sign Up Endpoint
app.post('/api/auth/signup', (req, res) => {
  console.log('📝 Sign Up Request:', req.body);
  
  const { name, email, password } = req.body;
  
  // Validation
  if (!name || !email || !password) {
    return res.status(400).json({ 
      message: 'Name, email and password are required' 
    });
  }
  
  // Check if email already exists
  if (users[email]) {
    console.log('❌ Email already registered:', email);
    return res.status(400).json({ 
      message: 'Email already registered' 
    });
  }
  
  // Create user
  const userId = 'user_' + Date.now();
  const newUser = {
    id: userId,
    name: name,
    email: email,
    password: password,  // In production, hash this!
    createdAt: new Date().toISOString()
  };
  
  // Save user
  users[email] = newUser;
  
  // Return user without password
  const { password: _, ...userWithoutPassword } = newUser;
  
  console.log('✅ User created successfully:', email);
  res.status(201).json({ 
    data: userWithoutPassword 
  });
});

// Login Endpoint
app.post('/api/auth/login', (req, res) => {
  console.log('🔐 Login Request:', req.body);
  
  const { email, password } = req.body;
  
  // Validation
  if (!email || !password) {
    return res.status(400).json({ 
      message: 'Email and password are required' 
    });
  }
  
  // Find user
  const user = users[email];
  
  if (!user) {
    console.log('❌ User not found:', email);
    return res.status(401).json({ 
      message: 'Invalid email or password' 
    });
  }
  
  // Check password
  if (user.password !== password) {
    console.log('❌ Invalid password for:', email);
    return res.status(401).json({ 
      message: 'Invalid email or password' 
    });
  }
  
  // Return user without password
  const { password: _, ...userWithoutPassword } = user;
  
  console.log('✅ Login successful:', email);
  res.status(200).json({ 
    data: userWithoutPassword 
  });
});

// Check Email Endpoint (Optional)
app.get('/api/auth/check-email', (req, res) => {
  const { email } = req.query;
  
  if (!email) {
    return res.status(400).json({ 
      message: 'Email parameter is required' 
    });
  }
  
  const exists = !!users[email];
  console.log(`📧 Checking email: ${email} - ${exists ? 'Exists' : 'Available'}`);
  
  res.json({ 
    exists: exists 
  });
});

// Get User Endpoint (Optional - for testing)
app.get('/api/auth/user/:email', (req, res) => {
  const { email } = req.params;
  const user = users[email];
  
  if (!user) {
    return res.status(404).json({ 
      message: 'User not found' 
    });
  }
  
  const { password: _, ...userWithoutPassword } = user;
  res.json({ 
    data: userWithoutPassword 
  });
});

// Get All Users Endpoint (Optional - for debugging)
app.get('/api/debug/users', (req, res) => {
  const allUsers = Object.values(users).map(user => {
    const { password, ...userWithoutPassword } = user;
    return userWithoutPassword;
  });
  
  res.json({ 
    count: allUsers.length,
    users: allUsers 
  });
});

// Health Check Endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok',
    timestamp: new Date().toISOString()
  });
});

// ============================================
// ERROR HANDLING
// ============================================

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    message: 'Endpoint not found' 
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('🔴 Error:', err);
  res.status(500).json({ 
    message: 'Internal server error' 
  });
});

// ============================================
// START SERVER
// ============================================

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Server running on http://localhost:${PORT}`);
  console.log('\n📍 Available Endpoints:');
  console.log(`  POST   http://localhost:${PORT}/api/auth/signup`);
  console.log(`  POST   http://localhost:${PORT}/api/auth/login`);
  console.log(`  GET    http://localhost:${PORT}/api/auth/check-email?email=test@example.com`);
  console.log(`  GET    http://localhost:${PORT}/api/health`);
  console.log(`\n📝 Test Data:
  
Email: test@example.com
Password: password123

Use these for testing!`);
  console.log('\n🛑 Press Ctrl+C to stop server\n');
});

// ============================================
// TESTING WITH CURL
// ============================================

/*
// Test endpoints with curl:

// Sign Up:
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","password":"pass123"}'

// Login:
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"pass123"}'

// Check Email:
curl http://localhost:3000/api/auth/check-email?email=john@example.com

// Get All Users (for debugging):
curl http://localhost:3000/api/debug/users

// Health Check:
curl http://localhost:3000/api/health
*/
