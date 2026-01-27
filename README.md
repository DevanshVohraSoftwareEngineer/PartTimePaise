# PartTimePaise - Student Task Marketplace

A Tinder-style platform connecting students who need work done with those ready to help. Fast, trusted payments with escrow system.

## 🚀 Project Status: Week 1 Complete ✅

### ✅ Completed Features:
- Backend API with Express + TypeScript
- PostgreSQL + Redis setup
- Complete authentication system (Register, Login, Logout)
- Email verification
- Password reset flow
- JWT authentication with refresh tokens
- Frontend with React + TypeScript + Vite
- TailwindCSS styling
- Auth pages (Login, Signup, Forgot Password, Reset Password)
- Protected routes
- Global state management with Zustand

## 📁 Project Structure

```
PartTimePaise/
├── backend/
│   ├── src/
│   │   ├── config/         # Database, Redis configs
│   │   ├── controllers/    # Auth controller
│   │   ├── db/             # Database schema & migrations
│   │   ├── middleware/     # Auth, error handling, rate limiting
│   │   ├── routes/         # API routes
│   │   ├── services/       # Email service
│   │   ├── utils/          # Helpers, validation, errors
│   │   ├── server.ts       # Express app setup
│   │   └── index.ts        # Entry point
│   ├── package.json
│   └── tsconfig.json
│
└── frontend/
    ├── src/
    │   ├── components/     # Reusable components
    │   ├── pages/          # Page components
    │   ├── services/       # API calls
    │   ├── store/          # Zustand stores
    │   ├── App.tsx         # Main app with routing
    │   └── main.tsx        # Entry point
    ├── package.json
    └── tailwind.config.js
```

## 🛠️ Tech Stack

### Backend:
- **Runtime**: Node.js + TypeScript
- **Framework**: Express.js
- **Database**: PostgreSQL (with Drizzle ORM)
- **Cache**: Redis
- **Auth**: JWT + bcrypt
- **Validation**: Zod
- **Email**: Nodemailer

### Frontend:
- **Framework**: React 18 + TypeScript
- **Build Tool**: Vite
- **Styling**: TailwindCSS
- **Routing**: React Router v6
- **State**: Zustand
- **Forms**: React Hook Form + Zod
- **API**: Axios

## 🚦 Getting Started

### Prerequisites:
- Node.js 20+
- PostgreSQL 15+
- Redis 7+

### Backend Setup:

1. Navigate to backend:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file (copy from `.env.example`):
```bash
cp .env.example .env
```

4. Update `.env` with your credentials:
```env
DATABASE_URL=postgresql://user:password@localhost:5432/parttimepaise
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secret-key
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
```

5. Generate database migrations:
```bash
npm run db:generate
```

6. Run migrations:
```bash
npm run db:migrate
```

7. Seed database with colleges:
```bash
npm run db:seed
```

8. Start development server:
```bash
npm run dev
```

Backend will run on `http://localhost:5000`

### Frontend Setup:

1. Navigate to frontend:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```bash
cp .env.example .env
```

4. Start development server:
```bash
npm run dev
```

Frontend will run on `http://localhost:5173`

## 📡 API Endpoints

### Authentication:
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/logout` - Logout
- `POST /api/v1/auth/verify-email` - Verify email with token
- `POST /api/v1/auth/resend-verification` - Resend verification email
- `POST /api/v1/auth/forgot-password` - Request password reset
- `POST /api/v1/auth/reset-password` - Reset password with token
- `POST /api/v1/auth/refresh-token` - Refresh access token
- `GET /api/v1/auth/me` - Get current user (protected)

### Health:
- `GET /api/v1/health` - API health check

## 🎨 Frontend Routes

- `/` - Landing page
- `/login` - Login page
- `/signup` - Signup page (with role selection)
- `/forgot-password` - Forgot password page
- `/reset-password?token=xxx` - Reset password page
- `/dashboard` - User dashboard (protected)

## 🔐 Authentication Flow

1. User registers with email, password, name, and role (client/worker)
2. Verification email sent automatically
3. User can login immediately (but email verification recommended)
4. JWT access token (15 min) + refresh token (7 days)
5. Auto token refresh on expiry
6. Password reset via email token (1 hour expiry)

## 📦 Week 2 Features (Coming Next):

- [ ] Profile setup (avatar, bio, location)
- [ ] College verification
- [ ] Worker: Skills, rates, portfolio upload
- [ ] Client: Budget preferences
- [ ] Location detection and distance calculation
- [ ] Skill quiz for workers

## 🧪 Testing

Backend tests:
```bash
cd backend
npm test
```

## 📝 Notes

- Email verification tokens expire in 24 hours
- Password reset tokens expire in 1 hour
- Rate limiting enabled (5 attempts per 15 min for auth endpoints)
- All passwords are hashed with bcrypt
- CORS enabled for frontend origin
- Redis used for session management and rate limiting

## 👨‍💻 Development

To run both backend and frontend concurrently:

```bash
# Terminal 1 (Backend)
cd backend && npm run dev

# Terminal 2 (Frontend)
cd frontend && npm run dev
```

## 🐛 Troubleshooting

**Database connection error:**
- Ensure PostgreSQL is running
- Check DATABASE_URL in .env

**Redis connection error:**
- Ensure Redis server is running
- Check REDIS_URL in .env

**Email not sending:**
- For Gmail, enable "Less secure app access" or use App Password
- Check EMAIL_USER and EMAIL_PASSWORD in .env

## 📄 License

MIT

---

**Built with ❤️ for students, by students**
