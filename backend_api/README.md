<div align="center">
  <img src="../app_icon_transparent.png" width="100" height="100" alt="CuanBuddy Logo">
  <h1>💰 CuanBuddy Backend API</h1>
  <p><strong>A modern, scalable, and secure RESTful API for personal finance management.</strong></p>
</div>

<hr />

## 🚀 Overview
**CuanBuddy** is designed for Gen Z and Baby Boomers alike—making financial management seamless, fast, and accessible. This backend repository serves as the core engine powering the CuanBuddy application, engineered with clean architecture, robust validations, and pre-formatted responses for rapid frontend consumption.

## 🛠️ Tech Stack
This backend leverages the absolute best of the modern Node.js ecosystem:

- **Framework**: [NestJS](https://nestjs.com/) (TypeScript-first, heavily structured)
- **Database**: PostgreSQL (Hosted on [Neon Serverless](https://neon.tech/))
- **ORM**: [Drizzle ORM](https://orm.drizzle.team/) (Lightweight, edge-ready, fully typed)
- **Validation**: [Zod](https://zod.dev/) & `nestjs-zod` (Strict schema validations)
- **Authentication**: JWT (JSON Web Tokens) with `Passport.js` and `bcrypt`
- **Language**: TypeScript

## 📂 Project Structure
The codebase follows a modular, domain-driven structure (NestJS standard) to ensure maintainability as the application scales.

```text
src/
├── analytics/         # Aggregations, financial health, spending trends
├── auth/              # JWT issuance, login, registration, password hashing
├── budgets/           # Monthly limit trackers per category
├── categories/        # Transaction & Budget categories (Income/Expense)
├── common/            # Shared resources across domains
│   ├── filters/       # Global exception filters (standardized JSON error responses)
│   └── utils/         # Pre-formatters (Currency IDR, localized Dates)
├── database/          # Database definitions
│   ├── database.module.ts # Connection injector
│   ├── relations.ts       # Foreign Key relational mappings
│   └── schema.ts          # Drizzle table schemas (Core of DB)
├── notifications/     # User alerts and in-app messages
├── savings-goals/     # Savings progress trackers
├── transactions/      # Core money-in/money-out logic
├── user-profiles/     # Avatars (DiceBear), bio, personal settings
└── users/             # Internal credential management
```

## 🧠 Code Architecture

### 1. Modules (`*.module.ts`)
Each feature has its own independent container. Dependencies are isolated.

### 2. Controllers (`*.controller.ts`)
The routing layer. It strictly handles incoming HTTP requests, extracts parameters, and passes payloads to the Service layer.

### 3. Services (`*.service.ts`)
The business logic layer. Contains all Drizzle ORM queries, condition checking, and data mapping. It is completely independent of the HTTP context.

### 4. DTOs (`dto/*.dto.ts`)
Data Transfer Objects powered by **Zod**. Every incoming request payload is strictly validated before it even hits the controller.

## ✨ Core Features
- **Smart Formatting**: The API returns pre-formatted strings (`Rp 1.000.000` or `15 Juni 2026`) alongside raw values, eliminating formatting logic on the frontend.
- **Universal Pagination**: All list endpoints (`findAll`) enforce pagination and return a standard `data` and `meta` (page, limit, total) structure.
- **Auto-Avatars**: User profiles are automatically populated with beautiful `DiceBear` generated avatars upon registration.
- **Global Error Handling**: Predictable, developer-friendly JSON error payloads globally.

## 💻 Getting Started

### Prerequisites
- Node.js (v18+)
- PostgreSQL (Neon URL recommended)

### Installation
```bash
# Install dependencies
npm install

# Push schema to Database
npx drizzle-kit push

# Seed initial categories
npx tsx seed.ts
```

### Running the App
```bash
# Development mode
npm run start:dev

# Production build
npm run build
npm run start:prod
```

---
*Built with ❤️ for CuanBuddy.*
