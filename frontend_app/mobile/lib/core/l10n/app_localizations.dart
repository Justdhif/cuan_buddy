import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ─── Abstract Base ─────────────────────────────────────────────────────────────
abstract class AppLocalizations {
  const AppLocalizations();

  /// Resolve the current [AppLocalizations] from the nearest [AppLocalizationsScope].
  static AppLocalizations of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLocalizationsScope>();
    return scope?.localizations ?? const AppLocalizationsEn();
  }

  /// Factory — returns the right subclass based on language code.
  static AppLocalizations forLocale(String languageCode) {
    return languageCode == 'id'
        ? const AppLocalizationsId()
        : const AppLocalizationsEn();
  }

  // ─── Language Meta ────────────────────────────────────────────────────────────
  String get languageCode;
  String get languageName;
  String get home;

  // ─── Auth — Login ─────────────────────────────────────────────────────────────
  String get welcomeBack;
  String get loginSubtitle;
  String get email;
  String get password;
  String get forgotPassword;
  String get loginButton;
  String get emailHint;
  String get passwordHint;
  String get emailRequired;
  String get invalidEmail;
  String get passwordRequired;
  String get noAccount;
  String get signUpNow;
  String get loginFailed;

  // ─── Auth — Register ──────────────────────────────────────────────────────────
  String get createAccount;
  String get registerSubtitle;
  String get fullName;
  String get confirmPassword;
  String get fullNameHint;
  String get passwordMinHint;
  String get confirmPasswordHint;
  String get fullNameRequired;
  String get nameTooShort;
  String get confirmPasswordRequired;
  String get passwordsDoNotMatch;
  String get passwordMin8;
  String get weak;
  String get fair;
  String get strong;
  String get veryStrong;
  String get signUp;
  String get alreadyHaveAccount;
  String get logInLink;
  String get error;

  // ─── Auth — Forgot Password ───────────────────────────────────────────────────
  String get forgotPasswordTitle;
  String get enterOtpSentToEmail;
  String get enterEmailForOtp;
  String get passwordChangedSuccess;
  String get canNowLoginNewPassword;
  String get otpCode;
  String get newPassword;
  String get emailHintForgot;
  String get otpHint;
  String get otpRequired;
  String get sendOtp;
  String get resetPassword;
  String get resendOtp;
  String get logInNow;
  String get pleaseEnterEmailFirst;
  String get otpSentToEmail;
  String get info;

  // ─── Auth — Email Verification ────────────────────────────────────────────────
  String get verifyEmail;
  String get waitingForActivation;
  String get verificationRequired;
  String verificationLinkSentTo(String email);
  String get verificationLinkSent;
  String get checkYourEmail;
  String weHaveSentVerificationTo(String email);
  String get accountVerified;
  String get redirectingToLogin;
  String get didNotReceiveEmail;
  String get sendVerificationEmail;
  String get backToLogin;
  String get checkUserStatus;
  String get goToLogin;
  String get goToLoginNow;
  String get accountVerifiedRedirecting;
  String get accountNotYetVerified;
  String get success;

  // ─── Splash ───────────────────────────────────────────────────────────────────
  String get splashTagline;

  // ─── Dashboard ────────────────────────────────────────────────────────────────
  String get hello;
  String get aiAdvisor;
  String get totalBalance;
  String get income;
  String get expense;
  String get recentActivities;
  String get seeAll;
  String get spendingByCategory;
  String get budgetDetails;
  // ─── AI Voice ───────────────────────────────────────────────────────────────
  String get aiVoiceTitle;
  String get aiVoiceTapToStart;
  String get aiVoiceTapToStop;
  String get aiVoiceListening;
  String get aiVoiceAnalyzing;
  String get aiVoiceExtracting;
  String get aiVoiceFailed;
  String get aiVoiceErrorUnclear;
  String get aiVoiceTitleField;
  String get aiVoiceAmountField;
  String get aiVoiceTypeField;
  String get aiVoiceCategoryField;
  String get aiVoiceIncome;
  String get aiVoiceExpense;
  String get aiVoiceSave;
  String get aiVoiceBack;
  String get aiVoiceSuccess;

  String get monthlyTrend;
  String get transaction;
  String get other;
  String get you;
  String get shared;

  String get noTransactionsYet;
  String get startRecordingTransactions;
  String get failedToLoadTransactions;
  String get noSpendingData;
  String get addExpensesToSeeBreakdown;
  String get noTrendData;
  String get startRecordingToSeeTrend;
  String get withinBudget;
  String get approachingBudget;
  String get exceededBudget;
  String get tryAgain;

  // ─── Transactions ─────────────────────────────────────────────────────────────
  String get transactions;
  String get addTransaction;
  String get allTypes;
  String get allCategories;
  String get noTransactionsYetTitle;
  String get noTransactionsYetSubtitle;
  String get failedToLoadTransactionsError;
  String get failedToLoadCategories;
  String get edit;
  String get delete;
  String get deleteTransaction;
  String get deleteTransactionConfirm;
  String get deleteBudget;
  String get deleteBudgetConfirm;
  String get cancel;
  String get failedToDelete;
  String get saving;
  String get saveTransaction;
  String get transactionTitle;
  String get titleRequired;
  String get transactionTitleHint;
  String get amount;
  String get category;
  String get noteOptional;
  String get date;
  String get amountRequired;
  String get invalidAmount;
  String get pleaseSelectCategory;
  String get transactionSaved;
  String get failedToSave;
  String get editTransaction;
  String get expenseHint;
  String get expenseType;
  String get incomeType;
  String get noCategories;

  // ─── Budgets ──────────────────────────────────────────────────────────────────
  String get budgets;
  String get totalBudget;
  String get all;
  String get onTrack;
  String get warning;
  String get exceeded;
  String get budgetExceeded;
  String get budget;
  String get noBudgetsSet;
  String get noBudgetsSetSubtitle;
  String noBudgetsFilter(String filter);
  String get tryChangingFilter;
  String get setBudget;
  String get limitAmount;
  String get month;
  String get saveBudget;
  String get budgetSaved;
  String get errorSavingBudget;
  String get recurringBudget;
  String get recurring;
  String get rolloverRemaining;
  String get rollover;

  // ─── Savings ──────────────────────────────────────────────────────────────────
  String get savingsGoals;
  String get totalSaved;
  String get goals;
  String get completed;
  String get remaining;
  String get inProgress;
  String daysOverdue(int days);
  String get dueToday;
  String daysLeft(int days);
  String get completedBadge;
  String get unnamedGoal;
  String get noSavingsGoals;
  String get noSavingsGoalsSubtitle;
  String noGoalsFilter(String filter);
  String get updateFunds;
  String get newGoal;
  String get goalName;
  String get targetAmount;
  String get initialAmountSaved;
  String get targetDateOptional;
  String get goalNameHint;
  String get selectDate;
  String get nameRequired;
  String get saveGoal;
  String get goalSavedSuccess;
  String get errorSavingGoal;
  
  String get editGoal;
  String get deleteGoal;
  String get deleteGoalConfirm;
  
  String gamificationLevel5(String emoji);
  String gamificationLevel4(String emoji);
  String gamificationLevel3(String emoji);
  String gamificationLevel2(String emoji);
  String gamificationLevel1(String emoji);
  String transferToSavings(String name);
  String withdrawFromSavings(String name);
  
  String get addFunds;
  String get reduceFunds;
  String get reduce;
  String get balanceCannotBeNegative;
  String get fundsAddedSuccess;
  String get fundsReducedSuccess;
  String updateGoalTitle(String name);

  // ─── Categories ───────────────────────────────────────────────────────────────
  String get manageCategories;
  String get noCategoriesFound;
  String get deleteCategory;
  String get deleteCategoryConfirm;
  String get newCategory;
  String get editCategory;
  String get categoryName;
  String get categoryNameHint;
  String get createCategory;
  String get saveChanges;
  String get categorySaved;
  String get pleaseFillAllFields;
  String get anErrorOccurred;

  // ─── Notifications ────────────────────────────────────────────────────────────
  String get notifications;
  String get markAllRead;
  String get noNotifications;
  String get noNotificationsSubtitle;
  String get notification;

  // ─── AI Chat ──────────────────────────────────────────────────────────────────
  String get cuanBuddyAI;
  String get askAboutFinances;

  // ─── Analytics ────────────────────────────────────────────────────────────────
  String get analytics;
  String get thisMonth;
  String get lastMonth;
  String get last3Months;
  String get last6Months;
  String get thisYear;
  String get topCategories;
  String get noAnalyticsData;

  // ─── Profile ──────────────────────────────────────────────────────────────────
  String get profile;
  String get preferences;
  String get account;
  String get darkMode;
  String get language;
  String get currency;
  String get backupRestore;
  String get editProfile;
  String get logOut;
  String get logOutTitle;
  String get logOutConfirm;
  String get selectCurrency;
  String get currencyUpdated;
  String currencyUpdatedTo(String currency);
  String get failedToUpdateCurrency;
  String get failedToLoadProfile;
  String get failed;
  String get selectLanguage;

  // ─── Change Password ──────────────────────────────────────────────────────────
  String get changePassword;
  String get oldPassword;
  String get oldPasswordHint;
  String get newPasswordHint;
  String get confirmNewPasswordHint;
  String get oldPasswordRequired;

  // ─── Edit Profile ─────────────────────────────────────────────────────────────
  String get chooseAvatar;
  String get personalInfo;
  String get currentAvatarLabel;
  String get phoneNumberOptional;
  String get dateOfBirthOptional;
  String get phoneHint;
  String get selectDateHint;
  String get profileUpdatedSuccess;
  String get failedToUpdateProfile;
  String get savingLabel;

  // ─── Backup & Restore ─────────────────────────────────────────────────────────
  String get backupSettings;
  String get step2of2;
  String get enableAutoBackup;
  String get autoBackup;
  String get autoBackupActive;
  String get backupYourDataAuto;
  String get backupFrequency;
  String get selectDataToBackup;
  String get manualAction;
  String get everyDay;
  String get dailyBackupDesc;
  String get everyWeek;
  String get weeklyBackupDesc;
  String get everyMonth;
  String get monthlyBackupDesc;
  String get transactionsLabel;
  String get budgetsLabel;
  String get savingsGoalsLabel;
  String get categoriesLabel;
  String get backupNow;
  String get restore;
  String get finishAndStart;
  String get skip;
  String get backupSettingsSaved;
  String get failedToSaveSettings;
  String get restoreData;
  String get restoreInstructions;
  String get downloadTemplates;
  String get uploadAndRestore;
  String get backupStarted;
  String get failedToLoadBackupSettings;

  // ─── Profile Setup ────────────────────────────────────────────────────────────
  String get step1of2;
  String get completeYourProfile;
  String get profileSetupSubtitle;
  String get phoneNumberField;
  String get continueButton;
  String get nameTooShortSetup;
  String get failedToSaveProfile;

  // ─── Common ───────────────────────────────────────────────────────────────────
  String get retry;
  String get close;
  String get ok;
  String get confirm;
  String get loading;
  String get failedGeneric;
  String spent(String amount);
  String of_(String amount);

  // ─── Transaction Redesign ──────────────────────────────────────────────────
  String get totalCashflow;
  String nTransactions(int count);
  String get today;
  String get yesterday;

  // ─── Onboarding ──────────────────────────────────────────────────────────────
  String get onboardingTitle1;
  String get onboardingDesc1;
  String get onboardingTitle2;
  String get onboardingDesc2;
  String get onboardingTitle3;
  String get onboardingDesc3;
  String get getStarted;
  String get next;

  // ─── Extra Fields ─────────────────────────────────────────────────────────────
  String get usernameField;
  String get usernameHint;
  String get genderField;
  String get genderMale;
  String get genderFemale;
  String get genderOther;
  String get bioField;
  String get bioHint;
  String get noBioFallback;
  String get allocateToSavings;
  String get selectSavingsGoal;
  String get allocate;
  String get allocationSuccessful;
  String get pleaseSelectSavingsGoal;
  String get changePasswordInfo;

  // ─── Export & Import ──────────────────────────────────────────────────────────
  String get exportData;
  String get importData;
}

// ─── InheritedWidget Scope ────────────────────────────────────────────────────
class AppLocalizationsScope extends InheritedWidget {
  const AppLocalizationsScope({
    super.key,
    required this.localizations,
    required super.child,
  });

  final AppLocalizations localizations;

  static AppLocalizations of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppLocalizationsScope>()
            ?.localizations ??
        const AppLocalizationsEn();
  }

  @override
  bool updateShouldNotify(AppLocalizationsScope oldWidget) {
    return localizations.languageCode != oldWidget.localizations.languageCode;
  }
}
