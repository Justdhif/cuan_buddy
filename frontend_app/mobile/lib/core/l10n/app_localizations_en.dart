import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  const AppLocalizationsEn();

  // ─── Meta ─────────────────────────────────────────────────────────────────────
  @override
  String get languageCode => 'en';
  @override
  String get languageName => 'English';
  @override
  String get home => 'Home';

  // ─── Auth — Login ─────────────────────────────────────────────────────────────
  @override
  String get welcomeBack => 'Welcome back';
  @override
  String get loginSubtitle => 'Log in to manage your finances';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get forgotPassword => 'Forgot Password?';
  @override
  String get loginButton => 'Log In';
  @override
  String get emailHint => 'email@example.com';
  @override
  String get passwordHint => 'Password';
  @override
  String get emailRequired => 'Email is required';
  @override
  String get invalidEmail => 'Invalid email format';
  @override
  String get passwordRequired => 'Password is required';
  @override
  String get noAccount => "Don't have an account? ";
  @override
  String get signUpNow => 'Sign up now';
  @override
  String get loginFailed => 'Login Failed';

  // ─── Auth — Register ──────────────────────────────────────────────────────────
  @override
  String get createAccount => 'Create an account';
  @override
  String get registerSubtitle => 'Start your financial journey with CuanBuddy!';
  @override
  String get fullName => 'Full Name';
  @override
  String get confirmPassword => 'Confirm Password';
  @override
  String get fullNameHint => 'Enter your full name';
  @override
  String get passwordMinHint => 'Minimum 8 characters';
  @override
  String get confirmPasswordHint => 'Repeat your password';
  @override
  String get fullNameRequired => 'Full name is required';
  @override
  String get nameTooShort => 'Name must be at least 2 characters';
  @override
  String get confirmPasswordRequired => 'Confirm password is required';
  @override
  String get passwordsDoNotMatch => 'Passwords do not match';
  @override
  String get passwordMin8 => 'Password must be at least 8 characters';
  @override
  String get weak => 'Weak';
  @override
  String get fair => 'Fair';
  @override
  String get strong => 'Strong';
  @override
  String get veryStrong => 'Very Strong 💪';
  @override
  String get signUp => 'Sign Up';
  @override
  String get alreadyHaveAccount => 'Already have an account? ';
  @override
  String get logInLink => 'Log In';
  @override
  String get error => 'Error';

  // ─── Auth — Forgot Password ───────────────────────────────────────────────────
  @override
  String get forgotPasswordTitle => 'Forgot Password? 🔐';
  @override
  String get enterOtpSentToEmail => 'Enter the OTP sent to your email';
  @override
  String get enterEmailForOtp => 'Enter your email to receive an OTP code';
  @override
  String get passwordChangedSuccess => 'Password successfully changed!';
  @override
  String get canNowLoginNewPassword =>
      'You can now log in with your new password';
  @override
  String get otpCode => 'OTP Code';
  @override
  String get newPassword => 'New Password';
  @override
  String get emailHintForgot => 'email@example.com';
  @override
  String get otpHint => '6-digit OTP code';
  @override
  String get otpRequired => 'OTP is required';
  @override
  String get sendOtp => 'Send OTP';
  @override
  String get resetPassword => 'Reset Password';
  @override
  String get resendOtp => 'Resend OTP';
  @override
  String get logInNow => 'Log In Now';
  @override
  String get pleaseEnterEmailFirst => 'Please enter your email first 😊';
  @override
  String get otpSentToEmail => 'OTP sent to your email 📧';
  @override
  String get info => 'Info';

  // ─── Auth — Email Verification ────────────────────────────────────────────────
  @override
  String get verifyEmail => 'Verify Email';
  @override
  String get waitingForActivation => 'Waiting for Activation';
  @override
  String get verificationRequired => 'Verification Required';
  @override
  String verificationLinkSentTo(String email) =>
      'Click the button below to receive a verification link at\n$email';
  @override
  String get verificationLinkSent =>
      'Click the button below to receive a verification link.';
  @override
  String get checkYourEmail => 'Check Your Email';
  @override
  String weHaveSentVerificationTo(String email) =>
      'We have sent a verification link to $email.\n\nPlease check your inbox and click the link to activate your account. Then return here to check your status.';
  @override
  String get accountVerified => 'Account Verified!';
  @override
  String get redirectingToLogin =>
      'Your email has been successfully verified.\nYou will be redirected to the login screen in 5 seconds...';
  @override
  String get didNotReceiveEmail =>
      "Didn't receive the email? Check your spam folder 📬";
  @override
  String get sendVerificationEmail => 'Send Verification Email';
  @override
  String get backToLogin => 'Back to Login';
  @override
  String get checkUserStatus => 'Check User Status';
  @override
  String get goToLogin => 'Go to Login';
  @override
  String get goToLoginNow => 'Go to Login Now';
  @override
  String get accountVerifiedRedirecting =>
      'Account verified! Redirecting to login...';
  @override
  String get accountNotYetVerified =>
      'Account is not yet verified. Please check your email and click the link.';
  @override
  String get success => 'Success';

  // ─── Splash ───────────────────────────────────────────────────────────────────
  @override
  String get splashTagline => 'Manage your finances smartly ✨';

  // ─── Dashboard ────────────────────────────────────────────────────────────────
  @override
  String get hello => 'Hello, ';
  @override
  String get aiAdvisor => 'AI Advisor';
  @override
  String get totalBalance => 'Total Balance';
  @override
  String get net => 'Net';
  @override
  String get income => '📈 Income';
  @override
  String get expense => '📉 Expense';
  @override
  String get recentActivities => 'Recent Activities';
  @override
  String get seeAll => 'See All';
  @override
  String get spendingByCategory => 'Spending by Category';
  @override
  String get budgetDetails => 'Budget Details';
  @override
  String get monthlyTrend => 'Monthly Trend';
  @override
  String get transaction => 'Transaction';
  @override
  String get other => 'Other';
  @override
  String get you => 'You';
  @override
  String get shared => 'Shared';
  @override
  String get noTransactionsYet => 'No transactions yet';
  @override
  String get startRecordingTransactions =>
      'Start recording your income & expenses!';
  @override
  String get failedToLoadTransactions => 'Failed to load transactions 😅';
  @override
  String get noSpendingData => 'No Spending Data';
  @override
  String get addExpensesToSeeBreakdown => 'Add expenses to see breakdown.';
  @override
  String get noTrendData => 'No Trend Data';
  @override
  String get startRecordingToSeeTrend =>
      'Start recording transactions to see your monthly trend.';
  @override
  String get withinBudget => 'Great! You are still within budget this month 🎉';
  @override
  String get approachingBudget =>
      'Careful! You are approaching your budget limit 💡';
  @override
  String get exceededBudget =>
      'Oh no! You have exceeded your budget this month 🆘';
  @override
  String get tryAgain => 'Try Again';

  // ─── Transactions ─────────────────────────────────────────────────────────────
  @override
  String get transactions => 'Transactions';
  @override
  String get transactionsSubtitle => 'Track all your income\n& expenses 👌';
  @override
  String get addTransaction => 'Add Transaction';
  @override
  String get allTypes => 'All Types';
  @override
  String get allCategories => 'All Categories';
  @override
  String get noTransactionsYetTitle => 'No transactions yet';
  @override
  String get noTransactionsYetSubtitle =>
      'Start recording your income & expenses!';
  @override
  String get failedToLoadTransactionsError => 'Failed to load transactions 😅';
  @override
  String get failedToLoadCategories => 'Failed to load categories';
  @override
  String get edit => 'Edit';
  @override
  String get delete => 'Delete';
  @override
  String get deleteTransaction => 'Delete Transaction';
  @override
  String get deleteTransactionConfirm =>
      'Are you sure you want to delete this transaction?';
  @override
  String get deleteBudget => 'Delete Budget?';
  @override
  String get deleteBudgetConfirm =>
      'Are you sure you want to delete this budget?';
  @override
  String get cancel => 'Cancel';
  @override
  String get failedToDelete => 'Failed to delete';
  @override
  String get saving => 'Saving...';
  @override
  String get saveTransaction => 'Save Transaction';
  @override
  String get transactionTitle => 'Title';
  @override
  String get titleRequired => 'Title is required';
  @override
  String get transactionTitleHint => 'E.g., Dinner with family';
  @override
  String get amount => 'Amount';
  @override
  String get category => 'Category';
  @override
  String get noteOptional => 'Note (Optional)';
  @override
  String get date => 'Date';
  @override
  String get amountRequired => 'Amount is required';
  @override
  String get invalidAmount => 'Invalid amount';
  @override
  String get pleaseSelectCategory => 'Please select a category';
  @override
  String get selectCategoryAction => 'Select Category';
  @override
  String get transactionSaved => 'Transaction saved!';
  @override
  String get failedToSave => 'Failed to save';
  @override
  String get editTransaction => 'Edit Transaction';
  @override
  String get expenseHint => 'E.g., Lunch with colleagues';
  @override
  String get expenseType => 'Expense';
  @override
  String get incomeType => 'Income';
  @override
  String get noCategories => 'No categories found';

  // ─── Budgets ──────────────────────────────────────────────────────────────────
  @override
  String get budgets => 'Budgets';
  @override
  String get budgetsSubtitle => 'Control your spending\nand stay on track 🎯';
  @override
  String get totalBudget => 'Total Budget';
  @override
  String get budgetSummary => 'Budget Summary';
  @override
  String get totalSpent => 'Total Spent';
  @override
  String get all => 'All';
  @override
  String get onTrack => 'On Track';
  @override
  String get warning => 'Warning';
  @override
  String get exceeded => 'Exceeded';
  @override
  String get budgetExceeded => 'Budget exceeded!';
  @override
  String get budget => 'Budget';
  @override
  String get noBudgetsSet => 'No Budgets Set';
  @override
  String get noBudgetsSetSubtitle =>
      'Tap + to set your first monthly spending limit.';
  @override
  String noBudgetsFilter(String filter) => 'No $filter Budgets';
  @override
  String get tryChangingFilter => 'Try changing the filter.';
  @override
  String get setBudget => 'Set Budget';
  @override
  String get limitAmount => 'Limit Amount';
  @override
  String get month => 'Month';
  @override
  String get saveBudget => 'Save Budget';
  @override
  String get budgetSaved => 'Budget saved successfully';
  @override
  String get errorSavingBudget => 'Error saving budget 😅';
  @override
  String get recurringBudget => 'Recurring Budget (Monthly)';
  @override
  String get recurring => 'Recurring';
  @override
  String get rolloverRemaining => 'Rollover Remaining';
  @override
  String get rollover => 'Rollover';
  @override
  String get remainingOf => ' remaining of ';
  @override
  String get exceededOf => ' exceeded of ';
  @override
  String periodMonths(int count, int date) => '$count months (starts on $date)';
  @override
  String periodDate(int date) => 'starts on $date';
  @override
  String dailyAllowance(String amount, int days) =>
      'You can spend $amount/day for $days more days';
  @override
  String get budgetPeriodEnded => 'Budget period has ended';
  @override
  String budgetExceededBy(String amount) => 'Budget exceeded by $amount';

  // ─── Savings ──────────────────────────────────────────────────────────────────
  @override
  String get addSavingsGoal => 'Add Savings Goal';
  @override
  String get savingsGoals => 'Savings Goals';
  @override
  String get savingsSubtitle => 'Achieve your dreams\none step at a time 🚀';
  @override
  String get totalSaved => 'Total Saved';
  @override
  String get savingSummary => 'Saving Summary';
  @override
  String get totalTarget => 'Total Target';
  @override
  String get progressTotal => 'Total Progress';
  @override
  String get numberOfSavings => 'Number of Savings';
  @override
  String get goals => 'Goals';
  @override
  String get completed => 'Completed';
  @override
  String get remaining => 'Remaining';
  @override
  String get inProgress => 'In Progress';
  @override
  String daysOverdue(int days) => '${days.abs()} days overdue';
  @override
  String get dueToday => 'Due today!';
  @override
  String daysLeft(int days) => '$days days left';
  @override
  String get completedBadge => 'Completed';
  @override
  String get unnamedGoal => 'Unnamed Goal';
  @override
  String get noSavingsGoals => 'No Savings Goals';
  @override
  String get noSavingsGoalsSubtitle =>
      'Tap the + icon to set aside money for your dreams.';
  @override
  String noGoalsFilter(String filter) => 'No $filter Goals';
  @override
  String get updateFunds => 'Update Funds';
  @override
  String get newGoal => 'New Goal';
  @override
  String get goalName => 'Goal Name';
  @override
  String get targetAmount => 'Target Amount';
  @override
  String get initialAmountSaved => 'Initial Amount Saved (Optional)';
  @override
  String get targetDateOptional => 'Target Date (Optional)';
  @override
  String get goalNameHint => 'e.g. New Car';
  @override
  String get selectDate => 'Select a date';
  @override
  String get selectYear => 'Select Year';
  @override
  String get selectMonth => 'Select Month';
  @override
  String get nameRequired => 'Name is required';
  @override
  String get saveGoal => 'Save Goal';
  @override
  String get goalSavedSuccess => 'Goal saved successfully';
  @override
  String get errorSavingGoal => 'Failed to save goal';
  @override
  String get editGoal => 'Edit Goal';
  @override
  String get deleteGoal => 'Delete Goal?';
  @override
  String get deleteGoalConfirm =>
      'Are you sure you want to delete this savings goal?';

  @override
  String gamificationLevel5(String emoji) =>
      'Target reached! Big harvest! $emoji';
  @override
  String gamificationLevel4(String emoji) =>
      'Almost there! Your tree is huge! $emoji';
  @override
  String gamificationLevel3(String emoji) =>
      'Halfway there! Keep watering your savings! $emoji';
  @override
  String gamificationLevel2(String emoji) =>
      'Leaves are growing! Keep it up! $emoji';
  @override
  String gamificationLevel1(String emoji) =>
      'Seed planted. Keep saving regularly! $emoji';
  @override
  String transferToSavings(String name) => 'Transfer to Savings: $name';
  @override
  String withdrawFromSavings(String name) => 'Withdraw from Savings: $name';

  @override
  String get addFunds => 'Add Funds';
  @override
  String get reduceFunds => 'Reduce Funds';
  @override
  String get reduce => 'Reduce';
  @override
  String get balanceCannotBeNegative => 'Balance cannot be negative';
  @override
  String get fundsAddedSuccess => 'Funds added successfully!';
  @override
  String get fundsReducedSuccess => 'Funds reduced successfully!';
  @override
  String updateGoalTitle(String name) => 'Update $name';

  // ─── Categories ───────────────────────────────────────────────────────────────
  @override
  String get manageCategories => 'Manage Categories';
  @override
  String get noCategoriesFound => 'No categories found.';
  @override
  String get deleteCategory => 'Delete Category?';
  @override
  String get deleteCategoryConfirm =>
      'Are you sure you want to delete this category?';
  @override
  String get newLabel => 'New';
  @override
  String get newCategory => 'New Category';
  @override
  String get editCategory => 'Edit Category';
  @override
  String get categoryName => 'Category Name';
  @override
  String get categoryNameHint => 'e.g., Food & Dining';
  @override
  String get createCategory => 'Create Category';
  @override
  String get saveChanges => 'Save Changes';
  @override
  String get categorySaved => 'Category saved successfully';
  @override
  String get pleaseFillAllFields => 'Please fill all fields';
  @override
  String get anErrorOccurred => 'An error occurred';
  @override
  String get customColor => 'Custom Color';
  @override
  String get hexColor => 'HEX Color';

  // ─── Wallets ──────────────────────────────────────────────────────────────────
  @override
  String get manageWallets => 'Manage Wallets';
  @override
  String get addWallet => 'Add Wallet';
  @override
  String get editWallet => 'Edit Wallet';
  @override
  String get walletName => 'Wallet Name';
  @override
  String get walletType => 'Wallet Type';
  @override
  String get initialBalance => 'Initial Balance';
  @override
  String get walletDecimalPrecision => 'Decimal Precision';
  @override
  String get walletDecimalPrecisionHint =>
      'Choose how many decimal places should be kept when balances are saved.';
  @override
  String get preview => 'Preview';
  @override
  String get isBaseCurrency => 'Is Base Currency?';
  @override
  String get walletSaved => 'Wallet saved successfully';
  @override
  String get deleteWallet => 'Delete Wallet?';
  @override
  String get deleteWalletConfirm =>
      'Are you sure you want to delete this wallet?';
  @override
  String get walletTypeCash => 'Cash';
  @override
  String get walletTypeBank => 'Bank Account';
  @override
  String get walletTypeEWallet => 'E-Wallet';
  @override
  String get walletTypeCrypto => 'Crypto';
  @override
  String get walletSearchCurrency => 'Search Currency...';
  @override
  String get walletDecimalPrecisionSheetDesc =>
      'Decimal places for rounding transaction amounts';
  @override
  String walletDecimalBadge(int n) => '$n decimal${n == 1 ? '' : 's'}';
  @override
  String get walletDecimalReset => 'Reset';
  @override
  String get walletDecimalSetAmount => 'Set amount';

  // ─── Notifications ────────────────────────────────────────────────────────────
  @override
  String get notifications => 'Notifications';
  @override
  String get markAllRead => 'Mark all read';
  @override
  String get noNotifications => 'No Notifications';
  @override
  String get noNotificationsSubtitle =>
      "You're all caught up! Check back later.";
  @override
  String get notification => 'Notification';

  // ─── AI Chat ──────────────────────────────────────────────────────────────────
  @override
  String get cuanBuddyAI => 'CuanBuddy AI';
  @override
  String get askAboutFinances => 'Ask about your finances...';

  // ─── Analytics ────────────────────────────────────────────────────────────────
  @override
  String get analytics => 'Analytics';
  @override
  String get thisMonth => 'This Month';
  @override
  String get lastMonth => 'Last Month';
  @override
  String get last3Months => 'Last 3 Months';
  @override
  String get last6Months => 'Last 6 Months';
  @override
  String get thisYear => 'This Year';
  @override
  String get topCategories => 'Top Categories';
  @override
  String get noAnalyticsData => 'No data available';

  // ─── Profile ──────────────────────────────────────────────────────────────────
  @override
  String get profile => 'Profile';
  @override
  String get accentColor => 'Accent Color';
  @override
  String get preferences => 'Preferences';
  @override
  String get account => 'Account';
  @override
  String get darkMode => 'Dark Mode';
  @override
  String get language => 'Language';
  @override
  String get currency => 'Currency';
  @override
  String get backupRestore => 'Backup & Restore';
  @override
  String get editProfile => 'Edit Profile';
  @override
  String get logOut => 'Log Out';
  @override
  String get logOutTitle => 'Log Out';
  @override
  String get logOutConfirm => 'Are you sure you want to log out?';

  // ─── Transaction Redesign ──────────────────────────────────────────────────
  @override
  String get totalCashflow => 'Total cashflow';
  @override
  @override
  String nTransactions(int count) => '$count Transactions';
  @override
  String get today => 'Today';
  @override
  String get yesterday => 'Yesterday';

  @override
  String get selectCurrency => 'Select Currency';
  @override
  String get currencyUpdated => 'Currency updated';
  @override
  String currencyUpdatedTo(String currency) => 'Currency updated to $currency';
  @override
  String get failedToUpdateCurrency => 'Failed to update currency';
  @override
  String get failedToLoadProfile => 'Failed to load profile';
  @override
  String get failed => 'Failed';
  @override
  String get selectLanguage => 'Select Language';

  // ─── Change Password & Phone ──────────────────────────────────────────────────
  @override
  String get changePassword => 'Change Password';
  @override
  String get oldPassword => 'Old Password';
  @override
  String get oldPasswordHint => 'Enter your current password';
  @override
  String get newPasswordHint => 'Enter your new password';
  @override
  String get confirmNewPasswordHint => 'Repeat your new password';
  @override
  String get oldPasswordRequired => 'Old password is required';

  @override
  String get otpSentTitle => 'OTP Sent';
  @override
  String otpSentMessage(String phone) =>
      'OTP verification code has been sent to WhatsApp number $phone';
  @override
  String get otpSuccessTitle => 'Success';
  @override
  String get otpSuccessMessage =>
      'Your phone number has been updated successfully!';
  @override
  String get otpFailedTitle => 'Failed';
  @override
  String get otpInvalidCodeTitle => 'Invalid Code';
  @override
  String get otpInvalidCodeMessage =>
      'The OTP code entered is incorrect. Use code "123456" for testing.';
  @override
  String get changePhoneNumberTitle => 'Change Phone Number';
  @override
  String get changePhoneNumberSubtitle =>
      'Enter your latest WhatsApp phone number. We will send an OTP verification code to this number.';
  @override
  String get whatsappPhoneNumber => 'WhatsApp Phone Number';
  @override
  String get phoneNumberRequired => 'Phone number is required';
  @override
  String get invalidPhoneNumberFormat => 'Invalid phone number format';
  @override
  String get sendOtpCode => 'Send OTP Code';
  @override
  String get enterOtpTitle => 'Enter 6 Digit WhatsApp OTP Code:';
  @override
  String get useDemoCode => 'Use demo code: "123456"';
  @override
  String get verifyAndSave => 'Verify & Save';
  @override
  String get changePhoneNumberLink => 'Change phone number';

  // ─── Edit Profile ─────────────────────────────────────────────────────────────
  @override
  String get chooseAvatar => 'Choose Avatar';
  @override
  String get personalInfo => 'Personal Info';
  @override
  String get currentAvatarLabel => '★ = your current avatar';
  @override
  String get phoneNumberOptional => 'Phone Number (Optional)';
  @override
  String get dateOfBirthOptional => 'Date of Birth (Optional)';
  @override
  String get phoneHint => '+62...';
  @override
  String get selectDateHint => 'Select date';
  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';
  @override
  String get failedToUpdateProfile => 'Failed to update profile';
  @override
  String get savingLabel => 'Saving...';
  @override
  String get pleaseSelectBirthdate => 'Please select a birthdate';
  @override
  String get birthdateUpdatedSuccess => 'Birthdate updated successfully';
  @override
  String failedToUpdateBirthdate(String error) =>
      'Failed to update birthdate: $error';
  @override
  String get birthdateTitle => 'Birthdate';
  @override
  String get dateOfBirth => 'Date of Birth';
  @override
  String get selectBirthdate => 'Select birthdate';
  @override
  String get birthdatePrivacyInfo =>
      'Your birthdate is private and will not be shown to other users.';
  @override
  String get saveButton => 'Save';

  @override
  String get pleaseSelectGender => 'Please select a gender';
  @override
  String get genderUpdatedSuccess => 'Gender updated successfully';
  @override
  String failedToUpdateGender(String error) =>
      'Failed to update gender: $error';
  @override
  String get selectYourGender => 'Select your gender';
  @override
  String get genderPrivacyInfo =>
      'Gender information is private and will not be shown to other users.';
  @override
  String get genderField => 'Gender';
  @override
  String get genderMale => 'Male';
  @override
  String get genderFemale => 'Female';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';
  @override
  String get nameUpdatedSuccess => 'Name updated successfully';
  @override
  String failedToUpdateName(String error) => 'Failed to update name: $error';
  @override
  String get yourFullName => 'Your Full Name';
  @override
  String get editNamePrivacyInfo =>
      'Enter your full name. This name will be displayed on your profile.';

  @override
  String get usernameCannotBeEmpty => 'Username cannot be empty';
  @override
  String get usernameInvalidFormat =>
      'Username can only contain letters, numbers, and underscores';
  @override
  String get usernameUpdatedSuccess => 'Username updated successfully';
  @override
  String failedToUpdateUsername(String error) =>
      'Failed to update username: $error';
  @override
  String get usernameField => 'Username';
  @override
  String get yourUsername => 'Your Username';
  @override
  String get editUsernamePrivacyInfo =>
      'Username can only contain letters (a-z, A-Z), numbers (0-9), and underscores (_).';

  @override
  String get bioUpdatedSuccess => 'Bio updated successfully';
  @override
  String failedToUpdateBio(String error) => 'Failed to update bio: $error';
  @override
  String get aboutTitle => 'About';
  @override
  String get aboutYou => 'About You';
  @override
  String get editBioPrivacyInfo =>
      'Write a status or a short description about yourself so other users can see it.';

  @override
  String get linkUpdatedSuccess => 'Instagram link updated successfully';
  @override
  String failedToUpdateLink(String error) => 'Failed to update link: $error';
  @override
  String get linkTitle => 'Link';
  @override
  String get yourInstagramLink => 'Your Instagram Link';
  @override
  String get editLinkPrivacyInfo =>
      'Link your Instagram or social media account so friends can connect directly from your CuanBuddy profile.';

  @override
  String get profilePhotoUpdatedSuccess =>
      'Profile photo updated successfully!';
  @override
  String failedToUpdateAvatar(String error) =>
      'Failed to update avatar: $error';
  @override
  String get profilePhoto => 'Profile Photo';
  @override
  String get uploadNewPhoto => 'Upload New Photo';
  @override
  String get profileTitle => 'Profile';
  @override
  String get notSet => 'Not set';
  @override
  String get editPhoto => 'Edit Photo';
  @override
  String get bioField => 'Bio';

  @override
  String get accountMenu => 'Account';
  @override
  String get changePasswordDesc => 'Change your account password';
  @override
  String get changePhoneNumberDesc => 'Update your WhatsApp phone number';

  @override
  List<String> get months => [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
  @override
  List<String> get shortMonths => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
  @override
  List<String> get shortDays =>
      ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  @override
  String get accountMenuDesc => 'Security notification, change number';
  @override
  String get appearanceMenu => 'Appearance';
  @override
  String get appearanceMenuDesc => 'Theme, app language';
  @override
  String get manageCategoriesDesc => 'Manage transaction categories';
  @override
  String get widgetsDesc => 'Configure home screen widgets';
  @override
  String get backupRestoreDesc => 'Backup and restore your data';
  @override
  String get aboutDesc => 'Information about the app';
  @override
  String get feedbackDesc => 'Send suggestions or report bugs';
  @override
  String get logOutDesc => 'Log out of your current account';
  @override
  String get aboutAppDesc =>
      'CuanBuddy is your smart financial assistant to track transactions, manage budgets, and monitor financial health with AI support.';
  @override
  String get connectWithUs => 'Connect with us:';

  // ─── Backup & Restore ─────────────────────────────────────────────────────────
  @override
  String get backupSettings => 'Backup Settings';
  @override
  String get step2of2 => 'Step 2/2';
  @override
  String get enableAutoBackup =>
      'Enable automatic backup to keep your data safe 🔒';
  @override
  String get autoBackup => 'Auto Backup';
  @override
  String get autoBackupActive => 'Automatic backup is active';
  @override
  String get backupYourDataAuto => 'Back up your data automatically';
  @override
  String get backupFrequency => 'Backup Frequency';
  @override
  String get selectDataToBackup => 'Select Data to Backup/Restore';
  @override
  String get manualAction => 'Manual Action';
  @override
  String get everyDay => 'Every Day';
  @override
  String get dailyBackupDesc => 'Daily automatic backup';
  @override
  String get everyWeek => 'Every Week';
  @override
  String get weeklyBackupDesc => 'Weekly automatic backup';
  @override
  String get everyMonth => 'Every Month';
  @override
  String get monthlyBackupDesc => 'Monthly automatic backup';
  @override
  String get transactionsLabel => 'Transactions';
  @override
  String get budgetsLabel => 'Budgets';
  @override
  String get savingsGoalsLabel => 'Savings';
  @override
  String get categoriesLabel => 'Categories';
  @override
  String get backupNow => 'Backup';
  @override
  String get restore => 'Restore';
  @override
  String get finishAndStart => 'Finish & Start 🚀';
  @override
  String get skip => 'Skip';
  @override
  String get backupSettingsSaved => 'Backup settings saved ✅';
  @override
  String get failedToSaveSettings => 'Failed to save settings';
  @override
  String get restoreData => 'Restore Data';
  @override
  String get restoreInstructions =>
      'To restore your data, please upload a valid .zip backup file. You can download the empty .zip template below to see the required format.';
  @override
  String get downloadTemplates => 'Download Templates';
  @override
  String get uploadAndRestore => 'Upload & Restore';
  @override
  String get backupStarted => 'Backup started...';
  @override
  String get failedToLoadBackupSettings => 'Failed to load backup settings';

  // ─── Profile Setup ────────────────────────────────────────────────────────────
  @override
  String get step1of2 => 'Step 1/2';
  @override
  String get completeYourProfile => 'Complete Your Profile';
  @override
  String get profileSetupSubtitle =>
      'Let us personalize your CuanBuddy experience ✨';
  @override
  String get phoneNumberField => 'Phone Number (Optional)';
  @override
  String get continueButton => 'Continue';
  @override
  String get nameTooShortSetup => 'Name must be at least 2 characters';
  @override
  String get failedToSaveProfile => 'Failed to save profile';

  // ─── Common ───────────────────────────────────────────────────────────────────
  @override
  String get retry => 'Retry';
  @override
  String get close => 'Close';
  @override
  String get ok => 'OK';
  @override
  String get confirm => 'Confirm';
  @override
  String get loading => 'Loading...';
  @override
  String get failedGeneric => 'Something went wrong. Please try again.';
  @override
  String spent(String amount) => 'Spent: $amount';
  @override
  String of_(String amount) => 'of $amount';

  // ─── Onboarding ──────────────────────────────────────────────────────────────
  @override
  String get onboardingTitle1 => 'Track Your Expenses';
  @override
  String get onboardingDesc1 =>
      'Easily record and categorize your income and expenses to visualize where your money goes.';
  @override
  String get onboardingTitle2 => 'Smart Budgeting';
  @override
  String get onboardingDesc2 =>
      'Set monthly limits for categories and receive warning alerts when you approach them.';
  @override
  String get onboardingTitle3 => 'AI Financial Advisor';
  @override
  String get onboardingDesc3 =>
      'Chat with your personal AI assistant to receive recommendations and insights about your health.';
  @override
  String get getStarted => 'Get Started';
  @override
  String get next => 'Next';

  // ─── AI Voice ───────────────────────────────────────────────────────────────
  @override
  String get aiVoiceTitle => 'Transaction Confirmation';
  @override
  String get aiVoiceTapToStart => 'Tap the microphone to start speaking';
  @override
  String get aiVoiceTapToStop => 'Tap the microphone when you\'re done';
  @override
  String get aiVoiceListening => 'Listening...';
  @override
  String get aiVoiceAnalyzing => 'AI is analyzing...';
  @override
  String get aiVoiceExtracting => 'Extracting amount and category';
  @override
  String get aiVoiceFailed => 'Failed to process voice.';
  @override
  String get aiVoiceErrorUnclear => 'Voice is unclear or failed to process.';
  @override
  String get aiVoiceTitleField => 'Title';
  @override
  String get aiVoiceAmountField => 'Amount';
  @override
  String get aiVoiceTypeField => 'Type';
  @override
  String get aiVoiceCategoryField => 'Category';
  @override
  String get aiVoiceIncome => 'Income';
  @override
  String get aiVoiceExpense => 'Expense';
  @override
  String get aiVoiceSave => 'Save Transaction';
  @override
  String get aiVoiceBack => 'Record Again';
  @override
  String get aiVoiceSuccess => 'Transaction saved via AI Voice!';

  // ─── Extra Fields ─────────────────────────────────────────────────────────────
  @override
  String get usernameHint => 'Enter your username';
  @override
  String get genderOther => 'Other';
  @override
  String get bioHint => 'Tell us about yourself...';
  @override
  String get noBioFallback => 'No bio yet.';
  @override
  String get allocateToSavings => 'Allocate to Savings';
  @override
  String get selectSavingsGoal => 'Select Savings Goal';
  @override
  String get allocate => 'Allocate';
  @override
  String get allocationSuccessful => 'Allocation successful';
  @override
  String get pleaseSelectSavingsGoal => 'Please select a savings goal';
  @override
  String get changePasswordInfo =>
      'Please enter your current password to create a new one. Make sure your new password is at least 8 characters long.';

  // ─── Export & Import ──────────────────────────────────────────────────────────
  @override
  String get exportData => 'Export Data';
  @override
  String get importData => 'Import Data';

  // ─── Saving Detail ──────────────────────────────────────────────────────────
  @override
  String get transactionHistory => 'Transaction History';
  @override
  String get perDay => 'Per Day';
  @override
  String get perDayShort => '/day';

  // ─── Notifications ────────────────────────────────────────────────────────
  @override
  String get newTransactionRecorded => 'New Transaction Recorded';
  @override
  String transactionRecordedSuccess(String typeStr, String amountStr) =>
      'You have successfully recorded a $typeStr of $amountStr.';
  @override
  String get newBudgetCreated => 'New Budget Created';
  @override
  String budgetSetTo(String monthYear, String limitStr) =>
      'Budget for $monthYear has been set to $limitStr.';
  @override
  String get budgetExceededNotification => 'Budget Exceeded';
  @override
  String budgetExceededWarning(String monthYear, String categoryName,
          String limitStr, String spentStr) =>
      'You have exceeded your $monthYear budget for $categoryName! Limit: $limitStr, Spent: $spentStr';
  @override
  String get budgetWarningNotification => 'Budget Warning';
  @override
  String budgetWarningDetail(
          int ratio, String monthYear, String categoryName) =>
      'Watch out! You have spent $ratio% of your $monthYear budget for $categoryName.';
  @override
  String get budgetPredictionWarning => 'Budget Prediction Warning';
  @override
  String budgetPredictionWarningDetail(
          String monthYear, String categoryName, String predictedStr) =>
      'Based on your spending, you are projected to exceed your $monthYear budget for $categoryName. Estimated spend: $predictedStr';
  @override
  String get incomeNotification => 'income';
  @override
  String get expenseNotification => 'expense';

  // ─── Exceptions & Network Errors ──────────────────────────────────────────
  @override
  String get errInvalidData => 'Invalid data. Please check again 😊';
  @override
  String get errAuthFailed => 'Oops, incorrect email or password 😅';
  @override
  String get errUnverifiedAccount =>
      'Account not verified. Check your email 📧';
  @override
  String get errNoAccess => 'You do not have access here 🚫';
  @override
  String get errDataNotFound => 'Data not found 🔍';
  @override
  String get errDataExists => 'Data already exists ⚠️';
  @override
  String get errInvalidFormat => 'Incorrect data format. Please check again 😊';
  @override
  String get errTooManyRequests => 'Too many attempts. Please wait a moment ⏳';
  @override
  String get errServerBusy =>
      'Oops, the server is busy. Please try again later 🙏';
  @override
  String get errGeneric => 'An error occurred. Please try again later 😅';
  @override
  String get errNoInternet =>
      'Internet connection issue. Please check your connection 📶';
  @override
  String get errTimeout => 'Slow connection. Please try again later ⏳';

  @override
  String get theme => 'Theme';
  @override
  String get system => 'System';
  @override
  String get light => 'Light';
  @override
  String get dark => 'Dark';
  @override
  String get about => 'About';
  @override
  String get feedback => 'Feedback';
  @override
  String get feedbackMessageHint =>
      'Write your feedback or suggestions here...';
  @override
  String get feedbackSentSuccess =>
      'Feedback sent successfully! Thank you for your support.';
  @override
  String get feedbackEmptyError => 'Feedback message cannot be empty';
  @override
  String get feedbackInstruction =>
      'Help us improve CuanBuddy by sending your suggestions or bug reports.';
  @override
  String get sendFeedback => 'Send Feedback';

  // Budget Screen Additions
  @override
  String get startMonth => 'Start Month';
  @override
  String get startDate => 'Start Date';
  @override
  String get periodStartsOnWhatDate =>
      'On what date does the period start each month';
  @override
  String selectedDateInfo(int day) => 'Selected date: $day';
  @override
  String get periodCountMonths => 'Period Count (Months)';
  @override
  String get howManyMonthsBudgetValid =>
      'How many months is this budget valid for';
  @override
  String get monthLabel => 'months';
  @override
  String get categoryBudget => 'Category Budget';
  @override
  String get endMonth => 'End';
  @override
  String get budgetName => 'Budget Name';
  @override
  String get budgetNameHint => 'e.g. Monthly Groceries';
  @override
  String get budgetTypeStandalone => 'Standalone Budget';
  @override
  String get budgetTypeAll => 'All Categories';
  @override
  String get budgetTypeSpecific => 'Specific Categories';
  @override
  String get selectCategories => 'Select Categories';
  @override
  String get selectAll => 'Select All';
  @override
  String get budgetIcon => 'Budget Icon';
  @override
  String get budgetColor => 'Budget Color';
  @override
  String budgetActivePeriod(String startMonth, String endMonth) =>
      'Budget is valid from $startMonth to $endMonth.';

  // ─── Savings Form (new fields) ─────────────────────────────────────────────
  @override
  String get selectWallet => 'Select Wallet';
  @override
  String get failedToLoadWallet => 'Failed to load wallets';
  @override
  String get noWalletsFound => 'No wallets found. Please create one.';
  @override
  String get pinGoal => 'Pin Goal';
  @override
  String get purchaseLinkOptional => 'Purchase Link (Optional)';
  @override
  String get purchaseLinkLabel => 'Purchase URL';
  @override
  String get purchaseLinkHint => 'https://shopee.co.id/... or Tokopedia';
}
