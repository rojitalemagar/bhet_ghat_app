const express = require('express');
const cors = require('cors');
const bcryptjs = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const nodemailer = require('nodemailer');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-this-in-production';

app.use(cors());
app.use(express.json());

const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `image-${uniqueSuffix}${path.extname(file.originalname)}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowedExts = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    const ext = path.extname(file.originalname).toLowerCase();
    const hasValidExt = allowedExts.includes(ext);
    const hasValidMime = file.mimetype.startsWith('image/') || file.mimetype === 'application/octet-stream';

    if (hasValidExt && hasValidMime) {
      cb(null, true);
      return;
    }

    cb(new Error(`Invalid file. Ext: ${ext}, MIME: ${file.mimetype}`));
  },
});

app.use('/uploads', express.static(uploadDir));

// In-memory data store (demo only)
const users = {};
const passwordResetTokens = new Map(); // hashedToken -> { email, expiresAt }

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function normalizeName(name) {
  return String(name || '').trim().replace(/\s+/g, ' ');
}

function getPublicBaseUrl(req) {
  const forwardedProto = req.headers['x-forwarded-proto'];
  const protocol = forwardedProto ? String(forwardedProto).split(',')[0] : req.protocol;
  return `${protocol}://${req.get('host')}`;
}

function createMailTransport() {
  const smtpHost = process.env.SMTP_HOST || 'smtp.gmail.com';
  const smtpPort = Number(process.env.SMTP_PORT || 587);
  const smtpUser = process.env.SMTP_USER || process.env.GMAIL_SMTP_USER;
  const smtpPass =
    process.env.SMTP_PASS || process.env.GMAIL_SMTP_APP_PASSWORD;

  if (!smtpUser || !smtpPass) {
    return null;
  }

  return nodemailer.createTransport({
    host: smtpHost,
    port: smtpPort,
    secure: false,
    auth: {
      user: smtpUser,
      pass: smtpPass,
    },
  });
}

const mailTransport = createMailTransport();

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function generateResetToken() {
  return crypto.randomBytes(32).toString('hex');
}

function sanitizeInterests(interests) {
  if (!Array.isArray(interests)) {
    return [];
  }

  return interests
    .map((interest) => String(interest || '').trim())
    .filter(Boolean)
    .slice(0, 12);
}

async function sendResetEmail({ toEmail, resetLink }) {
  if (!mailTransport) {
    console.log('SMTP not configured. Password reset link (dev only):', resetLink);
    return;
  }

  await mailTransport.sendMail({
    from:
      process.env.SMTP_FROM ||
      process.env.GMAIL_FROM ||
      process.env.SMTP_USER ||
      process.env.GMAIL_SMTP_USER,
    to: toEmail,
    subject: 'BhetGhat password reset link',
    text: `We received a request to reset your password. Open this link to continue:\n\n${resetLink}\n\nThis link expires in 15 minutes.`,
    html: `<p>We received a request to reset your password.</p><p><a href="${resetLink}">Reset Password</a></p><p>This link expires in 15 minutes.</p>`,
  });
}

