import 'app_localizations.dart';

class AppLocalizationsId extends AppLocalizations {
  const AppLocalizationsId();

  // ─── Meta ─────────────────────────────────────────────────────────────────────
  @override String get languageCode => 'id';
  @override String get languageName => 'Indonesia';
  @override String get home => 'Beranda';

  // ─── Auth — Login ─────────────────────────────────────────────────────────────
  @override String get welcomeBack => 'Selamat datang kembali';
  @override String get loginSubtitle => 'Masuk untuk mengelola keuanganmu';
  @override String get email => 'Email';
  @override String get password => 'Kata Sandi';
  @override String get forgotPassword => 'Lupa Kata Sandi?';
  @override String get loginButton => 'Masuk';
  @override String get emailHint => 'email@contoh.com';
  @override String get passwordHint => 'Kata sandi';
  @override String get emailRequired => 'Email wajib diisi';
  @override String get invalidEmail => 'Format email tidak valid';
  @override String get passwordRequired => 'Kata sandi wajib diisi';
  @override String get noAccount => 'Belum punya akun? ';
  @override String get signUpNow => 'Daftar sekarang';
  @override String get loginFailed => 'Login Gagal';

  // ─── Auth — Register ──────────────────────────────────────────────────────────
  @override String get createAccount => 'Buat akun baru';
  @override String get registerSubtitle =>
      'Mulai perjalanan finansialmu bersama CuanBuddy!';
  @override String get fullName => 'Nama Lengkap';
  @override String get confirmPassword => 'Konfirmasi Kata Sandi';
  @override String get fullNameHint => 'Masukkan nama lengkapmu';
  @override String get passwordMinHint => 'Minimal 8 karakter';
  @override String get confirmPasswordHint => 'Ulangi kata sandimu';
  @override String get fullNameRequired => 'Nama lengkap wajib diisi';
  @override String get nameTooShort => 'Nama minimal 2 karakter';
  @override String get confirmPasswordRequired =>
      'Konfirmasi kata sandi wajib diisi';
  @override String get passwordsDoNotMatch => 'Kata sandi tidak cocok';
  @override String get passwordMin8 => 'Kata sandi minimal 8 karakter';
  @override String get weak => 'Lemah';
  @override String get fair => 'Cukup';
  @override String get strong => 'Kuat';
  @override String get veryStrong => 'Sangat Kuat 💪';
  @override String get signUp => 'Daftar';
  @override String get alreadyHaveAccount => 'Sudah punya akun? ';
  @override String get logInLink => 'Masuk';
  @override String get error => 'Error';

  // ─── Auth — Forgot Password ───────────────────────────────────────────────────
  @override String get forgotPasswordTitle => 'Lupa Kata Sandi? 🔐';
  @override String get enterOtpSentToEmail =>
      'Masukkan OTP yang dikirim ke emailmu';
  @override String get enterEmailForOtp =>
      'Masukkan emailmu untuk menerima kode OTP';
  @override String get passwordChangedSuccess => 'Kata sandi berhasil diubah!';
  @override String get canNowLoginNewPassword =>
      'Kamu sekarang bisa masuk dengan kata sandi baru';
  @override String get otpCode => 'Kode OTP';
  @override String get newPassword => 'Kata Sandi Baru';
  @override String get emailHintForgot => 'email@contoh.com';
  @override String get otpHint => 'Kode OTP 6 digit';
  @override String get otpRequired => 'OTP wajib diisi';
  @override String get sendOtp => 'Kirim OTP';
  @override String get resetPassword => 'Reset Kata Sandi';
  @override String get resendOtp => 'Kirim Ulang OTP';
  @override String get logInNow => 'Masuk Sekarang';
  @override String get pleaseEnterEmailFirst =>
      'Silakan masukkan emailmu terlebih dahulu 😊';
  @override String get otpSentToEmail => 'OTP telah dikirim ke emailmu 📧';
  @override String get info => 'Info';

