import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Maya City CBHI'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Community-Based Health Insurance'**
  String get appSubtitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @claims.
  ///
  /// In en, this message translates to:
  /// **'Claims'**
  String get claims;

  /// No description provided for @facilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get facilities;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @startNewRegistration.
  ///
  /// In en, this message translates to:
  /// **'Start New Registration'**
  String get startNewRegistration;

  /// No description provided for @loginAsFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Login as Family Member'**
  String get loginAsFamilyMember;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyAndSignIn.
  ///
  /// In en, this message translates to:
  /// **'Verify and sign in'**
  String get verifyAndSignIn;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @otpCodeExpiry.
  ///
  /// In en, this message translates to:
  /// **'Code expires in'**
  String get otpCodeExpiry;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number'**
  String get emailOrPhone;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @oneTimePassword.
  ///
  /// In en, this message translates to:
  /// **'One-Time Password'**
  String get oneTimePassword;

  /// No description provided for @credentialLogin.
  ///
  /// In en, this message translates to:
  /// **'Credential Login'**
  String get credentialLogin;

  /// No description provided for @forHouseholdHeads.
  ///
  /// In en, this message translates to:
  /// **'For household heads, facility staff, and administrators.'**
  String get forHouseholdHeads;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a verification code to your Ethiopian mobile number.'**
  String get sendVerificationCode;

  /// No description provided for @developmentOtp.
  ///
  /// In en, this message translates to:
  /// **'Development OTP'**
  String get developmentOtp;

  /// No description provided for @notShownInProduction.
  ///
  /// In en, this message translates to:
  /// **'not shown in production'**
  String get notShownInProduction;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Member-centered community-based health insurance for Ethiopian households, health facilities, and CBHI officers.'**
  String get welcomeSubtitle;

  /// No description provided for @multilingual.
  ///
  /// In en, this message translates to:
  /// **'Multilingual'**
  String get multilingual;

  /// No description provided for @digitalCard.
  ///
  /// In en, this message translates to:
  /// **'Digital Card'**
  String get digitalCard;

  /// No description provided for @claimsTracking.
  ///
  /// In en, this message translates to:
  /// **'Claims Tracking'**
  String get claimsTracking;

  /// No description provided for @offlineReady.
  ///
  /// In en, this message translates to:
  /// **'Offline Ready'**
  String get offlineReady;

  /// No description provided for @householdHeadsUseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Household heads, facility staff, and administrators use Sign In. Adult beneficiaries use family member login.'**
  String get householdHeadsUseSignIn;

  /// No description provided for @privacyConsent.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data Consent'**
  String get privacyConsent;

  /// No description provided for @privacyConsentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please read and accept before using Maya City CBHI'**
  String get privacyConsentSubtitle;

  /// No description provided for @scrollToRead.
  ///
  /// In en, this message translates to:
  /// **'Scroll down to read all terms'**
  String get scrollToRead;

  /// No description provided for @iAcceptContinue.
  ///
  /// In en, this message translates to:
  /// **'I Accept — Continue to App'**
  String get iAcceptContinue;

  /// No description provided for @byAccepting.
  ///
  /// In en, this message translates to:
  /// **'By accepting, you consent to the collection and use of your data as described above.'**
  String get byAccepting;

  /// No description provided for @dataWeCollect.
  ///
  /// In en, this message translates to:
  /// **'1. Data We Collect'**
  String get dataWeCollect;

  /// No description provided for @howWeUseData.
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Your Data'**
  String get howWeUseData;

  /// No description provided for @dataStorage.
  ///
  /// In en, this message translates to:
  /// **'3. Data Storage & Security'**
  String get dataStorage;

  /// No description provided for @yourRights.
  ///
  /// In en, this message translates to:
  /// **'4. Your Rights'**
  String get yourRights;

  /// No description provided for @offlineData.
  ///
  /// In en, this message translates to:
  /// **'5. Offline Data'**
  String get offlineData;

  /// No description provided for @thirdPartyServices.
  ///
  /// In en, this message translates to:
  /// **'6. Third-Party Services'**
  String get thirdPartyServices;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'7. Contact'**
  String get contact;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Maya City CBHI'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Community-Based Health Insurance protects your family from unexpected medical costs. Register once and access healthcare services across accredited facilities.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Easy Registration'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Register your household in 4 simple steps. Capture your ID, add family members, and choose your membership type — even without internet.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Your Digital CBHI Card'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Your digital membership card is always in your pocket. Show the QR code at any accredited health facility to verify your coverage instantly.'**
  String get onboardingBody3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Works Offline'**
  String get onboardingTitle4;

  /// No description provided for @onboardingBody4.
  ///
  /// In en, this message translates to:
  /// **'No internet? No problem. Register and manage your household offline. Your data syncs automatically when connectivity is restored.'**
  String get onboardingBody4;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @step1PersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 5'**
  String get step1PersonalInfo;

  /// No description provided for @step2Confirm.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 5'**
  String get step2Confirm;

  /// No description provided for @step3Identity.
  ///
  /// In en, this message translates to:
  /// **'Step 3 of 5'**
  String get step3Identity;

  /// No description provided for @step4Membership.
  ///
  /// In en, this message translates to:
  /// **'Step 4 of 5'**
  String get step4Membership;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInformation;

  /// No description provided for @captureHouseholdDetails.
  ///
  /// In en, this message translates to:
  /// **'Capture household head details and supporting documents before identity verification.'**
  String get captureHouseholdDetails;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @middleName.
  ///
  /// In en, this message translates to:
  /// **'Middle name'**
  String get middleName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get preferredLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @amharic.
  ///
  /// In en, this message translates to:
  /// **'Amharic'**
  String get amharic;

  /// No description provided for @afaanOromo.
  ///
  /// In en, this message translates to:
  /// **'Afaan Oromo'**
  String get afaanOromo;

  /// No description provided for @householdAddress.
  ///
  /// In en, this message translates to:
  /// **'Household address'**
  String get householdAddress;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @zone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// No description provided for @woreda.
  ///
  /// In en, this message translates to:
  /// **'Woreda'**
  String get woreda;

  /// No description provided for @kebele.
  ///
  /// In en, this message translates to:
  /// **'Kebele'**
  String get kebele;

  /// No description provided for @householdSize.
  ///
  /// In en, this message translates to:
  /// **'Household size'**
  String get householdSize;

  /// No description provided for @birthCertificate.
  ///
  /// In en, this message translates to:
  /// **'Birth certificate'**
  String get birthCertificate;

  /// No description provided for @optionalImageOrPdf.
  ///
  /// In en, this message translates to:
  /// **'Optional image or PDF upload'**
  String get optionalImageOrPdf;

  /// No description provided for @reviewInformation.
  ///
  /// In en, this message translates to:
  /// **'Review information'**
  String get reviewInformation;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @choosePdfOrImage.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF or image'**
  String get choosePdfOrImage;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get uploadDocument;

  /// No description provided for @replaceDocument.
  ///
  /// In en, this message translates to:
  /// **'Replace document'**
  String get replaceDocument;

  /// No description provided for @confirmDetails.
  ///
  /// In en, this message translates to:
  /// **'Confirm your details'**
  String get confirmDetails;

  /// No description provided for @reviewBeforeContinuing.
  ///
  /// In en, this message translates to:
  /// **'Review your information before continuing to identity verification.'**
  String get reviewBeforeContinuing;

  /// No description provided for @editInformation.
  ///
  /// In en, this message translates to:
  /// **'Edit information'**
  String get editInformation;

  /// No description provided for @continueToIdentity.
  ///
  /// In en, this message translates to:
  /// **'Continue to identity verification'**
  String get continueToIdentity;

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get identityVerification;

  /// No description provided for @collectIdForScreening.
  ///
  /// In en, this message translates to:
  /// **'Collect the member identification number and employment status needed for CBHI eligibility screening.'**
  String get collectIdForScreening;

  /// No description provided for @identityDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Identity document type'**
  String get identityDocumentType;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @localId.
  ///
  /// In en, this message translates to:
  /// **'Local ID'**
  String get localId;

  /// No description provided for @passport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// No description provided for @fanNumber.
  ///
  /// In en, this message translates to:
  /// **'FAN Number'**
  String get fanNumber;

  /// No description provided for @fanNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Your 12-digit Fayda Authentication Number'**
  String get fanNumberHint;

  /// No description provided for @identityDocument.
  ///
  /// In en, this message translates to:
  /// **'Identity document'**
  String get identityDocument;

  /// No description provided for @nationalIdOrPassportPhoto.
  ///
  /// In en, this message translates to:
  /// **'National ID, local ID, or passport photo'**
  String get nationalIdOrPassportPhoto;

  /// No description provided for @employmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Employment status'**
  String get employmentStatus;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @dailyLaborer.
  ///
  /// In en, this message translates to:
  /// **'Daily laborer'**
  String get dailyLaborer;

  /// No description provided for @employed.
  ///
  /// In en, this message translates to:
  /// **'Employed'**
  String get employed;

  /// No description provided for @unemployed.
  ///
  /// In en, this message translates to:
  /// **'Unemployed'**
  String get unemployed;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @homemaker.
  ///
  /// In en, this message translates to:
  /// **'Homemaker'**
  String get homemaker;

  /// No description provided for @pensioner.
  ///
  /// In en, this message translates to:
  /// **'Pensioner'**
  String get pensioner;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @validatingDocument.
  ///
  /// In en, this message translates to:
  /// **'Validating document with AI...'**
  String get validatingDocument;

  /// No description provided for @documentVerified.
  ///
  /// In en, this message translates to:
  /// **'Document verified successfully.'**
  String get documentVerified;

  /// No description provided for @retryValidation.
  ///
  /// In en, this message translates to:
  /// **'Retry validation'**
  String get retryValidation;

  /// No description provided for @membershipSelection.
  ///
  /// In en, this message translates to:
  /// **'Membership selection'**
  String get membershipSelection;

  /// No description provided for @chooseMembershipPathway.
  ///
  /// In en, this message translates to:
  /// **'Choose the household membership pathway. Paying members can enter a premium estimate while indigent members use employment screening.'**
  String get chooseMembershipPathway;

  /// No description provided for @indigentMembership.
  ///
  /// In en, this message translates to:
  /// **'Indigent membership'**
  String get indigentMembership;

  /// No description provided for @indigentMembershipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Zero-touch eligibility screening with subsidized premium if approved.'**
  String get indigentMembershipSubtitle;

  /// No description provided for @payingMembership.
  ///
  /// In en, this message translates to:
  /// **'Paying membership'**
  String get payingMembership;

  /// No description provided for @payingMembershipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Standard membership with annual household premium payment.'**
  String get payingMembershipSubtitle;

  /// No description provided for @estimatedPremiumAmount.
  ///
  /// In en, this message translates to:
  /// **'Estimated premium amount (ETB)'**
  String get estimatedPremiumAmount;

  /// No description provided for @completeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete registration'**
  String get completeRegistration;

  /// No description provided for @indigentApplication.
  ///
  /// In en, this message translates to:
  /// **'Indigent Application'**
  String get indigentApplication;

  /// No description provided for @indigentApplicationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Qualifying households receive subsidized or free CBHI coverage. Upload supporting documents from your kebele. Documents are verified automatically by AI.'**
  String get indigentApplicationSubtitle;

  /// No description provided for @monthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly Income'**
  String get monthlyIncome;

  /// No description provided for @monthlyIncomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your household monthly income in ETB.'**
  String get monthlyIncomeSubtitle;

  /// No description provided for @monthlyIncomeEtb.
  ///
  /// In en, this message translates to:
  /// **'Monthly income (ETB)'**
  String get monthlyIncomeEtb;

  /// No description provided for @householdStatus.
  ///
  /// In en, this message translates to:
  /// **'Household Status'**
  String get householdStatus;

  /// No description provided for @ownsProperty.
  ///
  /// In en, this message translates to:
  /// **'Owns property (land, house, or business)'**
  String get ownsProperty;

  /// No description provided for @hasMemberWithDisability.
  ///
  /// In en, this message translates to:
  /// **'Has a household member with disability'**
  String get hasMemberWithDisability;

  /// No description provided for @supportingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Supporting Documents'**
  String get supportingDocuments;

  /// No description provided for @upload1To3Documents.
  ///
  /// In en, this message translates to:
  /// **'Upload 1-3 documents from your kebele.'**
  String get upload1To3Documents;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addDocument;

  /// No description provided for @acceptedDocumentTypes.
  ///
  /// In en, this message translates to:
  /// **'Accepted document types'**
  String get acceptedDocumentTypes;

  /// No description provided for @noDocumentsYet.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded yet'**
  String get noDocumentsYet;

  /// No description provided for @tapAddToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap Add to upload a document'**
  String get tapAddToUpload;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// No description provided for @validatingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Validating documents...'**
  String get validatingDocuments;

  /// No description provided for @expiredDocumentsCannotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Expired documents — cannot submit'**
  String get expiredDocumentsCannotSubmit;

  /// No description provided for @documentExpired.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get documentExpired;

  /// No description provided for @documentAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get documentAccepted;

  /// No description provided for @issueDetected.
  ///
  /// In en, this message translates to:
  /// **'Issue detected'**
  String get issueDetected;

  /// No description provided for @documentExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'This document has expired. Please obtain a new certificate from your kebele.'**
  String get documentExpiredMessage;

  /// No description provided for @incomeCertificate.
  ///
  /// In en, this message translates to:
  /// **'Income Certificate'**
  String get incomeCertificate;

  /// No description provided for @disabilityCertificate.
  ///
  /// In en, this message translates to:
  /// **'Disability Certificate'**
  String get disabilityCertificate;

  /// No description provided for @kebeleId.
  ///
  /// In en, this message translates to:
  /// **'Kebele ID / Residence'**
  String get kebeleId;

  /// No description provided for @povertyCertificate.
  ///
  /// In en, this message translates to:
  /// **'Poverty Certificate'**
  String get povertyCertificate;

  /// No description provided for @agriculturalCertificate.
  ///
  /// In en, this message translates to:
  /// **'Agricultural Certificate'**
  String get agriculturalCertificate;

  /// No description provided for @validFor.
  ///
  /// In en, this message translates to:
  /// **'Valid for {months} months'**
  String validFor(int months);

  /// No description provided for @issued.
  ///
  /// In en, this message translates to:
  /// **'Issued: {date}'**
  String issued(String date);

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'{percent}% confidence'**
  String confidence(String percent);

  /// No description provided for @registrationSavedForSync.
  ///
  /// In en, this message translates to:
  /// **'Registration saved for sync'**
  String get registrationSavedForSync;

  /// No description provided for @registrationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Registration completed'**
  String get registrationCompleted;

  /// No description provided for @offlineQueueMessage.
  ///
  /// In en, this message translates to:
  /// **'Your household record is safely queued offline. As soon as the app syncs online, your member account will activate automatically.'**
  String get offlineQueueMessage;

  /// No description provided for @registrationSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Maya City household account is active and your digital CBHI card is now available from the home screen.'**
  String get registrationSuccessMessage;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @openMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Open my account'**
  String get openMyAccount;

  /// No description provided for @startAnotherRegistration.
  ///
  /// In en, this message translates to:
  /// **'Start another registration'**
  String get startAnotherRegistration;

  /// No description provided for @household.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get household;

  /// No description provided for @coverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get coverage;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @eligibility.
  ///
  /// In en, this message translates to:
  /// **'Eligibility'**
  String get eligibility;

  /// No description provided for @eligible.
  ///
  /// In en, this message translates to:
  /// **'Eligible'**
  String get eligible;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @noHouseholdSynced.
  ///
  /// In en, this message translates to:
  /// **'No household synced yet'**
  String get noHouseholdSynced;

  /// No description provided for @guestSession.
  ///
  /// In en, this message translates to:
  /// **'Guest Session'**
  String get guestSession;

  /// No description provided for @offlineQueueActive.
  ///
  /// In en, this message translates to:
  /// **'Offline queue active'**
  String get offlineQueueActive;

  /// No description provided for @householdSynced.
  ///
  /// In en, this message translates to:
  /// **'Household synced'**
  String get householdSynced;

  /// No description provided for @changesWaitingToSync.
  ///
  /// In en, this message translates to:
  /// **'Changes are waiting to sync.'**
  String get changesWaitingToSync;

  /// No description provided for @dataAndCardUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Data and digital card are up to date.'**
  String get dataAndCardUpToDate;

  /// No description provided for @renewalStatus.
  ///
  /// In en, this message translates to:
  /// **'Renewal Status'**
  String get renewalStatus;

  /// No description provided for @personalEligibility.
  ///
  /// In en, this message translates to:
  /// **'Personal Eligibility'**
  String get personalEligibility;

  /// No description provided for @coverageEligibilityDetails.
  ///
  /// In en, this message translates to:
  /// **'Coverage eligibility details will appear after sync.'**
  String get coverageEligibilityDetails;

  /// No description provided for @renewCoverage.
  ///
  /// In en, this message translates to:
  /// **'Renew Coverage'**
  String get renewCoverage;

  /// No description provided for @confirmRenewal.
  ///
  /// In en, this message translates to:
  /// **'Confirm Renewal'**
  String get confirmRenewal;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @noPaymentsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded'**
  String get noPaymentsRecorded;

  /// No description provided for @renewalTransactionsHere.
  ///
  /// In en, this message translates to:
  /// **'Renewal and contribution transactions will appear here.'**
  String get renewalTransactionsHere;

  /// No description provided for @recentNotifications.
  ///
  /// In en, this message translates to:
  /// **'Recent Notifications'**
  String get recentNotifications;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @coverageAlertsHere.
  ///
  /// In en, this message translates to:
  /// **'Coverage alerts and benefit updates will appear here.'**
  String get coverageAlertsHere;

  /// No description provided for @viewAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'View all notifications'**
  String get viewAllNotifications;

  /// No description provided for @allNotifications.
  ///
  /// In en, this message translates to:
  /// **'All Notifications'**
  String get allNotifications;

  /// No description provided for @independentAccess.
  ///
  /// In en, this message translates to:
  /// **'Independent access'**
  String get independentAccess;

  /// No description provided for @householdManaged.
  ///
  /// In en, this message translates to:
  /// **'Household-managed'**
  String get householdManaged;

  /// No description provided for @beneficiaryProfile.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary Profile'**
  String get beneficiaryProfile;

  /// No description provided for @offlineIndicator.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineIndicator;

  /// No description provided for @confirmFreeRenewal.
  ///
  /// In en, this message translates to:
  /// **'Confirm Free Renewal'**
  String get confirmFreeRenewal;

  /// No description provided for @freeRenewalMessage.
  ///
  /// In en, this message translates to:
  /// **'This household qualifies for subsidized coverage. Tap confirm to extend your coverage for another year at no cost.'**
  String get freeRenewalMessage;

  /// No description provided for @confirmFreeRenewalButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Free Renewal'**
  String get confirmFreeRenewalButton;

  /// No description provided for @payPremium.
  ///
  /// In en, this message translates to:
  /// **'Pay Premium'**
  String get payPremium;

  /// No description provided for @premiumAmount.
  ///
  /// In en, this message translates to:
  /// **'Premium Amount'**
  String get premiumAmount;

  /// No description provided for @acceptedPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Accepted Payment Methods'**
  String get acceptedPaymentMethods;

  /// No description provided for @telebirr.
  ///
  /// In en, this message translates to:
  /// **'Telebirr'**
  String get telebirr;

  /// No description provided for @cbeBirr.
  ///
  /// In en, this message translates to:
  /// **'CBE Birr'**
  String get cbeBirr;

  /// No description provided for @amole.
  ///
  /// In en, this message translates to:
  /// **'Amole'**
  String get amole;

  /// No description provided for @helloCash.
  ///
  /// In en, this message translates to:
  /// **'HelloCash'**
  String get helloCash;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @demoSandboxNoBankCharge.
  ///
  /// In en, this message translates to:
  /// **'Demo Sandbox — No real money charged'**
  String get demoSandboxNoBankCharge;

  /// No description provided for @payViaChapa.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} ETB via Chapa'**
  String payViaChapa(String amount);

  /// No description provided for @paymentInitiated.
  ///
  /// In en, this message translates to:
  /// **'Payment Initiated'**
  String get paymentInitiated;

  /// No description provided for @transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction: {txRef}'**
  String transaction(String txRef);

  /// No description provided for @completePaymentOnChapa.
  ///
  /// In en, this message translates to:
  /// **'Complete your payment on the Chapa checkout page, then tap \"Verify Payment\" below.'**
  String get completePaymentOnChapa;

  /// No description provided for @verifyPayment.
  ///
  /// In en, this message translates to:
  /// **'Verify Payment'**
  String get verifyPayment;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment successful! Coverage activated.'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment could not be completed. Please try again.'**
  String get paymentFailed;

  /// No description provided for @myFamily.
  ///
  /// In en, this message translates to:
  /// **'My family'**
  String get myFamily;

  /// No description provided for @householdMembers.
  ///
  /// In en, this message translates to:
  /// **'Household members'**
  String get householdMembers;

  /// No description provided for @viewHouseholdMembers.
  ///
  /// In en, this message translates to:
  /// **'View your household members and their current coverage details.'**
  String get viewHouseholdMembers;

  /// No description provided for @manageHouseholdBeneficiaries.
  ///
  /// In en, this message translates to:
  /// **'Manage household beneficiaries, capture photos, and prepare family-member OTP access from one place.'**
  String get manageHouseholdBeneficiaries;

  /// No description provided for @addBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Add beneficiary'**
  String get addBeneficiary;

  /// No description provided for @noBeneficiariesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No beneficiaries available'**
  String get noBeneficiariesAvailable;

  /// No description provided for @addFamilyMembersOnceActive.
  ///
  /// In en, this message translates to:
  /// **'Add family members once the household account is active.'**
  String get addFamilyMembersOnceActive;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Remove beneficiary?'**
  String get removeBeneficiary;

  /// No description provided for @removeConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove {name} from the household.'**
  String removeConfirmMessage(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @accessThroughHouseholdHead.
  ///
  /// In en, this message translates to:
  /// **'Access through household head'**
  String get accessThroughHouseholdHead;

  /// No description provided for @independentLoginNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Independent login not yet enabled'**
  String get independentLoginNotEnabled;

  /// No description provided for @otpEnabled.
  ///
  /// In en, this message translates to:
  /// **'OTP enabled'**
  String get otpEnabled;

  /// No description provided for @beneficiaryDetails.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary details'**
  String get beneficiaryDetails;

  /// No description provided for @captureBeneficiaryProfile.
  ///
  /// In en, this message translates to:
  /// **'Capture the beneficiary profile, photo, and optional OTP access phone number.'**
  String get captureBeneficiaryProfile;

  /// No description provided for @beneficiaryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary photo'**
  String get beneficiaryPhoto;

  /// No description provided for @useCamera.
  ///
  /// In en, this message translates to:
  /// **'Use the camera or gallery and confirm the preview before saving.'**
  String get useCamera;

  /// No description provided for @addOrChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add or change photo'**
  String get addOrChangePhoto;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @enterFirstAndLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter at least first name and last name.'**
  String get enterFirstAndLastName;

  /// No description provided for @relationshipToHouseholdHead.
  ///
  /// In en, this message translates to:
  /// **'Relationship to household head'**
  String get relationshipToHouseholdHead;

  /// No description provided for @spouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get spouse;

  /// No description provided for @child.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get child;

  /// No description provided for @parent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parent;

  /// No description provided for @sibling.
  ///
  /// In en, this message translates to:
  /// **'Sibling'**
  String get sibling;

  /// No description provided for @independentAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Independent access'**
  String get independentAccessSection;

  /// No description provided for @independentAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Non-child beneficiaries must have a phone number. Adult beneficiaries can then use OTP or a password for independent access.'**
  String get independentAccessDescription;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required for non-child beneficiaries.'**
  String get phoneRequired;

  /// No description provided for @identityDetails.
  ///
  /// In en, this message translates to:
  /// **'Identity details'**
  String get identityDetails;

  /// No description provided for @nationalIdOrLocalIdOptional.
  ///
  /// In en, this message translates to:
  /// **'National ID or local ID is optional for beneficiaries.'**
  String get nationalIdOrLocalIdOptional;

  /// No description provided for @idTypeOptional.
  ///
  /// In en, this message translates to:
  /// **'ID type (optional)'**
  String get idTypeOptional;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @idNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'ID number (optional)'**
  String get idNumberOptional;

  /// No description provided for @saveBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Save beneficiary'**
  String get saveBeneficiary;

  /// No description provided for @updateBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Update beneficiary'**
  String get updateBeneficiary;

  /// No description provided for @photoRequired.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary photo is required before saving.'**
  String get photoRequired;

  /// No description provided for @digitalCbhiCards.
  ///
  /// In en, this message translates to:
  /// **'Digital CBHI Cards'**
  String get digitalCbhiCards;

  /// No description provided for @encryptedQrToken.
  ///
  /// In en, this message translates to:
  /// **'Encrypted QR token • Tap card to verify'**
  String get encryptedQrToken;

  /// No description provided for @completeSyncForQr.
  ///
  /// In en, this message translates to:
  /// **'Complete sync to generate QR token'**
  String get completeSyncForQr;

  /// No description provided for @shareCardInfo.
  ///
  /// In en, this message translates to:
  /// **'Share Card Info'**
  String get shareCardInfo;

  /// No description provided for @cardDetailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Card details copied — share with facility staff if needed.'**
  String get cardDetailsCopied;

  /// No description provided for @myClaims.
  ///
  /// In en, this message translates to:
  /// **'My Claims'**
  String get myClaims;

  /// No description provided for @trackClaimsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track all health service claims submitted on your behalf by accredited facilities.'**
  String get trackClaimsSubtitle;

  /// No description provided for @claimsSubmittedByFacility.
  ///
  /// In en, this message translates to:
  /// **'Claims are submitted by health facility staff when you receive services. Show your digital card at any accredited facility.'**
  String get claimsSubmittedByFacility;

  /// No description provided for @noClaimsYet.
  ///
  /// In en, this message translates to:
  /// **'No claims yet'**
  String get noClaimsYet;

  /// No description provided for @claimsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Claims will appear here after you receive services at an accredited health facility.'**
  String get claimsWillAppearHere;

  /// No description provided for @serviceDate.
  ///
  /// In en, this message translates to:
  /// **'Service Date'**
  String get serviceDate;

  /// No description provided for @claimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get claimed;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @claimNumber.
  ///
  /// In en, this message translates to:
  /// **'Claim #'**
  String get claimNumber;

  /// No description provided for @beneficiary.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary'**
  String get beneficiary;

  /// No description provided for @facility.
  ///
  /// In en, this message translates to:
  /// **'Facility'**
  String get facility;

  /// No description provided for @decisionNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get decisionNote;

  /// No description provided for @findHealthFacilities.
  ///
  /// In en, this message translates to:
  /// **'Find Health Facilities'**
  String get findHealthFacilities;

  /// No description provided for @searchByFacilityName.
  ///
  /// In en, this message translates to:
  /// **'Search by facility name...'**
  String get searchByFacilityName;

  /// No description provided for @noFacilitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No accredited facilities found'**
  String get noFacilitiesFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @accredited.
  ///
  /// In en, this message translates to:
  /// **'Accredited'**
  String get accredited;

  /// No description provided for @serviceLevel.
  ///
  /// In en, this message translates to:
  /// **'Service Level'**
  String get serviceLevel;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @easierOnEyes.
  ///
  /// In en, this message translates to:
  /// **'Easier on the eyes in low light'**
  String get easierOnEyes;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @useFingerprintOrFace.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face ID to sign in'**
  String get useFingerprintOrFace;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @authority.
  ///
  /// In en, this message translates to:
  /// **'Authority'**
  String get authority;

  /// No description provided for @ministry.
  ///
  /// In en, this message translates to:
  /// **'Ministry'**
  String get ministry;

  /// No description provided for @ehia.
  ///
  /// In en, this message translates to:
  /// **'Ethiopian Health Insurance Agency (EHIA)'**
  String get ehia;

  /// No description provided for @fmoh.
  ///
  /// In en, this message translates to:
  /// **'Federal Ministry of Health (FMOH)'**
  String get fmoh;

  /// No description provided for @platformVersion.
  ///
  /// In en, this message translates to:
  /// **'Maya City CBHI v1.0'**
  String get platformVersion;

  /// No description provided for @helpAndFaq.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpAndFaq;

  /// No description provided for @ehiaHelpline.
  ///
  /// In en, this message translates to:
  /// **'EHIA Helpline'**
  String get ehiaHelpline;

  /// No description provided for @ehiaContact.
  ///
  /// In en, this message translates to:
  /// **'info@ehia.gov.et  |  Ethiopian Health Insurance Agency'**
  String get ehiaContact;

  /// No description provided for @faqQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I register my household?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Start New Registration\" on the welcome screen. Complete the 4 steps: personal info, identity verification, and membership selection. You can register offline — data syncs when you connect.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In en, this message translates to:
  /// **'What is a FAN Number?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In en, this message translates to:
  /// **'FAN stands for Fayda Authentication Number — your 12-digit Ethiopian National ID number. You can find it on your Fayda ID card.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In en, this message translates to:
  /// **'How do I pay my premium?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Renew Coverage\" on the Home screen. You can pay via Telebirr, CBE Birr, Amole, HelloCash, or bank transfer through the Chapa payment page.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In en, this message translates to:
  /// **'How do I add family members?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In en, this message translates to:
  /// **'Go to the Family tab and tap \"Add beneficiary\". You need to capture a photo and provide basic details. Non-child members need a phone number for independent access.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In en, this message translates to:
  /// **'How do I use my digital CBHI card?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In en, this message translates to:
  /// **'Go to the Card tab to view your digital membership card with QR code. Show this to health facility staff to verify your eligibility for services.'**
  String get faqA5;

  /// No description provided for @faqQ6.
  ///
  /// In en, this message translates to:
  /// **'What if I have no internet connection?'**
  String get faqQ6;

  /// No description provided for @faqA6.
  ///
  /// In en, this message translates to:
  /// **'The app works offline. Registration and changes are saved locally and sync automatically when you reconnect. Look for the \"Offline queue active\" indicator on the Home screen.'**
  String get faqA6;

  /// No description provided for @faqQ7.
  ///
  /// In en, this message translates to:
  /// **'How do I track my claims?'**
  String get faqQ7;

  /// No description provided for @faqA7.
  ///
  /// In en, this message translates to:
  /// **'Go to the Claims tab to see all claims submitted by health facilities on your behalf. You will see the status (Submitted, Under Review, Approved, Paid, or Rejected).'**
  String get faqA7;

  /// No description provided for @faqQ8.
  ///
  /// In en, this message translates to:
  /// **'How do I find accredited health facilities?'**
  String get faqQ8;

  /// No description provided for @faqA8.
  ///
  /// In en, this message translates to:
  /// **'Go to the Facilities tab and search by name. All listed facilities are accredited by EHIA and accept your CBHI membership card.'**
  String get faqA8;

  /// No description provided for @faqQ9.
  ///
  /// In en, this message translates to:
  /// **'Who do I contact for help?'**
  String get faqQ9;

  /// No description provided for @faqA9.
  ///
  /// In en, this message translates to:
  /// **'Contact the Ethiopian Health Insurance Agency (EHIA) at info@ehia.gov.et or visit your local CBHI office. You can also call the EHIA helpline.'**
  String get faqA9;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Ethiopian mobile number (+2519XXXXXXXX)'**
  String get invalidPhone;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @invalidDate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date'**
  String get invalidDate;

  /// No description provided for @minAge.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 18 years old'**
  String get minAge;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unknownError;

  /// No description provided for @networkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Changes saved offline.'**
  String get networkUnavailable;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get sessionExpired;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading your health coverage...'**
  String get loading;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @etb.
  ///
  /// In en, this message translates to:
  /// **'ETB'**
  String get etb;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @adminPortalTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Portal'**
  String get adminPortalTitle;

  /// No description provided for @adminPortalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For CBHI Officers and System Administrators.'**
  String get adminPortalSubtitle;

  /// No description provided for @facilityPortalTitle.
  ///
  /// In en, this message translates to:
  /// **'Facility Staff Portal'**
  String get facilityPortalTitle;

  /// No description provided for @facilityPortalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Health Facility Staff use the dedicated desktop application.'**
  String get facilityPortalSubtitle;

  /// No description provided for @useDesktopApp.
  ///
  /// In en, this message translates to:
  /// **'Please use the dedicated desktop application for your role.'**
  String get useDesktopApp;

  /// No description provided for @installAdminApp.
  ///
  /// In en, this message translates to:
  /// **'Install: cbhi_admin_desktop'**
  String get installAdminApp;

  /// No description provided for @installFacilityApp.
  ///
  /// In en, this message translates to:
  /// **'Install: cbhi_facility_desktop'**
  String get installFacilityApp;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am': return AppLocalizationsAm();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