function buildResetBridgeHtml({ token, appDeepLink }) {
  const escapedToken = String(token || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
  const escapedDeepLink = String(appDeepLink || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>BhetGhat Password Reset</title>
  <style>
    body {
      margin: 0;
      font-family: Arial, sans-serif;
      background: linear-gradient(135deg, #7e57c2, #5e35b1);
      color: #1f2937;
    }
    .wrap {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .card {
      width: 100%;
      max-width: 520px;
      background: #ffffff;
      border-radius: 20px;
      padding: 28px;
      box-shadow: 0 18px 40px rgba(0, 0, 0, 0.18);
    }
    h1 {
      margin: 0 0 12px;
      font-size: 28px;
    }
    p {
      line-height: 1.5;
      color: #4b5563;
    }
    .token {
      margin: 18px 0;
      padding: 14px;
      border-radius: 12px;
      background: #f3f4f6;
      word-break: break-all;
      font-family: Consolas, monospace;
      font-size: 14px;
    }
    .actions {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
      margin-top: 18px;
    }
    .btn {
      display: inline-block;
      padding: 12px 18px;
      border-radius: 12px;
      text-decoration: none;
      font-weight: 700;
    }
    .btn-primary {
      background: #e94057;
      color: white;
    }
    .btn-secondary {
      background: #eef2ff;
      color: #312e81;
      border: 0;
      cursor: pointer;
    }
    .note {
      margin-top: 18px;
      font-size: 13px;
      color: #6b7280;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>Reset your password</h1>
      <p>Tap the button below to open the BhetGhat app and continue resetting your password.</p>
      <div class="actions">
        <a class="btn btn-primary" href="${escapedDeepLink}">Open BhetGhat App</a>
        <button class="btn btn-secondary" type="button" onclick="copyToken()">Copy Token</button>
      </div>
      <div class="token" id="token">${escapedToken}</div>
      <p class="note">If the app does not open automatically, copy the token and paste it into the reset password screen in the app.</p>
    </div>
  </div>
  <script>
    const deepLink = ${JSON.stringify(appDeepLink)};
    function copyToken() {
      navigator.clipboard.writeText(${JSON.stringify(token)}).then(() => {
        alert('Reset token copied.');
      });
    }
    setTimeout(() => {
      window.location.href = deepLink;
    }, 300);
  </script>
</body>
</html>`;
}

app.post('/api/auth/signup', async (req, res) => {
  const { name, email, password, gender, bio, interests, profileImages } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ message: 'Name, email and password are required' });
  }

  const normalizedEmail = normalizeEmail(email);

  if (users[normalizedEmail]) {
    return res.status(400).json({ message: 'Email already registered' });
  }

  try {
    const salt = await bcryptjs.genSalt(10);
    const hashedPassword = await bcryptjs.hash(password, salt);

    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let userId = 'u';
    for (let i = 0; i < 7; i += 1) {
      userId += chars.charAt(Math.floor(Math.random() * chars.length));
    }

    const newUser = {
      id: userId,
      name,
      email: normalizedEmail,
      password: hashedPassword,
      gender: gender || null,
      bio: bio || null,
      interests: Array.isArray(interests) ? interests : [],
      profileImages: Array.isArray(profileImages) ? profileImages : [],
      profileImage: Array.isArray(profileImages) && profileImages.length > 0 ? profileImages[0] : null,
      createdAt: new Date().toISOString(),
      lastLogin: null,
    };

    users[normalizedEmail] = newUser;

    const token = jwt.sign({ id: userId, email: normalizedEmail }, JWT_SECRET, { expiresIn: '7d' });
    const { password: _password, ...userWithoutPassword } = newUser;

    return res.status(201).json({ data: userWithoutPassword, token });
  } catch (error) {
    return res.status(500).json({ message: 'Error creating user' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  const normalizedEmail = normalizeEmail(email);
  const user = users[normalizedEmail];

  if (!user) {
    return res.status(401).json({ message: 'Invalid email or password' });
  }

  try {
    const isPasswordValid = await bcryptjs.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    user.lastLogin = new Date().toISOString();

    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
    const { password: _password, ...userWithoutPassword } = user;

    return res.status(200).json({ data: userWithoutPassword, token });
  } catch (error) {
    return res.status(500).json({ message: 'Error during login' });
  }
});

app.get('/api/auth/check-email', (req, res) => {
  const { email } = req.query;

  if (!email) {
    return res.status(400).json({ message: 'Email parameter is required' });
  }

  const exists = !!users[normalizeEmail(email)];
  return res.json({ exists });
});

app.post('/api/auth/forgot-password', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: 'Email is required' });
  }

  const normalizedEmail = normalizeEmail(email);
  const user = users[normalizedEmail];

  // Neutral response to prevent user enumeration
  const successResponse = {
    success: true,
    message: 'If an account exists for this email, a password reset link has been sent.',
  };

  if (!user) {
    return res.status(200).json(successResponse);
  }

  try {
    const plainToken = generateResetToken();
    const hashedToken = hashToken(plainToken);
    const expiresAt = Date.now() + (15 * 60 * 1000);

    passwordResetTokens.set(hashedToken, { email: normalizedEmail, expiresAt });

    const clientResetUrl = process.env.CLIENT_RESET_URL;
    const appDeepLinkScheme = process.env.APP_DEEP_LINK_SCHEME || 'bhetghat';
    const publicBaseUrl = getPublicBaseUrl(req);
    const resetLink = clientResetUrl
      ? `${clientResetUrl}?token=${encodeURIComponent(plainToken)}`
      : `${publicBaseUrl}/reset-password?token=${encodeURIComponent(plainToken)}`;

    await sendResetEmail({ toEmail: normalizedEmail, resetLink });

    return res.status(200).json(successResponse);
  } catch (error) {
    return res.status(500).json({ message: 'Failed to process password reset request' });
  }
});

app.get('/reset-password', (req, res) => {
  const token = String(req.query.token || '').trim();
  if (!token) {
    return res.status(400).send('Reset token is required');
  }

  const appDeepLinkScheme = process.env.APP_DEEP_LINK_SCHEME || 'bhetghat';
  const appDeepLink = `${appDeepLinkScheme}://reset-password?token=${encodeURIComponent(token)}`;

  return res
    .status(200)
    .type('html')
    .send(buildResetBridgeHtml({ token, appDeepLink }));
});

app.post('/api/auth/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;

  if (!token || !newPassword) {
    return res.status(400).json({ message: 'Token and new password are required' });
  }

  if (String(newPassword).length < 6) {
    return res.status(400).json({ message: 'Password must be at least 6 characters' });
  }

  const hashedToken = hashToken(String(token));
  const tokenRecord = passwordResetTokens.get(hashedToken);

  if (!tokenRecord) {
    return res.status(400).json({ message: 'Invalid or expired reset token' });
  }

  if (Date.now() > tokenRecord.expiresAt) {
    passwordResetTokens.delete(hashedToken);
    return res.status(400).json({ message: 'Reset token expired' });
  }

  const user = users[tokenRecord.email];
  if (!user) {
    passwordResetTokens.delete(hashedToken);
    return res.status(400).json({ message: 'Invalid token data' });
  }

  try {
    const salt = await bcryptjs.genSalt(10);
    user.password = await bcryptjs.hash(newPassword, salt);
    passwordResetTokens.delete(hashedToken);

    return res.status(200).json({ success: true, message: 'Password reset successful' });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to reset password' });
  }
});

app.post('/api/upload/image', (req, res) => {
  upload.single('image')(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(413).json({ success: false, message: 'File too large. Max size is 5MB.' });
      }
      return res.status(400).json({ success: false, message: `Upload error: ${err.message}` });
    }

    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }

    const publicBaseUrl = getPublicBaseUrl(req);
    const imageUrl = `${publicBaseUrl}/uploads/${req.file.filename}`;

    const email = req.query.email ? normalizeEmail(req.query.email) : '';
    if (email && users[email]) {
      users[email].profileImage = req.file.filename;
      if (!Array.isArray(users[email].profileImages)) {
        users[email].profileImages = [];
      }
      users[email].profileImages.push(req.file.filename);
    }

    return res.status(200).json({
      success: true,
      message: 'Image uploaded successfully',
      imageUrl,
      fileName: req.file.filename,
    });
  });
});