  // ─── Auth — Email Verification ────────────────────────────────────────────────
  @override String get verifyEmail => 'Verifikasi Email';
  @override String get waitingForActivation => 'Menunggu Aktivasi';
  @override String get verificationRequired => 'Verifikasi Diperlukan';
  @override String verificationLinkSentTo(String email) =>
      'Klik tombol di bawah untuk mendapatkan tautan verifikasi ke\n$email';
  @override String get verificationLinkSent =>
      'Klik tombol di bawah untuk mendapatkan tautan verifikasi.';
  @override String get checkYourEmail => 'Periksa Emailmu';
  @override String weHaveSentVerificationTo(String email) =>
      'Kami telah mengirim tautan verifikasi ke $email.\n\nSilakan periksa kotak masukmu dan klik tautan untuk mengaktifkan akun. Lalu kembali ke sini untuk memeriksa statusmu.';
  @override String get accountVerified => 'Akun Terverifikasi!';
  @override String get redirectingToLogin =>
      'Emailmu telah berhasil diverifikasi.\nKamu akan diarahkan ke halaman login dalam 5 detik...';
  @override String get didNotReceiveEmail =>
      'Tidak menerima email? Periksa folder spam 📬';
  @override String get sendVerificationEmail => 'Kirim Email Verifikasi';
  @override String get backToLogin => 'Kembali ke Login';
  @override String get checkUserStatus => 'Periksa Status Akun';
  @override String get goToLogin => 'Ke Halaman Login';
  @override String get goToLoginNow => 'Ke Login Sekarang';
  @override String get accountVerifiedRedirecting =>
      'Akun terverifikasi! Mengarahkan ke login...';
  @override String get accountNotYetVerified =>
      'Akun belum terverifikasi. Silakan periksa email dan klik tautannya.';
  @override String get success => 'Berhasil';

  // ─── Splash ───────────────────────────────────────────────────────────────────
  @override String get splashTagline => 'Kelola keuanganmu dengan cerdas ✨';

  // ─── Dashboard ────────────────────────────────────────────────────────────────
  @override String get hello => 'Halo, ';
  @override String get aiAdvisor => 'Asisten AI';
  @override String get totalBalance => 'Total Saldo';
  @override String get income => '📈 Pemasukan';
  @override String get expense => '📉 Pengeluaran';
  @override String get recentActivities => 'Aktivitas Terkini';
  @override String get seeAll => 'Lihat Semua';
  @override String get spendingByCategory => 'Pengeluaran per Kategori';
  @override String get budgetDetails => 'Detail Anggaran';
  @override String get monthlyTrend => 'Tren Bulanan';
  @override String get transaction => 'Transaksi';
  @override String get other => 'Lainnya';
  @override String get you => 'Kamu';
  @override String get noTransactionsYet => 'Belum ada transaksi';
  @override String get startRecordingTransactions =>
      'Mulai catat pemasukan & pengeluaranmu!';
  @override String get failedToLoadTransactions =>
      'Gagal memuat transaksi 😅';
  @override String get noSpendingData => 'Tidak Ada Data Pengeluaran';
  @override String get addExpensesToSeeBreakdown =>
      'Tambahkan pengeluaran untuk melihat rincian.';
  @override String get noTrendData => 'Tidak Ada Data Tren';
  @override String get startRecordingToSeeTrend =>
      'Mulai catat transaksi untuk melihat tren bulananmu.';
  @override String get withinBudget =>
      'Bagus! Kamu masih dalam batas anggaran bulan ini 🎉';
  @override String get approachingBudget =>
      'Hati-hati! Kamu hampir mencapai batas anggaranmu 💡';
  @override String get exceededBudget =>
      'Oh tidak! Kamu telah melebihi anggaran bulan ini 🆘';
  @override String get tryAgain => 'Coba Lagi';

