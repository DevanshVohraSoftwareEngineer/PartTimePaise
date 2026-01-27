# 🎉 Week 1 Complete! Quick Start Guide

## ✅ What's Been Built:

### Backend (Node.js + Express + TypeScript):
- ✅ Complete authentication system (register, login, logout)
- ✅ Email verification with tokens
- ✅ Password reset flow
- ✅ JWT authentication with refresh tokens
- ✅ PostgreSQL database with Drizzle ORM
- ✅ Redis for caching and rate limiting
- ✅ Rate limiting on auth endpoints
- ✅ Email service (Nodemailer)
- ✅ Error handling and validation (Zod)

### Frontend (React + TypeScript + Vite):
- ✅ Beautiful landing page
- ✅ Login & Signup pages (with role selection)
- ✅ Forgot password & Reset password flows
- ✅ Protected routes
- ✅ TailwindCSS styling
- ✅ Zustand state management
- ✅ Axios API integration with auto token refresh

## 🚀 Quick Start (5 Minutes):

### 1. Install Prerequisites (if not installed):
- **Node.js 20+**: https://nodejs.org
- **PostgreSQL 15+**: https://www.postgresql.org/download/
- **Redis** (optional): https://github.com/tporadowski/redis/releases

### 2. Setup Backend:

```powershell
# Create PostgreSQL database
createdb parttimepaise

# Go to backend folder
cd backend

# Copy environment file
cp .env.example .env

# Edit .env and update these:
# DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/parttimepaise
# JWT_SECRET=change-this-to-random-string
# EMAIL_USER=your-email@gmail.com
# EMAIL_PASSWORD=your-app-password

# Install dependencies (already done)
npm install

# Run database migrations
npm run db:migrate

# Seed initial data (colleges)
npm run db:seed

# Start backend server
npm run dev
```

Backend will be running on **http://localhost:5000**

### 3. Setup Frontend (in new terminal):

```powershell
cd frontend

# .env already created
# Install dependencies (already done)
npm install

# Start frontend
npm run dev
```

Frontend will be running on **http://localhost:5173**

## 📧 Email Setup (for verification & password reset):

### Option 1: Gmail (Easiest)
1. Go to Google Account settings
2. Enable 2-Step Verification
3. Generate App Password: https://myaccount.google.com/apppasswords
4. Use app password in `.env`:
```
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=generated-app-password
```

### Option 2: Use Mailtrap (Testing)
1. Sign up at https://mailtrap.io (free)
2. Get SMTP credentials
3. Update `.env`:
```
EMAIL_HOST=smtp.mailtrap.io
EMAIL_PORT=2525
EMAIL_USER=your-mailtrap-user
EMAIL_PASSWORD=your-mailtrap-pass
```

## 🧪 Test the Application:

### 1. Register a New User:
1. Open http://localhost:5173
2. Click "Get Started" or "Sign up"
3. Choose role (Client or Worker)
4. Fill in details
5. Submit

### 2. Check Email:
- You'll receive verification email
- Click link to verify (or test in Mailtrap)

### 3. Login:
- Use credentials to login
- You'll be redirected to dashboard

### 4. Test Password Reset:
- Click "Forgot password" on login
- Enter email
- Check email for reset link
- Set new password

## 📡 API Testing (Postman/Thunder Client):

### Register:
```
POST http://localhost:5000/api/v1/auth/register
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123",
  "name": "Test User",
  "role": "worker"
}
```

### Login:
```
POST http://localhost:5000/api/v1/auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123"
}
```

### Get Current User (with token):
```
GET http://localhost:5000/api/v1/auth/me
Authorization: Bearer YOUR_ACCESS_TOKEN
```

## 🐛 Troubleshooting:

### "Cannot connect to PostgreSQL"
```powershell
# Start PostgreSQL service (Windows)
net start postgresql-x64-15

# Or check if running:
pg_isready
```

### "Cannot connect to Redis"
```powershell
# Start Redis (Windows with downloaded exe)
redis-server

# Or if installed as service:
net start redis
```

### "Port 5000 already in use"
- Change PORT in backend/.env
- Update VITE_API_URL in frontend/.env

### "Email not sending"
- Check EMAIL_USER and EMAIL_PASSWORD
- For Gmail, use App Password (not regular password)
- Test with Mailtrap first

### "Database migration error"
```powershell
cd backend

# Drop and recreate database
dropdb parttimepaise
createdb parttimepaise

# Run migrations again
npm run db:migrate
npm run db:seed
```

## 🎯 What's Next (Week 2):

- Profile setup wizard
- College verification
- Location detection
- Skills and rates configuration
- Portfolio upload
- Worker skill quiz
- File upload (AWS S3/Cloudinary)

## 📁 Project Structure:

```
PartTimePaise/
├── backend/              # Node.js API
│   ├── src/
│   │   ├── config/      # DB, Redis config
│   │   ├── controllers/ # Business logic
│   │   ├── db/          # Database schema
│   │   ├── middleware/  # Auth, rate limiting
│   │   ├── routes/      # API endpoints
│   │   ├── services/    # External services
│   │   └── utils/       # Helpers
│   └── package.json
│
├── frontend/            # React app
│   ├── src/
│   │   ├── components/  # Reusable components
│   │   ├── pages/       # Route pages
│   │   ├── services/    # API calls
│   │   ├── store/       # State management
│   │   └── App.tsx      # Main app
│   └── package.json
│
└── README.md            # Full documentation
```

## 💡 Tips:

1. **Development Workflow**:
   - Keep both terminals open (backend + frontend)
   - Changes auto-reload in both
   - Check browser console for frontend errors
   - Check terminal for backend errors

2. **Git Workflow**:
   ```bash
   git init
   git add .
   git commit -m "Week 1: Complete authentication system"
   ```

3. **Database Management**:
   - Use `npm run db:studio` in backend to open Drizzle Studio (GUI)
   - View/edit database visually

4. **Testing**:
   - Create multiple test accounts (both client and worker)
   - Test all flows (register, login, forgot password, etc.)
   - Check email delivery

## 🎉 Success Indicators:

✅ Backend running on port 5000
✅ Frontend running on port 5173  
✅ Can register new users
✅ Can login successfully
✅ Receive verification emails
✅ Can reset password
✅ Protected routes work
✅ Token refresh works automatically

## 📞 Support:

- Check README.md for detailed docs
- Review code comments
- Test API endpoints with provided examples
- Database schema is in backend/src/db/schema.ts

---

**🚀 You're all set! Week 1 complete. Ready to build Week 2 features!**