app.get('/api/user/:userId/image', (req, res) => {
  const { userId } = req.params;
  const user = Object.values(users).find((item) => item.id === userId);

  if (!user || !user.profileImage) {
    return res.json({ imageUrl: null, message: 'No profile image set' });
  }

  const publicBaseUrl = getPublicBaseUrl(req);
  return res.json({
    imageUrl: `${publicBaseUrl}/uploads/${user.profileImage}`,
    message: 'Profile image found',
  });
});

app.delete('/api/upload/image/:fileName', (req, res) => {
  const { fileName } = req.params;
  const filePath = path.join(uploadDir, fileName);

  try {
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ success: false, message: 'Image not found' });
    }

    fs.unlinkSync(filePath);
    return res.json({ success: true, message: 'Image deleted successfully' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Error deleting image' });
  }
});

app.get('/api/users/count', (_req, res) => {
  const count = Object.keys(users).length;
  return res.json({ success: true, count, message: `Total users on server: ${count}` });
});

app.get('/api/users/list/all', (_req, res) => {
  try {
    const publicBaseUrl = process.env.PUBLIC_BASE_URL || `http://localhost:${PORT}`;
    const usersList = Object.values(users).map((user) => ({
      id: user.id,
      name: user.name,
      email: user.email,
      profileImage: user.profileImage || null,
      profileImages: Array.isArray(user.profileImages) ? user.profileImages : [],
      imageUrl: user.profileImage ? `${publicBaseUrl}/uploads/${user.profileImage}` : null,
      createdAt: user.createdAt,
      lastLogin: user.lastLogin || null,
      bio: user.bio || null,
      interests: Array.isArray(user.interests) ? user.interests : [],
      gender: user.gender || null,
    }));

    return res.json({ success: true, total: usersList.length, users: usersList });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch users' });
  }
});