  // ─── Transactions ─────────────────────────────────────────────────────────────
  @override String get transactions => 'Transaksi';
  @override String get addTransaction => 'Tambah Transaksi';
  @override String get allTypes => 'Semua Tipe';
  @override String get allCategories => 'Semua Kategori';
  @override String get noTransactionsYetTitle => 'Belum ada transaksi';
  @override String get noTransactionsYetSubtitle =>
      'Mulai catat pemasukan & pengeluaranmu!';
  @override String get failedToLoadTransactionsError =>
      'Gagal memuat transaksi 😅';
  @override String get failedToLoadCategories => 'Gagal memuat kategori';
  @override String get edit => 'Edit';
  @override String get delete => 'Hapus';
  @override String get deleteTransaction => 'Hapus Transaksi';
  @override String get deleteTransactionConfirm =>
      'Apakah kamu yakin ingin menghapus transaksi ini?';
  @override String get cancel => 'Batal';
  @override String get failedToDelete => 'Gagal menghapus';
  @override String get saving => 'Menyimpan...';
  @override String get saveTransaction => 'Simpan Transaksi';
  @override String get amount => 'Jumlah';
  @override String get category => 'Kategori';
  @override String get noteOptional => 'Catatan (Opsional)';
  @override String get date => 'Tanggal';
  @override String get amountRequired => 'Jumlah wajib diisi';
  @override String get invalidAmount => 'Jumlah tidak valid';
  @override String get pleaseSelectCategory => 'Silakan pilih kategori';
  @override String get transactionSaved => 'Transaksi berhasil disimpan!';
  @override String get failedToSave => 'Gagal menyimpan';
  @override String get editTransaction => 'Edit Transaksi';
  @override String get expenseHint => 'Mis., Makan siang bersama rekan';
  @override String get expenseType => 'Pengeluaran';
  @override String get incomeType => 'Pemasukan';
  @override String get noCategories => 'Tidak ada kategori';

  // ─── Budgets ──────────────────────────────────────────────────────────────────
  @override String get budgets => 'Anggaran';
  @override String get totalBudget => 'Total Anggaran';
  @override String get all => 'Semua';
  @override String get onTrack => 'Sesuai Rencana';
  @override String get warning => 'Peringatan';
  @override String get exceeded => 'Terlampaui';
  @override String get budgetExceeded => 'Anggaran terlampaui!';
  @override String get budget => 'Anggaran';
  @override String get noBudgetsSet => 'Belum Ada Anggaran';
  @override String get noBudgetsSetSubtitle =>
      'Ketuk + untuk menetapkan batas pengeluaran bulanan pertamamu.';
  @override String noBudgetsFilter(String filter) => 'Tidak Ada Anggaran $filter';
  @override String get tryChangingFilter => 'Coba ubah filter.';
  @override String get setBudget => 'Tetapkan Anggaran';
  @override String get limitAmount => 'Jumlah Batas';
  @override String get month => 'Bulan';
  @override String get saveBudget => 'Simpan Anggaran';
  @override String get budgetSaved => 'Anggaran berhasil disimpan';
  @override String get errorSavingBudget => 'Gagal menyimpan anggaran';
  @override String get recurringBudget => 'Anggaran Berulang (Tiap Bulan)';
  @override String get rolloverRemaining => 'Akumulasi Sisa Anggaran (Rollover)';

