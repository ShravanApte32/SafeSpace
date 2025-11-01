# 💗 Safe Space

> **An anonymous, safe, and empathetic platform for emotional expression, healing, and human connection.**

Safe Space provides a judgment-free space where users can share their feelings, reflect through journaling, connect to listeners (AI + human), and access verified mental health resources worldwide.

---

## 🧭 Purpose

> “A digital safe space for people who feel unheard.”

Safe Space combines empathy, privacy, and technology to create a platform that listens — helping users express emotions safely and find support through journaling, conversations, and community.

---

## 🌟 Core Values

- 🛡 **Privacy:** Anonymous mode, end-to-end encrypted data  
- 💬 **Empathy:** Emotionally intelligent interactions  
- 🌍 **Accessibility:** Cross-platform, inclusive UI/UX  
- 💡 **Global Reach:** Localized helplines & multi-language ready  

---

## ⚙️ Tech Stack

| Layer | Technology | Purpose |
|-------|-------------|----------|
| **Frontend** | Flutter | Cross-platform app (Android, iOS, Web) |
| **Backend API** | Node.js + Express (Hosted on Render) | REST API for journaling, AI chat, and analytics |
| **Database** | Supabase (PostgreSQL) | Encrypted storage, Auth, and Realtime sync |
| **AI Services** | OpenAI / Hugging Face | Sentiment detection, AI listener |
| **Notifications** | Firebase Cloud Messaging | Daily mood prompts |
| **Hosting** | Render + Supabase | Backend + Database |
| **Version Control** | GitHub | Project management & collaboration |

---

## 🧩 App Architecture

splash_screen -
- splash_screen.dart

welcome_screen -
- welcome_screen.dart

urgent_help_screen -
- urgent_help_screen.dart
- emergency_contacts_screen.dart

onboarding_screen -
- onboarding_screen.dart

login_screen -
- login_screen.dart

homepage -
- journal
	- journal_page.dart
	- journal_storage.dart
- chat
	- ai_chat
		- ai_chat.dart
	- human_chat
		- human_chat.dart
	- community_chat
		- community_chat.dart
- home
	- exercises
		- breathing_exercises.dart
		- meditation.dart
	- homepage.dart
- explore
	- talents
		- talents.dart
	- hobbies
		- hobbies.dart
	- creative challenges
		-creative_challenges.dart
- profile
	- profile
		- profile.dart
	- settings
		- settings.dart
	- stats
		- stats.dart
	- safety & privacy
		- safety_privacy.dart

## 🧠 Key Features (Phase-wise)

### **Phase 1 – MVP**
- 🧭 Onboarding & Guest Mode  
- 📔 Anonymous Journal (text/voice)  
- 🌤 Daily Mood Check-in  
- 🤖 AI Sentiment Detection  
- ☎️ Helpline Directory (localized)  

### **Phase 2 – Expansion**
- 💬 Instant Listener Chat (Human + AI)  
- 🌍 Community Board (anonymous sharing)  
- 📈 Mood History & Insights  
- 📶 Offline Journaling  

### **Phase 3 – Advanced**
- 🚨 Location-Based Crisis Alerts  
- 🎙 AI Voice Companion  
- 💖 Gamified Healing Journey  

---

## 🧰 API Overview (Express + Supabase)

| Endpoint | Method | Description |
|-----------|--------|-------------|
| `/api/journal/create` | `POST` | Save journal entry (text/voice) |
| `/api/journal/get` | `GET` | Fetch user’s journal history |
| `/api/sentiment/analyze` | `POST` | Analyze text using OpenAI/Hugging Face |
| `/api/helplines` | `GET` | Fetch country-based helpline data |
| `/api/listener/connect` | `POST` | Connect to volunteer listener |
| `/api/auth/signup` | `POST` | Register new user (optional) |
| `/api/auth/login` | `POST` | Log in user |
| `/api/insights/mood` | `GET` | Get mood trends and recommendations |

---

## 🗃 Database (Supabase Schema - Example)

| Table | Columns |
|--------|----------|
| `users` | id, email, country, is_anonymous, created_at |
| `journal_entries` | id, user_id, content, mood, sentiment_score, created_at |
| `helplines` | id, country, name, phone, type |
| `listeners` | id, name, language, availability_status |
| `mood_trends` | id, user_id, mood, timestamp |

---

## 🧱 System Architecture Diagram

    ┌────────────────────┐
    │     Flutter App     │
    │ (Android / iOS / Web) │
    └──────────┬──────────┘
               │
 	HTTPS / JSON API Calls
               │
    ┌──────────▼──────────┐
    │   Express.js Server  │
    │ (Hosted on Render)   │
    └──────────┬──────────┘
               │
     REST / WebSocket / Realtime
               │
    ┌──────────▼──────────┐
    │     Supabase DB      │
    │ (PostgreSQL + Auth)  │
    └──────────┬──────────┘
               │
    ┌──────────▼──────────┐
    │  OpenAI / HuggingFace │
    │ (Sentiment + AI Chat) │
    └───────────────────────┘


