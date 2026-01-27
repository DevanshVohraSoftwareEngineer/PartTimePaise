# 🔧 Environment Setup Guide

## 📝 What You Need to Do:

### 1️⃣ **PostgreSQL Database**
**Status:** ❌ Not installed

**Steps:**
1. Download PostgreSQL: https://www.postgresql.org/download/windows/
2. Install with password: `YOUR_POSTGRES_PASSWORD`
3. Open pgAdmin or psql
4. Create database: `CREATE DATABASE parttimepaise;`
5. Update in `backend/.env`:
   ```
   DATABASE_URL=postgresql://postgres:YOUR_POSTGRES_PASSWORD@localhost:5432/parttimepaise
   ```

---

### 2️⃣ **Redis Server**
**Status:** ❌ Not installed

**Option A - Windows Installer:**
1. Download: https://github.com/tporadowski/redis/releases
2. Install and start Redis service
3. Default: `redis://localhost:6379` (already in .env)

**Option B - Docker (Easier):**
```bash
docker run -d -p 6379:6379 redis:alpine
```

---

### 3️⃣ **Gmail SMTP (for emails)**
**Status:** ❌ Not configured

**Steps:**
1. Go to: https://myaccount.google.com/security
2. Enable 2-Factor Authentication
3. Go to: https://myaccount.google.com/apppasswords
4. Create App Password (select "Mail" and "Windows Computer")
5. Copy the 16-digit password
6. Update in `backend/.env`:
   ```
   EMAIL_USER=youremail@gmail.com
   EMAIL_PASSWORD=abcd efgh ijkl mnop  (16 digits, no spaces)
   FROM_EMAIL=youremail@gmail.com
   ```

---

### 4️⃣ **Cloudinary (for image/file uploads)**
**Status:** ❌ Not configured

**Steps:**
1. Sign up: https://cloudinary.com/users/register/free
2. Go to Dashboard: https://cloudinary.com/console
3. Copy credentials:
   - Cloud Name
   - API Key
   - API Secret
4. Update in **BOTH** `backend/.env` AND `frontend/.env`:
   ```
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=123456789012345
   CLOUDINARY_API_SECRET=abcdefghijklmnopqrstuvwxyz123456
   ```

---

### 5️⃣ **Google Maps API (for location features)**
**Status:** ❌ Not configured

**Steps:**
1. Go to: https://console.cloud.google.com
2. Create a new project (e.g., "PartTimePaise")
3. Enable APIs:
   - Maps JavaScript API
   - Geocoding API
   - Places API
4. Go to "Credentials" → Create API Key
5. Copy the API key
6. Update in `frontend/.env`:
   ```
   VITE_GOOGLE_MAPS_API_KEY=AIzaSyAaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPp
   ```

---

## 🎯 Quick Checklist:

- [ ] PostgreSQL installed & database created
- [ ] Redis installed & running
- [ ] Gmail App Password generated
- [ ] Cloudinary account created & credentials copied
- [ ] Google Maps API key generated
- [ ] Updated `backend/.env` with all credentials
- [ ] Updated `frontend/.env` with Cloudinary & Maps key

---

## ▶️ After Setup, Run:

### Backend:
```bash
cd backend
npm install
npm run migrate    # Create database tables
npm run seed       # Add demo data (optional)
npm run dev        # Start backend server
```

### Frontend:
```bash
cd frontend
npm run dev        # Already running on http://localhost:5177
```

---

## 🔍 Verify Everything Works:

1. Backend should start on: http://localhost:5000
2. Frontend should be on: http://localhost:5177
3. Test registration → Should send email
4. Test profile setup → Should upload image to Cloudinary
5. Test location search → Should use Google Maps

---

## 📞 Need Help?

**PostgreSQL issues:** Check if service is running in Windows Services
**Redis issues:** Run `redis-cli ping` (should return PONG)
**Email issues:** Make sure 2FA is enabled and App Password is correct (no spaces)
**Cloudinary issues:** Check Dashboard for correct credentials
**Maps issues:** Make sure APIs are enabled and billing is set up (free tier available)