  // ─── Savings ──────────────────────────────────────────────────────────────────
  @override String get savingsGoals => 'Tabungan';
  @override String get totalSaved => 'Total Tersimpan';
  @override String get goals => 'Tujuan';
  @override String get completed => 'Selesai';
  @override String get remaining => 'Sisa';
  @override String get inProgress => 'Sedang Berjalan';
  @override String daysOverdue(int days) => '${days.abs()} hari terlambat';
  @override String get dueToday => 'Jatuh tempo hari ini!';
  @override String daysLeft(int days) => '$days hari lagi';
  @override String get completedBadge => 'Selesai';
  @override String get unnamedGoal => 'Tujuan Tanpa Nama';
  @override String get noSavingsGoals => 'Belum Ada Tujuan Tabungan';
  @override String get noSavingsGoalsSubtitle =>
      'Ketuk ikon + untuk menyisihkan uang untuk impianmu.';
  @override String noGoalsFilter(String filter) => 'Tidak Ada Tujuan $filter';
  @override String get updateFunds => 'Perbarui Dana';
  @override String get newGoal => 'Tujuan Baru';
  @override String get goalName => 'Nama Tujuan';
  @override String get targetAmount => 'Target Jumlah';
  @override String get initialAmountSaved => 'Jumlah Awal Tersimpan (Opsional)';
  @override String get targetDateOptional => 'Tanggal Target (Opsional)';
  @override String get goalNameHint => 'mis. Mobil Baru';
  @override String get selectDate => 'Pilih tanggal';
  @override String get nameRequired => 'Nama wajib diisi';
  @override String get saveGoal => 'Simpan Target';
  @override String get goalSavedSuccess => 'Target berhasil disimpan';
  @override String get errorSavingGoal => 'Gagal menyimpan target';
  @override String get addFunds => 'Tambah Dana';
  @override String get reduceFunds => 'Kurangi Dana';
  @override String get reduce => 'Kurangi';
  @override String get balanceCannotBeNegative => 'Saldo tidak boleh negatif';
  @override String get fundsAddedSuccess => 'Dana berhasil ditambahkan!';
  @override String get fundsReducedSuccess => 'Dana berhasil dikurangi!';
  @override String updateGoalTitle(String name) => 'Perbarui $name';

  // ─── Categories ───────────────────────────────────────────────────────────────
  @override String get manageCategories => 'Kelola Kategori';
  @override String get noCategoriesFound => 'Tidak ada kategori.';
  @override String get deleteCategory => 'Hapus Kategori?';
  @override String get deleteCategoryConfirm =>
      'Apakah kamu yakin ingin menghapus kategori ini?';
  @override String get newCategory => 'Kategori Baru';
  @override String get editCategory => 'Edit Kategori';
  @override String get categoryName => 'Nama Kategori';
  @override String get categoryNameHint => 'mis., Makanan & Minuman';
  @override String get createCategory => 'Buat Kategori';
  @override String get saveChanges => 'Simpan Perubahan';
  @override String get categorySaved => 'Kategori berhasil disimpan';
  @override String get pleaseFillAllFields => 'Harap isi semua kolom';
  @override String get anErrorOccurred => 'Terjadi kesalahan';

  // ─── Notifications ────────────────────────────────────────────────────────────
  @override String get notifications => 'Notifikasi';
  @override String get markAllRead => 'Tandai semua dibaca';
  @override String get noNotifications => 'Tidak Ada Notifikasi';
  @override String get noNotificationsSubtitle =>
      'Semua sudah terbaca! Cek lagi nanti.';
  @override String get notification => 'Notifikasi';

  // ─── AI Chat ──────────────────────────────────────────────────────────────────
  @override String get cuanBuddyAI => 'CuanBuddy AI';
  @override String get askAboutFinances => 'Tanya tentang keuanganmu...';

  // ─── Analytics ────────────────────────────────────────────────────────────────
  @override String get analytics => 'Analitik';
  @override String get thisMonth => 'Bulan Ini';
  @override String get lastMonth => 'Bulan Lalu';
  @override String get last3Months => '3 Bulan Terakhir';
  @override String get last6Months => '6 Bulan Terakhir';
  @override String get thisYear => 'Tahun Ini';
  @override String get topCategories => 'Kategori Teratas';
  @override String get noAnalyticsData => 'Tidak ada data tersedia';

