# CuanBuddy (Monorepo)

CuanBuddy adalah aplikasi personal finance asisten cerdas yang dilengkapi AI untuk menganalisa pengeluaran, auto-categorize, rekomendasi budget harian, dan fitur notifikasi pintar (anomaly detection). 

Repository ini adalah struktur monorepo yang berisi:
1. **`backend_api/`**: NestJS REST API Server (PostgreSQL Neon Serverless + Drizzle ORM).
2. **`frontend_app/`**: Folder untuk frontend aplikasi (misalnya web verifikasi email dengan React/Vite + Tailwind v4).

## Arsitektur & Teknologi

### Backend (NestJS)
- **Framework**: NestJS (TypeScript)
- **Database**: PostgreSQL (Neon Serverless)
- **ORM**: Drizzle ORM (schema-first, highly optimized)
- **AI Engine**: Google Gemini Pro (langsung terintegrasi menggunakan SDK resmi)
- **Security**: JWT Authentication, Bcrypt Hashing, OTP-based Reset Password, Email Verification.
- **Deployment**: Dioptimalkan khusus untuk Vercel Serverless Functions.

### Frontend
- **Framework**: React (Vite)
- **Styling**: Tailwind CSS v4

---

## Fitur Utama API

1. **Authentication (JWT-based)**
   - Register (Email verification flow using Nodemailer SMTP).
   - Login (Zero-database query JWT verification via `is_active` payload).
   - Lupa Password (6-digit OTP expiration).

2. **CuanBuddy AI**
   - **Spending Insights**: Menghasilkan ringkasan dan opini AI dari data transaksi bulanan user.
   - **Auto-Categorize**: Mengkategorisasikan transaksi secara otomatis (mis. "Beli kopi" -> Food & Drink) menggunakan JSON-mode AI.
   - **Budget Recommendation**: Analisis AI yang menentukan limit wajar per kategori berdasarkan pola hidup/pendapatan user.
   - **Chat AI**: Tanya-jawab bahasa natural (mendukung Auto-Language Detection - Indonesia/English) tentang finansial user.
   - **Anomaly Detection**: Mendeteksi lonjakan pengeluaran tiba-tiba (contoh: langganan tersembunyi/pengeluaran abnormal).

3. **Data Management & Backup**
   - CRUD Transaksi, Budget, Kategori, Profil, Target Tabungan.
   - **Backup & Restore**: Automasi Export ZIP (berisi file Excel multi-tabel) tanpa membebani storage/Vercel (On-The-Fly Streaming Archive). Import dari Excel/ZIP.

---

## Panduan Lokal (Development)

### Backend Setup
1. Masuk ke folder backend: `cd backend_api`
2. Install dependencies: `npm install`
3. Salin environment variables: `cp .env.example .env` lalu isi (URL Neon DB, JWT Secret, Gemini Key, SMTP).
4. Sync skema database: `npx drizzle-kit push`
5. Jalankan server: `npm run start:dev` (Berjalan di `http://localhost:3000`)
6. Dokumentasi API (Swagger) dapat diakses di: `http://localhost:3000/api-docs`

---

## Dokumentasi API (Swagger)
Backend CuanBuddy menyediakan Swagger UI yang mendokumentasikan setiap rute secara interaktif. Saat menjalankan backend secara lokal, kunjungi `http://localhost:3000/api-docs`.
