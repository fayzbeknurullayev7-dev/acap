# ⚡ ACAP — AI Coding Agent Platform

> Mobile-first AI IDE | Flutter + FastAPI + Multi-Agent

---

## Loyiha tuzilishi

```
acap/
├── acap_app/                        # Flutter Android ilovasi
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/                     # Router, Theme
│   │   ├── core/                    # Network, Storage, Errors
│   │   └── features/
│   │       ├── auth/                # ✅ Stage 1 — Login, OTP, Splash
│   │       ├── editor/              # ✅ Stage 6 — Code Editor
│   │       ├── terminal/            # ✅ Stage 6 — PTY Terminal
│   │       └── agent/               # ✅ Stage 5 — Agent Orchestrator UI
│   └── pubspec.yaml
│
├── acap_backend/
│   └── services/
│       ├── auth/                    # ✅ Stage 2 — FastAPI Auth (JWT, OTP, Google)
│       ├── agent/                   # ✅ Stage 5 — Agent Orchestrator
│       └── terminal/                # ✅ Stage 6 — PTY Terminal Service
│
└── docker-compose.yml               # Barcha servislarni birga ishga tushirish
```

---

## Bosqichlar

| Bosqich | Nima | Status |
|---------|------|--------|
| 1 | Flutter Auth (Splash, Onboarding, Login, OTP) | ✅ |
| 2 | FastAPI Auth Service (JWT, Google OAuth, OTP) | ✅ |
| 3 | Dashboard + Projects UI | ⏳ |
| 4 | AI Chat + WebSocket | ⏳ |
| 5 | Agent Orchestrator | ✅ |
| 6 | Code Editor + Terminal | ✅ |
| 7 | Git + Deploy | ⏳ |
| 8 | Billing + Final | ⏳ |

---

## Ishga tushirish

### Backend (Docker)

```bash
# .env fayl yarating
cp .env.example .env
# Kerakli kalitlarni to'ldiring (JWT_SECRET_KEY, GOOGLE_CLIENT_ID, ...)

# Barcha servislarni ishga tushiring
docker-compose up -d

# Loglarni koring
docker-compose logs -f auth-service
docker-compose logs -f terminal-service
```

**Endpoints:**
- Auth Service:     http://localhost:8000/docs
- Agent Service:    http://localhost:8001/docs
- Projects Service: http://localhost:8002/docs
- Terminal Service: http://localhost:8003/docs
- Files Service:    http://localhost:8004/docs

### Flutter

```bash
cd acap_app

# google-services.json ni android/app/ ga qo'ying (Firebase Console dan)

flutter pub get
flutter run
```

---

## Arxitektura haqida

- **Flutter** — Riverpod (state), GoRouter (navigation), Dio (HTTP), Hive (local DB)
- **FastAPI** — Async SQLAlchemy, Redis, WebSocket
- **Auth** — Google OAuth2 + Email OTP + JWT (access + refresh + rotation)
- **Terminal** — Real PTY (pseudo-terminal) orqali haqiqiy bash shell
- **Editor** — `re_editor` paketi, 20+ til syntax highlighting, AI autocomplete
- **Agents** — Groq API (tezlik) + Gemini API (vision), Redis Streams orqali parallel

---

## .env.example

```env
JWT_SECRET_KEY=your-256-bit-random-secret
GOOGLE_CLIENT_ID=your-google-client-id
GROQ_API_KEY=your-groq-key
GEMINI_API_KEY=your-gemini-key
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
```