  // ─── Profile ──────────────────────────────────────────────────────────────────
  @override String get profile => 'Profil';
  @override String get preferences => 'Preferensi';
  @override String get account => 'Akun';
  @override String get darkMode => 'Mode Gelap';
  @override String get language => 'Bahasa';
  @override String get currency => 'Mata Uang';
  @override String get backupRestore => 'Backup & Pemulihan';
  @override String get editProfile => 'Ubah Profil';
  @override String get logOut => 'Keluar';
  @override String get logOutTitle => 'Keluar';
  @override String get logOutConfirm =>
      'Apakah kamu yakin ingin keluar?';
  @override String get selectCurrency => 'Pilih Mata Uang';
  @override String get currencyUpdated => 'Mata uang diperbarui';
  @override String currencyUpdatedTo(String currency) =>
      'Mata uang diperbarui ke $currency';
  @override String get failedToUpdateCurrency => 'Gagal memperbarui mata uang';
  @override String get failedToLoadProfile => 'Gagal memuat profil';
  @override String get failed => 'Gagal';
  @override String get selectLanguage => 'Pilih Bahasa';

  // ─── Change Password ──────────────────────────────────────────────────────────
  @override String get changePassword => 'Ganti Password';
  @override String get oldPassword => 'Password Lama';
  @override String get oldPasswordHint => 'Masukkan password Anda saat ini';
  @override String get newPasswordHint => 'Masukkan password baru Anda';
  @override String get confirmNewPasswordHint => 'Ulangi password baru Anda';
  @override String get oldPasswordRequired => 'Password lama wajib diisi';

  // ─── Edit Profile ─────────────────────────────────────────────────────────────
  @override String get chooseAvatar => 'Pilih Avatar';
  @override String get personalInfo => 'Informasi Pribadi';
  @override String get currentAvatarLabel => '★ = avatar kamu saat ini';
  @override String get phoneNumberOptional => 'Nomor Telepon (Opsional)';
  @override String get dateOfBirthOptional => 'Tanggal Lahir (Opsional)';
  @override String get phoneHint => '+62...';
  @override String get selectDateHint => 'Pilih tanggal';
  @override String get profileUpdatedSuccess => 'Profil berhasil diperbarui';
  @override String get failedToUpdateProfile => 'Gagal memperbarui profil';
  @override String get savingLabel => 'Menyimpan...';

  // ─── Backup & Restore ─────────────────────────────────────────────────────────
  @override String get backupSettings => 'Pengaturan Backup';
  @override String get step2of2 => 'Langkah 2/2';
  @override String get enableAutoBackup =>
      'Aktifkan backup otomatis untuk menjaga keamanan datamu 🔒';
  @override String get autoBackup => 'Backup Otomatis';
  @override String get autoBackupActive => 'Backup otomatis aktif';
  @override String get backupYourDataAuto =>
      'Backup datamu secara otomatis';
  @override String get backupFrequency => 'Frekuensi Backup';
  @override String get selectDataToBackup =>
      'Pilih Data untuk Backup/Pemulihan';
  @override String get manualAction => 'Aksi Manual';
  @override String get everyDay => 'Setiap Hari';
  @override String get dailyBackupDesc => 'Backup otomatis harian';
  @override String get everyWeek => 'Setiap Minggu';
  @override String get weeklyBackupDesc => 'Backup otomatis mingguan';
  @override String get everyMonth => 'Setiap Bulan';
  @override String get monthlyBackupDesc => 'Backup otomatis bulanan';
  @override String get transactionsLabel => 'Transaksi';
  @override String get budgetsLabel => 'Anggaran';
  @override String get savingsGoalsLabel => 'Tabungan';
  @override String get categoriesLabel => 'Kategori';
  @override String get backupNow => 'Backup Sekarang';
  @override String get restore => 'Pulihkan';
  @override String get finishAndStart => 'Selesai & Mulai 🚀';
  @override String get skip => 'Lewati';
  @override String get backupSettingsSaved => 'Pengaturan backup disimpan ✅';
  @override String get failedToSaveSettings => 'Gagal menyimpan pengaturan';
  @override String get restoreData => 'Pulihkan Data';
  @override String get restoreInstructions =>
      'Untuk memulihkan data dengan benar, pastikan file Excel atau ZIP kamu mengikuti struktur template standar kami. Kamu bisa unduh template di bawah, isi, lalu unggah.';
  @override String get downloadTemplates => 'Unduh Template';
  @override String get uploadAndRestore => 'Unggah & Pulihkan';
  @override String get backupStarted => 'Backup dimulai...';
  @override String get failedToLoadBackupSettings =>
      'Gagal memuat pengaturan backup';

