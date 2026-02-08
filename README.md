# Happle - Student Task Marketplace (Mobile)

A Tinder-style mobile platform connecting college students for quick tasks and gigs. Built with Flutter and Supabase.

## 🚀 Project Status: High-Fidelity Mobile App ✅

### ✅ Core Features (Flutter):
- **Tinder-Style Task Matching**: Swipe-based interface for workers to find tasks.
- **Supabase Real-time Backend**: Instant updates for tasks, matches, and chat.
- **Advanced KYC System**: Identity verification using Google ML Kit (OCR & Face Detection).
- **Secure Payments**: Integrated with Razorpay for escrow and wallet management.
- **Real-time Communication**: Chat and Video/Voice calling via Agora RTC.
- **Live Tracking**: Geo-location heartbeats for active gigs using PostGIS.

## 📁 Project Structure

```
Happle/
└── mobile_new/
    ├── lib/
    │   ├── config/         # App themes and constants
    │   ├── data_types/     # Domain models
    │   ├── managers/       # Riverpod logic & state management
    │   ├── screens/        # UI Layers (Auth, Swipe, Chat, KYC)
    │   ├── services/       # Supabase, Agora, & ML Kit integrations
    │   └── widgets/        # Reusable UI components
    ├── android/
    ├── ios/
    └── supabase_schema.sql # Database schema & functions
```

## 🛠️ Tech Stack

### Mobile App:
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Persistence**: Supabase Flutter
- **Real-time**: Supabase Channels

### Infrastructure:
- **Database**: PostgreSQL (Supabase) with PostGIS
- **Payments**: Razorpay
- **Video/Voice**: Agora RTC
- **Machine Learning**: Google ML Kit (Face/Text)

## 🚦 Getting Started

### Prerequisites:
- Flutter SDK (>=3.0.0)
- Supabase Project (URL & Anon Key)

### Mobile Setup:

1. Navigate to mobile directory:
```bash
cd mobile_new
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## 📡 API Endpoints (via Supabase RPC/Realtime)

### Authentication:
- Supabase Auth handles Email/Password and Google Sign-In.

### Marketplace:
- Real-time task feeds and proximity-based matching.

## 🔐 Presence & Activity
- **Live Calorie Scan**: Real-time meal analysis.
- **Presence Tracking**: Users are only "Active" when the app is in foreground and screen is on.

## 🧪 Testing

```bash
cd mobile_new
flutter test
```

## 👨‍💻 Development

The project is now fully focused on the high-fidelity Flutter mobile experience. Backend logic is centralized in Supabase Edge Functions and PostgreSQL Triggers/RPCs.

## 📄 License

MIT

**Built with ❤️ for students, by students**
