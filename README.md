# 💗 HereForYou

> **An anonymous, safe, and empathetic platform for emotional expression, healing, and human connection.**

HereForYou provides a judgment-free space where users can share their feelings, reflect through journaling, connect to listeners (AI + human), and access verified mental health resources worldwide.

---

## 🧭 Purpose

> “A digital safe space for people who feel unheard.”

HereForYou combines empathy, privacy, and technology to create a platform that listens — helping users express emotions safely and find support through journaling, conversations, and community.

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
