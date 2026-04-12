import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('am'),
    Locale('om'),
  ];

  static const frameworkSupportedLocales = <Locale>[Locale('en'), Locale('am')];

  static Locale resolveAppLocale(Locale locale) {
    return switch (locale.languageCode) {
      'am' => const Locale('am'),
      'om' => const Locale('om'),
      _ => const Locale('en'),
    };
  }

  static Locale resolveFrameworkLocale(Locale locale) {
    return switch (locale.languageCode) {
      'am' => const Locale('am'),
      _ => const Locale('en'),
    };
  }

  static const _values = <String, Map<String, String>>{
    'en': {
      'appTitle': 'Maya City CBHI Admin',
      'appWindowTitle': 'Maya City CBHI - Admin',
      'portalTitle': 'Maya City CBHI\nAdmin Portal',
      'portalSubtitle':
          'For CBHI Officers and System Administrators.\nManage claims, enrollments, and system settings.',
      'signIn': 'Sign In',
      'adminAccessOnly': 'CBHI Officer and Admin access only',
      'identifierRequired': 'Email/phone and password are required.',
      'emailOrPhone': 'Email or phone number',
      'password': 'Password',
      'demoMode': 'Demo mode active. Use any admin account credentials.',
      'language': 'Language',
      'languageEnglish': 'English',
      'languageAmharic': 'Amharic',
      'languageOromo': 'Afaan Oromo',
      'navOverview': 'Overview',
      'navClaims': 'Claims',
      'navIndigent': 'Indigent',
      'navReports': 'Reports',
      'navSettings': 'Settings',
      'signOut': 'Sign Out',
      'connected': 'Connected',
      'claimsReviewApproval': 'Claims Review and Approval',
      'householdEnrollmentManagement': 'Household Enrollment Management',
      'reportsAnalytics': 'Reports and Analytics',
      'systemConfiguration': 'System Configuration',
      'csvDataExport': 'CSV Data Export',
      'totalHouseholds': 'Total Households',
      'accreditedFacilities': 'Accredited Facilities',
      'claimsSubmitted': 'Claims Submitted',
      'pendingIndigent': 'Pending Indigent',
      'claimsBreakdown': 'Claims Breakdown',
      'financialSummary': 'Financial Summary',
      'submitted': 'Submitted',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'paid': 'Paid',
      'totalClaimed': 'Total Claimed',
      'totalApproved': 'Total Approved',
      'totalTransactions': 'Total Transactions',
      'totalCollected': 'Total Collected',
      'refresh': 'Refresh',
      'noClaimsFound': 'No claims found',
      'claimNumber': 'Claim #',
      'beneficiary': 'Beneficiary',
      'facility': 'Facility',
      'claimedAmount': 'Claimed (ETB)',
      'approvedAmount': 'Approved (ETB)',
      'status': 'Status',
      'serviceDate': 'Service Date',
      'actions': 'Actions',
      'cancel': 'Cancel',
      'decisionNote': 'Decision Note',
      'setClaimTo': 'Set claim to {status}',
      'claimUpdatedTo': 'Claim updated to {status}',
      'notAvailable': 'N/A',
      'pendingIndigentApplications': 'Pending Indigent Applications',
      'pendingCount': '{count} pending',
      'noPendingApplications': 'No pending applications',
      'allIndigentProcessed': 'All indigent applications have been processed.',
      'userId': 'User ID',
      'income': 'Income (ETB)',
      'employment': 'Employment',
      'familySize': 'Family Size',
      'score': 'Score',
      'approve': 'Approve',
      'reject': 'Reject',
      'reviewIndigentTitle': '{action} Indigent Application',
      'overrideReason': 'Override reason (optional)',
      'scoreValue': 'Score: {score} / 100',
      'employmentValue': 'Employment: {employment}',
      'familySizeValue': 'Family size: {size}',
      'userIdValue': 'User ID: {userId}',
      'dataExport': 'Data Export',
      'exportSubtitle': 'Export CBHI data as CSV for reporting to FMOH/EHIA.',
      'saveExport': 'Save {type} export',
      'exportedTo': 'Exported to {path}',
      'households': 'Households',
      'claims': 'Claims',
      'payments': 'Payments',
      'indigentApplications': 'Indigent Applications',
      'householdsExportDescription':
          'All registered households with coverage status and location data.',
      'claimsExportDescription':
          'All submitted claims with status, amounts, and facility details.',
      'paymentsExportDescription':
          'All premium payment transactions with method and status.',
      'indigentExportDescription':
          'All indigent applications with scores and decisions.',
      'exportCsv': 'Export CSV',
      'manageSystemSettings':
          'Manage CBHI system settings. Changes take effect immediately.',
      'setting': 'Setting',
      'label': 'Label',
      'description': 'Description',
      'valueJson': 'Value (JSON)',
      'save': 'Save',
      'settingUpdated': 'Setting updated',
      'edit': 'Edit',
      'statusAll': 'All',
      'statusSubmitted': 'Submitted',
      'statusUnderReview': 'Under Review',
      'statusApproved': 'Approved',
      'statusRejected': 'Rejected',
      'statusPaid': 'Paid',
      'statusPending': 'Pending',
      'statusActive': 'Active',
      'statusSuccess': 'Success',
      'statusFailed': 'Failed',
      'statusExpired': 'Expired',
    },
    'am': {
      'appTitle': 'የማያ ከተማ CBHI አስተዳደር',
      'appWindowTitle': 'የማያ ከተማ CBHI - አስተዳደር',
      'portalTitle': 'የማያ ከተማ CBHI\nየአስተዳደር ፖርታል',
      'portalSubtitle':
          'ለCBHI ባለሙያዎች እና ለስርዓት አስተዳዳሪዎች።\nክሌሞችን፣ ምዝገባዎችን እና የስርዓት ቅንብሮችን ያስተዳድሩ።',
      'signIn': 'ግባ',
      'adminAccessOnly': 'ለCBHI ባለሙያዎች እና አስተዳዳሪዎች ብቻ',
      'identifierRequired': 'ኢሜይል/ስልክ እና የይለፍ ቃል ያስፈልጋሉ።',
      'emailOrPhone': 'ኢሜይል ወይም ስልክ ቁጥር',
      'password': 'የይለፍ ቃል',
      'demoMode': 'የሙከራ ሁኔታ ነቅቷል። ማንኛውንም የአስተዳዳሪ መለያ ይጠቀሙ።',
      'language': 'ቋንቋ',
      'languageEnglish': 'English',
      'languageAmharic': 'አማርኛ',
      'languageOromo': 'Afaan Oromoo',
      'navOverview': 'አጠቃላይ እይታ',
      'navClaims': 'ክሌሞች',
      'navIndigent': 'ድጋፍ የሚያስፈልጋቸው',
      'navReports': 'ሪፖርቶች',
      'navSettings': 'ቅንብሮች',
      'signOut': 'ውጣ',
      'connected': 'ተገናኝቷል',
      'claimsReviewApproval': 'የክሌም ግምገማ እና ይሁንታ',
      'householdEnrollmentManagement': 'የቤተሰብ ምዝገባ አስተዳደር',
      'reportsAnalytics': 'ሪፖርቶች እና ትንታኔ',
      'systemConfiguration': 'የስርዓት ቅንብር',
      'csvDataExport': 'የCSV ውሂብ መላክ',
      'totalHouseholds': 'ጠቅላላ ቤተሰቦች',
      'accreditedFacilities': 'የተፈቀዱ ተቋማት',
      'claimsSubmitted': 'የቀረቡ ክሌሞች',
      'pendingIndigent': 'በመጠባበቅ ላይ ያሉ',
      'claimsBreakdown': 'የክሌም ክፍፍል',
      'financialSummary': 'የፋይናንስ አጠቃላይ',
      'submitted': 'ቀርቧል',
      'approved': 'ጸድቋል',
      'rejected': 'ተቀባይነት አላገኘም',
      'paid': 'ተከፍሏል',
      'totalClaimed': 'ጠቅላላ የተጠየቀ',
      'totalApproved': 'ጠቅላላ የጸደቀ',
      'totalTransactions': 'ጠቅላላ ግብይቶች',
      'totalCollected': 'ጠቅላላ የተሰበሰበ',
      'refresh': 'አድስ',
      'noClaimsFound': 'ምንም ክሌም አልተገኘም',
      'claimNumber': 'ክሌም #',
      'beneficiary': 'ተጠቃሚ',
      'facility': 'ተቋም',
      'claimedAmount': 'የተጠየቀ (ብር)',
      'approvedAmount': 'የጸደቀ (ብር)',
      'status': 'ሁኔታ',
      'serviceDate': 'የአገልግሎት ቀን',
      'actions': 'እርምጃዎች',
      'cancel': 'ሰርዝ',
      'decisionNote': 'የውሳኔ ማስታወሻ',
      'setClaimTo': 'ክሌምን ወደ {status} ቀይር',
      'claimUpdatedTo': 'ክሌም ወደ {status} ተዘምኗል',
      'notAvailable': 'የለም',
      'pendingIndigentApplications': 'በመጠባበቅ ላይ ያሉ የድጋፍ ማመልከቻዎች',
      'pendingCount': '{count} በመጠባበቅ ላይ',
      'noPendingApplications': 'በመጠባበቅ ላይ ያለ ማመልከቻ የለም',
      'allIndigentProcessed': 'ሁሉም ማመልከቻዎች ተከናውነዋል።',
      'userId': 'የተጠቃሚ መለያ',
      'income': 'ገቢ (ብር)',
      'employment': 'የስራ ሁኔታ',
      'familySize': 'የቤተሰብ ብዛት',
      'score': 'ነጥብ',
      'approve': 'ፍቀድ',
      'reject': 'አልተፈቀደም',
      'reviewIndigentTitle': 'የድጋፍ ማመልከቻን {action}',
      'overrideReason': 'የመቀየሪያ ምክንያት (አማራጭ)',
      'scoreValue': 'ነጥብ: {score} / 100',
      'employmentValue': 'የስራ ሁኔታ: {employment}',
      'familySizeValue': 'የቤተሰብ ብዛት: {size}',
      'userIdValue': 'የተጠቃሚ መለያ: {userId}',
      'dataExport': 'የውሂብ መላክ',
      'exportSubtitle': 'የCBHI ውሂብን ለFMOH/EHIA ሪፖርት በCSV ይላኩ።',
      'saveExport': 'የ{type} መላኪያ አስቀምጥ',
      'exportedTo': 'ወደ {path} ተልኳል',
      'households': 'ቤተሰቦች',
      'claims': 'ክሌሞች',
      'payments': 'ክፍያዎች',
      'indigentApplications': 'የድጋፍ ማመልከቻዎች',
      'householdsExportDescription':
          'ሁሉም የተመዘገቡ ቤተሰቦች ከሽፋን ሁኔታ እና ከአድራሻ መረጃ ጋር።',
      'claimsExportDescription': 'ሁሉም የቀረቡ ክሌሞች ከሁኔታ፣ ከመጠን እና ከተቋም ዝርዝር ጋር።',
      'paymentsExportDescription': 'ሁሉም የፕሪሚየም ክፍያዎች ከዘዴ እና ከሁኔታ ጋር።',
      'indigentExportDescription': 'ሁሉም የድጋፍ ማመልከቻዎች ከነጥብ እና ከውሳኔ ጋር።',
      'exportCsv': 'CSV ላክ',
      'manageSystemSettings': 'የCBHI ስርዓት ቅንብሮችን ያስተዳድሩ። ለውጦች ወዲያውኑ ይተገበራሉ።',
      'setting': 'ቅንብር',
      'label': 'መለያ',
      'description': 'መግለጫ',
      'valueJson': 'እሴት (JSON)',
      'save': 'አስቀምጥ',
      'settingUpdated': 'ቅንብሩ ተዘምኗል',
      'edit': 'አርትዕ',
      'statusAll': 'ሁሉም',
      'statusSubmitted': 'ቀርቧል',
      'statusUnderReview': 'በግምገማ ላይ',
      'statusApproved': 'ጸድቋል',
      'statusRejected': 'ተቀባይነት አላገኘም',
      'statusPaid': 'ተከፍሏል',
      'statusPending': 'በመጠባበቅ ላይ',
      'statusActive': 'ንቁ',
      'statusSuccess': 'ተሳክቷል',
      'statusFailed': 'አልተሳካም',
      'statusExpired': 'አልቋል',
    },
    'om': {
      'appTitle': 'Bulchiinsa CBHI Magaalaa Maya',
      'appWindowTitle': 'CBHI Magaalaa Maya - Bulchiinsa',
      'portalTitle': 'CBHI Magaalaa Maya\nPoortaalii Bulchiinsaa',
      'portalSubtitle':
          'Hojjettoota CBHI fi bulchitoota sirnaaf.\nKlaayimii, galmeessa, fi qindeessitoota sirnaa bulchi.',
      'signIn': 'Seeni',
      'adminAccessOnly': 'Kan hojii CBHI fi bulchitoota qofa',
      'identifierRequired': 'Imeelii/bilbila fi jecha darbii guuti.',
      'emailOrPhone': 'Imeelii yookaan lakkoofsa bilbilaa',
      'password': 'Jecha darbii',
      'demoMode':
          'Haalli demo hojii irra jira. Ragaa bulchiinsaa kamiyyuu fayyadami.',
      'language': 'Afaan',
      'languageEnglish': 'English',
      'languageAmharic': 'Afaan Amaaraa',
      'languageOromo': 'Afaan Oromoo',
      'navOverview': 'Ilaalcha waliigalaa',
      'navClaims': 'Klaayimii',
      'navIndigent': 'Gargaarsa barbaadan',
      'navReports': 'Gabaasota',
      'navSettings': 'Qindaa\'inoota',
      'signOut': 'Ba\'i',
      'connected': 'Walitti hidhameera',
      'claimsReviewApproval': 'Sakatta\'iinsa fi raggaasisa klaayimii',
      'householdEnrollmentManagement': 'Bulchiinsa galmeessa maatii',
      'reportsAnalytics': 'Gabaasa fi xiinxala',
      'systemConfiguration': 'Qindeessa sirnaa',
      'csvDataExport': 'Ergaa deetaa CSV',
      'totalHouseholds': 'Maatii waliigalaa',
      'accreditedFacilities': 'Dhaabbilee raggaafaman',
      'claimsSubmitted': 'Klaayimii galfaman',
      'pendingIndigent': 'Kan eeggachaa jiran',
      'claimsBreakdown': 'Hirinsa klaayimii',
      'financialSummary': 'Cuunfaa faayinaansii',
      'submitted': 'Galfameera',
      'approved': 'Raggaafameera',
      'rejected': 'Didameera',
      'paid': 'Kaffalameera',
      'totalClaimed': 'Walitti qabama gaafatame',
      'totalApproved': 'Walitti qabama raggaafame',
      'totalTransactions': 'Daldala waliigalaa',
      'totalCollected': 'Walitti qabama sassaabame',
      'refresh': 'Haaromsi',
      'noClaimsFound': 'Klaayimiin hin argamne',
      'claimNumber': 'Klaayimii #',
      'beneficiary': 'Fayyadamaa',
      'facility': 'Dhaabbata',
      'claimedAmount': 'Kan gaafatame (ETB)',
      'approvedAmount': 'Kan raggaafame (ETB)',
      'status': 'Haala',
      'serviceDate': 'Guyyaa tajaajilaa',
      'actions': 'Tarkaanfii',
      'cancel': 'Dhiisi',
      'decisionNote': 'Yaada murtii',
      'setClaimTo': 'Klaayimii gara {status} jijjiiri',
      'claimUpdatedTo': 'Klaayimiin gara {status} haaromfameera',
      'notAvailable': 'Hin jiru',
      'pendingIndigentApplications': 'Iyyannoowwan gargaarsaa eeggachaa jiran',
      'pendingCount': '{count} eeggachaa jira',
      'noPendingApplications': 'Iyyanni eeggachaa jiru hin jiru',
      'allIndigentProcessed': 'Iyyannoowwan hundi hojii irra oolaniiru.',
      'userId': 'ID fayyadamaa',
      'income': 'Galii (ETB)',
      'employment': 'Haala hojii',
      'familySize': 'Baay\'ina maatii',
      'score': 'Qabxii',
      'approve': 'Raggaasi',
      'reject': 'Didi',
      'reviewIndigentTitle': 'Iyyannoo gargaarsaa {action}',
      'overrideReason': 'Sababa jijjiirraa (filannoo)',
      'scoreValue': 'Qabxii: {score} / 100',
      'employmentValue': 'Haala hojii: {employment}',
      'familySizeValue': 'Baay\'ina maatii: {size}',
      'userIdValue': 'ID fayyadamaa: {userId}',
      'dataExport': 'Ergaa deetaa',
      'exportSubtitle':
          'Deetaa CBHI gara CSVtti ergi akka FMOH/EHIAf gabaasamu.',
      'saveExport': 'Ergaa {type} olkaa\'i',
      'exportedTo': 'Gara {path}tti ergameera',
      'households': 'Maatiiwwan',
      'claims': 'Klaayimii',
      'payments': 'Kaffaltiiwwan',
      'indigentApplications': 'Iyyannoowwan gargaarsaa',
      'householdsExportDescription':
          'Maatiiwwan galmaa\'an hundi haala tajaajila fi deetaa teessoo waliin.',
      'claimsExportDescription':
          'Klaayimiiwwan galfaman hundi haala, maallaqa, fi odeeffannoo dhaabbataa waliin.',
      'paymentsExportDescription':
          'Kaffaltiiwwan priimiyeemii hundi mala kaffaltii fi haala isaanii waliin.',
      'indigentExportDescription':
          'Iyyannoowwan gargaarsaa hundi qabxii fi murtii waliin.',
      'exportCsv': 'CSV ergi',
      'manageSystemSettings':
          'Qindaa\'inoota sirna CBHI bulchi. Jijjiiramni battalatti hojii irra oola.',
      'setting': 'Qindeessa',
      'label': 'Maqaa',
      'description': 'Ibsa',
      'valueJson': 'Gatii (JSON)',
      'save': 'Olkaa\'i',
      'settingUpdated': 'Qindeessi haaromfameera',
      'edit': 'Gulaali',
      'statusAll': 'Hundaa',
      'statusSubmitted': 'Galfameera',
      'statusUnderReview': 'Sakatta\'iinsa keessa jira',
      'statusApproved': 'Raggaafameera',
      'statusRejected': 'Didameera',
      'statusPaid': 'Kaffalameera',
      'statusPending': 'Eeggachaa jira',
      'statusActive': 'Sochii keessa',
      'statusSuccess': 'Milkaa\'e',
      'statusFailed': 'Hin milkoofne',
      'statusExpired': 'Yeroon isaa darbeera',
    },
  };

  static AppLocalizations of(BuildContext context) {
    final localization = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    return localization ?? const AppLocalizations(Locale('en'));
  }

  String t(String key, [Map<String, String> params = const {}]) {
    var value =
        _values[locale.languageCode]?[key] ?? _values['en']?[key] ?? key;
    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  String languageLabel(String code) {
    return switch (code) {
      'am' => t('languageAmharic'),
      'om' => t('languageOromo'),
      _ => t('languageEnglish'),
    };
  }

  String statusLabel(String status) {
    return switch (status.toUpperCase()) {
      'ALL' => t('statusAll'),
      'SUBMITTED' => t('statusSubmitted'),
      'UNDER_REVIEW' => t('statusUnderReview'),
      'APPROVED' => t('statusApproved'),
      'REJECTED' => t('statusRejected'),
      'PAID' => t('statusPaid'),
      'PENDING' => t('statusPending'),
      'ACTIVE' => t('statusActive'),
      'SUCCESS' => t('statusSuccess'),
      'FAILED' => t('statusFailed'),
      'EXPIRED' => t('statusExpired'),
      _ => status.replaceAll('_', ' '),
    };
  }

  static LocalizationsDelegate<AppLocalizations> delegateFor(Locale locale) =>
      _AppLocalizationsDelegate(locale);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate(this.selectedLocale);

  final Locale selectedLocale;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(selectedLocale);

  @override
  bool shouldReload(covariant _AppLocalizationsDelegate old) =>
      old.selectedLocale.languageCode != selectedLocale.languageCode;
}