app.get('/api/users/:userId', (req, res) => {
  const { userId } = req.params;

  try {
    const user = Object.values(users).find((item) => item.id === userId);

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const publicBaseUrl = getPublicBaseUrl(req);
    return res.json({
      success: true,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        profileImage: user.profileImage || null,
        profileImages: Array.isArray(user.profileImages) ? user.profileImages : [],
        imageUrl: user.profileImage ? `${publicBaseUrl}/uploads/${user.profileImage}` : null,
        createdAt: user.createdAt,
        lastLogin: user.lastLogin || null,
        bio: user.bio || null,
        interests: Array.isArray(user.interests) ? user.interests : [],
        gender: user.gender || null,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch user' });
  }
});

app.put('/api/users/profile', (req, res) => {
  const { email, name, gender, bio, interests, profileImages, profileImage } = req.body || {};

  if (!email) {
    return res.status(400).json({ success: false, message: 'Email is required' });
  }

  const normalizedEmail = normalizeEmail(email);
  const user = users[normalizedEmail];

  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }

  const normalizedName = typeof name === 'string' ? name.trim() : user.name;
  const normalizedBio = typeof bio === 'string' ? bio.trim() : user.bio;
  const normalizedGender = typeof gender === 'string' && gender.trim().length > 0
    ? gender.trim().toLowerCase()
    : null;
  const normalizedProfileImages = Array.isArray(profileImages)
    ? profileImages.map((item) => String(item || '').trim()).filter(Boolean)
    : Array.isArray(user.profileImages)
      ? user.profileImages
      : [];

  user.name = normalizedName || user.name;
  user.gender = normalizedGender;
  user.bio = normalizedBio || null;
  user.interests = sanitizeInterests(interests);
  user.profileImages = normalizedProfileImages;

  if (typeof profileImage === 'string' && profileImage.trim()) {
    user.profileImage = profileImage.trim();
  } else if (normalizedProfileImages.length > 0) {
    const firstImage = normalizedProfileImages[0];
    user.profileImage = firstImage.startsWith('http')
      ? firstImage.split('/').pop()
      : firstImage;
  }

  const publicBaseUrl = getPublicBaseUrl(req);
  const { password: _password, ...userWithoutPassword } = user;

  return res.json({
    success: true,
    message: 'Profile updated successfully',
    data: {
      ...userWithoutPassword,
      imageUrl: user.profileImage ? `${publicBaseUrl}/uploads/${user.profileImage}` : null,
    },
  });
});

app.get('/api/users/images/all', (_req, res) => {
  try {
    const publicBaseUrl = process.env.PUBLIC_BASE_URL || `http://localhost:${PORT}`;
    const imagesData = Object.values(users)
      .filter((user) => user.profileImage)
      .map((user) => ({
        userId: user.id,
        userName: user.name,
        email: user.email,
        profileImage: user.profileImage,
        imageUrl: `${publicBaseUrl}/uploads/${user.profileImage}`,
        uploadedAt: user.createdAt,
      }));

    return res.json({ success: true, total: imagesData.length, images: imagesData });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch user images' });
  }
});

app.get('/api/auth/user/:email', (req, res) => {
  const email = normalizeEmail(req.params.email);
  const user = users[email];

  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }

  const publicBaseUrl = getPublicBaseUrl(req);
  const { password: _password, ...userWithoutPassword } = user;
  return res.json({
    data: {
      ...userWithoutPassword,
      imageUrl: user.profileImage ? `${publicBaseUrl}/uploads/${user.profileImage}` : null,
    },
  });
});

app.get('/api/debug/users', (_req, res) => {
  const allUsers = Object.values(users).map((user) => {
    const { password, ...userWithoutPassword } = user;
    return userWithoutPassword;
  });

  return res.json({ count: allUsers.length, users: allUsers });
});

app.get('/api/health', (_req, res) => {
  return res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use((req, res) => {
  res.status(404).json({ message: 'Endpoint not found' });
});

app.use((err, _req, res, _next) => {
  console.error('Server error:', err);
  res.status(500).json({ message: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log('Auth routes:');
  console.log(`POST   http://localhost:${PORT}/api/auth/signup`);
  console.log(`POST   http://localhost:${PORT}/api/auth/login`);
  console.log(`POST   http://localhost:${PORT}/api/auth/forgot-password`);
  console.log(`POST   http://localhost:${PORT}/api/auth/reset-password`);
  console.log(`GET    http://localhost:${PORT}/api/auth/check-email?email=test@example.com`);
});