  // ─── Profile Setup ────────────────────────────────────────────────────────────
  @override String get step1of2 => 'Langkah 1/2';
  @override String get completeYourProfile => 'Lengkapi Profilmu';
  @override String get profileSetupSubtitle =>
      'Ayo personalisasi pengalaman CuanBuddy-mu ✨';
  @override String get phoneNumberField => 'Nomor Telepon (Opsional)';
  @override String get continueButton => 'Lanjutkan';
  @override String get nameTooShortSetup => 'Nama minimal 2 karakter';
  @override String get failedToSaveProfile => 'Gagal menyimpan profil';

  // ─── Common ───────────────────────────────────────────────────────────────────
  @override String get retry => 'Coba Lagi';
  @override String get close => 'Tutup';
  @override String get ok => 'OK';
  @override String get confirm => 'Konfirmasi';
  @override String get loading => 'Memuat...';
  @override String get failedGeneric =>
      'Terjadi kesalahan. Silakan coba lagi.';
  @override String spent(String amount) => 'Terpakai: $amount';
  @override String of_(String amount) => 'dari $amount';

  // ─── Onboarding ──────────────────────────────────────────────────────────────
  @override String get onboardingTitle1 => 'Catat Pengeluaranmu';
  @override String get onboardingDesc1 => 'Catat dan kategorikan pemasukan serta pengeluaranmu dengan mudah untuk melacak aliran uangmu.';
  @override String get onboardingTitle2 => 'Anggaran Pintar';
  @override String get onboardingDesc2 => 'Atur batasan bulanan per kategori dan dapatkan peringatan saat hampir melampauinya.';
  @override String get onboardingTitle3 => 'Penasihat Finansial AI';
  @override String get onboardingDesc3 => 'Konsultasi dengan asisten AI personalmu untuk mendapat saran dan analisis kesehatan keuangan.';
  @override String get getStarted => 'Mulai Sekarang';
  @override String get next => 'Lanjut';

  // ─── AI Voice ───────────────────────────────────────────────────────────────
  @override String get aiVoiceTitle => 'Konfirmasi Transaksi';
  @override String get aiVoiceTapToStart => 'Ketuk mikrofon untuk mulai berbicara';
  @override String get aiVoiceTapToStop => 'Ketuk mikrofon saat selesai berbicara';
  @override String get aiVoiceListening => 'Mendengarkan...';
  @override String get aiVoiceAnalyzing => 'AI sedang menganalisis...';
  @override String get aiVoiceExtracting => 'Mengekstrak nominal dan kategori';
  @override String get aiVoiceFailed => 'Gagal memproses suara.';
  @override String get aiVoiceErrorUnclear => 'Suara tidak jelas atau gagal memproses.';
  @override String get aiVoiceTitleField => 'Judul';
  @override String get aiVoiceAmountField => 'Nominal';
  @override String get aiVoiceTypeField => 'Tipe';
  @override String get aiVoiceCategoryField => 'Kategori';
  @override String get aiVoiceIncome => 'Pemasukan';
  @override String get aiVoiceExpense => 'Pengeluaran';
  @override String get aiVoiceSave => 'Simpan Transaksi';
  @override String get aiVoiceBack => 'Rekam Ulang';
  @override String get aiVoiceSuccess => 'Transaksi disimpan melalui AI Voice!';
}
