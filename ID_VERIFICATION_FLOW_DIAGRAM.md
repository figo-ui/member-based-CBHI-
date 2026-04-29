# ID Verification Flow Diagram

## Complete User Journey

```
┌──────────────────────────────────────────────────────────────────────┐
│                         USER STARTS REGISTRATION                      │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│  STEP 1: PERSONAL INFORMATION                                         │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  User enters:                                                   │  │
│  │  • First Name: "Abebe"                                         │  │
│  │  • Father Name: "Bekele"                                       │  │
│  │  • Last Name: "Tadesse"                                        │  │
│  │  • Phone: "+251912345678"                                      │  │
│  │  • Date of Birth, Gender, etc.                                 │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  [Continue] ──────────────────────────────────────────────────────▶   │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│  STEP 2: CONFIRMATION                                                 │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Review information:                                            │  │
│  │  ✓ Name: Abebe Bekele Tadesse                                  │  │
│  │  ✓ Phone: +251912345678                                        │  │
│  │  ✓ DOB: 1990-01-15                                             │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  [Confirm] ───────────────────────────────────────────────────────▶   │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│  STEP 3: IDENTITY VERIFICATION ✨ NEW FEATURES                        │
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  1. SELECT IDENTITY TYPE                                        │  │
│  │     [National ID ▼] [Passport] [Local ID]                      │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                    │                                   │
│                                    ▼                                   │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  2. UPLOAD ID DOCUMENT                                          │  │
│  │     ┌──────────────────────────────────────────────────────┐   │  │
│  │     │  📷 Scan or Upload ID                                 │   │  │
│  │     │  Tap to take photo or choose from gallery            │   │  │
│  │     └──────────────────────────────────────────────────────┘   │  │
│  │                                                                  │  │
│  │     User taps ──▶ [Camera] or [Gallery]                        │  │
│  │                                                                  │  │
│  │     Image selected ──▶ [Preview shown]                          │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                    │                                   │
│                                    ▼                                   │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  3. OCR PROCESSING                                              │  │
│  │     ⏳ Processing ID document...                                │  │
│  │                                                                  │  │
│  │     Backend calls Google Vision API                             │  │
│  │     ├─ Extract ID Number: "123456789012"                       │  │
│  │     └─ Extract Name: "Abebe Bekele Tadesse"                    │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                    │                                   │
│                                    ▼                                   │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  4. NAME MATCHING ✨ NEW                                        │  │
│  │     ┌──────────────────────────────────────────────────────┐   │  │
│  │     │  📋 Name Verification                                 │   │  │
│  │     │                                                        │   │  │
│  │     │  Name on ID:        Abebe Bekele Tadesse             │   │  │
│  │     │  Name you entered:  Abebe Bekele Tadesse             │   │  │
│  │     │                                                        │   │  │
│  │     │  ✅ Names match                                       │   │  │
│  │     └──────────────────────────────────────────────────────┘   │  │
│  │                                                                  │  │
│  │     Compare logic:                                               │  │
│  │     • Normalize both names (lowercase, trim)                    │  │
│  │     • Split into tokens: ["abebe", "bekele", "tadesse"]        │  │
│  │     • Count matches: 3 tokens match                             │  │
│  │     • Result: ✅ MATCHED (≥2 tokens)                            │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                    │                                   │
│                                    ▼                                   │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  5. DUPLICATE ID CHECK ✨ NEW                                   │  │
│  │     ⏳ Checking ID availability...                              │  │
│  │                                                                  │  │
│  │     API Call: GET /api/v1/cbhi/registration/check-id/123...    │  │
│  │     Database Query: SELECT * FROM users WHERE identityNumber=?  │  │
│  │                                                                  │  │
│  │     ┌──────────────────────────────────────────────────────┐   │  │
│  │     │  🔍 ID Availability                                   │   │  │
│  │     │                                                        │   │  │
│  │     │  ✅ ID number is available                            │   │  │
│  │     │  This ID is not registered in the system             │   │  │
│  │     └──────────────────────────────────────────────────────┘   │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                    │                                   │
│                                    ▼                                   │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  6. EMPLOYMENT STATUS                                           │  │
│  │     [Farmer ▼] [Merchant] [Employed] [Student] ...             │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                    │                                   │
│                                    ▼                                   │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  7. SUBMIT VALIDATION                                           │  │
│  │     ✅ Image uploaded                                           │  │
│  │     ✅ ID number extracted                                      │  │
│  │     ✅ Names match                                              │  │
│  │     ✅ ID is available                                          │  │
│  │     ✅ Employment selected                                      │  │
│  │                                                                  │  │
│  │     [Continue to Membership] ──────────────────────────────▶    │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│  STEP 4: MEMBERSHIP SELECTION                                         │
│  Choose benefit package and continue...                               │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Error Scenarios

### Scenario A: Name Mismatch ❌

```
┌──────────────────────────────────────────────────────────────────────┐
│  STEP 3: IDENTITY VERIFICATION                                        │
│                                                                        │
│  Personal Info: "Abebe Bekele Tadesse"                               │
│  ID Document: "Alemayehu Girma Haile"                                │
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  📋 Name Verification                                          │  │
│  │                                                                 │  │
│  │  Name on ID:        Alemayehu Girma Haile                     │  │
│  │  Name you entered:  Abebe Bekele Tadesse                      │  │
│  │                                                                 │  │
│  │  ❌ Names do not match                                         │  │
│  │                                                                 │  │
│  │  ⚠️ The name on your ID does not match the name you entered.  │  │
│  │  Please verify your information or upload a different ID.     │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  [Continue to Membership] ──────────────────────────────────────▶     │
│  (DISABLED - Cannot proceed)                                          │
│                                                                        │
│  User must:                                                            │
│  • Go back and correct personal info, OR                              │
│  • Upload correct ID document, OR                                     │
│  • Contact support                                                    │
└──────────────────────────────────────────────────────────────────────┘
```

### Scenario B: Duplicate ID ❌

```
┌──────────────────────────────────────────────────────────────────────┐
│  STEP 3: IDENTITY VERIFICATION                                        │
│                                                                        │
│  ID Number: "TEST-ID-001" (already registered)                       │
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  📋 Name Verification                                          │  │
│  │  ✅ Names match                                                │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  🔍 ID Availability                                            │  │
│  │                                                                 │  │
│  │  ❌ ID number already registered                               │  │
│  │                                                                 │  │
│  │  ⚠️ This ID number is already registered in the system.       │  │
│  │  If this is your ID, please contact support.                  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  [Continue to Membership] ──────────────────────────────────────▶     │
│  (DISABLED - Cannot proceed)                                          │
│                                                                        │
│  User must:                                                            │
│  • Contact support (cannot proceed with duplicate ID)                 │
└──────────────────────────────────────────────────────────────────────┘
```

### Scenario C: OCR Failure

```
┌──────────────────────────────────────────────────────────────────────┐
│  STEP 3: IDENTITY VERIFICATION                                        │
│                                                                        │
│  Image uploaded: [blurry_id.jpg]                                     │
│                                                                        │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  ⚠️ Low confidence                                             │  │
│  │  Could not extract ID number with high confidence             │  │
│  │                                                                 │  │
│  │  [🔄 Retry Validation]                                         │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  User can:                                                             │
│  • Click "Retry Validation" to try again                              │
│  • Upload a better quality image                                      │
│  • Ensure good lighting and focus                                     │
└──────────────────────────────────────────────────────────────────────┘
```

---

## State Machine Diagram

```
                    ┌─────────────┐
                    │   IDLE      │
                    │ (No image)  │
                    └──────┬──────┘
                           │
                    User uploads image
                           │
                           ▼
                    ┌─────────────┐
                    │  SCANNING   │
                    │ (OCR in     │
                    │  progress)  │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
         Success      Low Conf      Failed
              │            │            │
              ▼            ▼            ▼
       ┌──────────┐  ┌──────────┐  ┌──────────┐
       │ SUCCESS  │  │ LOW_CONF │  │  FAILED  │
       │          │  │          │  │          │
       │ ✅ ID    │  │ ⚠️ Retry │  │ ❌ Error │
       │ ✅ Name  │  │          │  │          │
       └────┬─────┘  └────┬─────┘  └────┬─────┘
            │             │              │
            │             │              │
            ▼             │              │
    ┌──────────────┐      │              │
    │ NAME MATCH   │      │              │
    │              │      │              │
    │ Compare with │      │              │
    │ personal info│      │              │
    └──────┬───────┘      │              │
           │              │              │
    ┌──────┼──────┐       │              │
    │      │      │       │              │
  Match  Mismatch Skip    │              │
    │      │      │       │              │
    ▼      ▼      ▼       │              │
  ✅     ❌     ℹ️        │              │
    │      │      │       │              │
    └──────┼──────┘       │              │
           │              │              │
           ▼              │              │
    ┌──────────────┐      │              │
    │ DUPLICATE    │      │              │
    │ CHECK        │      │              │
    │              │      │              │
    │ API call to  │      │              │
    │ check ID     │      │              │
    └──────┬───────┘      │              │
           │              │              │
    ┌──────┼──────┐       │              │
    │      │      │       │              │
Available Taken Error     │              │
    │      │      │       │              │
    ▼      ▼      ▼       │              │
  ✅     ❌     ✅        │              │
    │      │      │       │              │
    └──────┼──────┘       │              │
           │              │              │
           ▼              ▼              ▼
    ┌──────────────────────────────────────┐
    │      SUBMIT BUTTON STATE             │
    │                                      │
    │  Enabled if:                         │
    │  • Name: Match or Skip               │
    │  • ID: Available                     │
    │  • All fields valid                  │
    │                                      │
    │  Disabled if:                        │
    │  • Name: Mismatch                    │
    │  • ID: Taken or Checking             │
    │  • OCR: Scanning or Failed           │
    └──────────────────────────────────────┘
```

---

## API Flow Diagram

```
┌──────────────┐                    ┌──────────────┐
│   Flutter    │                    │   Backend    │
│     App      │                    │   (NestJS)   │
└──────┬───────┘                    └──────┬───────┘
       │                                   │
       │  1. Upload ID Image               │
       │  POST /api/v1/vision/validate-id  │
       │  Body: { imageBase64: "..." }     │
       ├──────────────────────────────────▶│
       │                                   │
       │                                   │  2. Call Google Vision API
       │                                   ├─────────────────────────▶
       │                                   │  Extract text from image
       │                                   │
       │                                   │  3. Parse extracted text
       │                                   │  - Find ID number
       │                                   │  - Find name
       │                                   │
       │  4. Return results                │
       │  { detectedIdNumber: "123...",    │
       │    detectedName: "Abebe...",      │
       │    isValid: true,                 │
       │    confidence: 0.95 }             │
       │◀──────────────────────────────────┤
       │                                   │
       │  5. Compare names locally         │
       │  (Frontend logic)                 │
       │                                   │
       │  6. Check ID availability         │
       │  GET /api/v1/cbhi/registration/   │
       │      check-id/123456789012        │
       ├──────────────────────────────────▶│
       │                                   │
       │                                   │  7. Query database
       │                                   │  SELECT * FROM users
       │                                   │  WHERE identityNumber=?
       │                                   │
       │  8. Return availability           │
       │  { available: true }              │
       │◀──────────────────────────────────┤
       │                                   │
       │  9. Display results to user       │
       │  - Name match status              │
       │  - ID availability status         │
       │  - Enable/disable submit          │
       │                                   │
       │  10. Submit registration          │
       │  POST /api/v1/cbhi/registration/  │
       │       step-2                      │
       │  Body: { identityType: "...",     │
       │          identityNumber: "...",   │
       │          employmentStatus: "..." }│
       ├──────────────────────────────────▶│
       │                                   │
       │                                   │  11. Final validation
       │                                   │  - Check duplicate again
       │                                   │  - Save to database
       │                                   │
       │  12. Return success               │
       │  { success: true,                 │
       │    registrationId: "..." }        │
       │◀──────────────────────────────────┤
       │                                   │
       ▼                                   ▼
```

---

## Component Hierarchy

```
IdentityVerificationScreen
│
├─ AppBar
│  ├─ Back button
│  ├─ Title: "Identity and Employment"
│  └─ Language selector
│
├─ Form
│  │
│  ├─ Header Card (gradient)
│  │  ├─ Title: "Identity Verification"
│  │  └─ Subtitle: "Collect ID for screening"
│  │
│  ├─ Identity Card
│  │  │
│  │  ├─ Section: Identity Details
│  │  │  ├─ Identity Type Dropdown
│  │  │  └─ ID Document Scanner ✨ NEW
│  │  │     │
│  │  │     ├─ Upload Prompt (if no image)
│  │  │     │  └─ Tap to scan/upload
│  │  │     │
│  │  │     ├─ Image Preview (if image selected)
│  │  │     │  ├─ Image display
│  │  │     │  └─ Remove button
│  │  │     │
│  │  │     ├─ OCR Status Area
│  │  │     │  ├─ Scanning indicator
│  │  │     │  ├─ Success message
│  │  │     │  ├─ Low confidence warning
│  │  │     │  └─ Failed error
│  │  │     │
│  │  │     ├─ Extracted ID Field (read-only)
│  │  │     │
│  │  │     ├─ Name Matching Card ✨ NEW
│  │  │     │  ├─ Status icon (✅/❌/ℹ️)
│  │  │     │  ├─ Name on ID
│  │  │     │  ├─ Name you entered
│  │  │     │  └─ Warning message (if mismatch)
│  │  │     │
│  │  │     └─ ID Availability Card ✨ NEW
│  │  │        ├─ Status icon (⏳/✅/❌)
│  │  │        ├─ Availability message
│  │  │        └─ Error message (if duplicate)
│  │  │
│  │  └─ Section: Employment Status
│  │     └─ Employment Dropdown
│  │
│  └─ Submit Button
│     └─ "Continue to Membership"
│        (Enabled/Disabled based on validation)
│
└─ BlocProvider
   └─ IdentityCubit
      ├─ State management
      ├─ OCR logic
      ├─ Name matching logic ✨ NEW
      └─ Duplicate check logic ✨ NEW
```

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INPUT                               │
│  Personal Info (Step 1): firstName, fatherName, lastName        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    REGISTRATION CUBIT                            │
│  Stores: registrationSnapshot { personalInfo, ... }             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                     IDENTITY CUBIT                               │
│                                                                  │
│  State:                                                          │
│  • idImageBytes: List<int>?                                     │
│  • identityNumber: String                                       │
│  • detectedName: String? ✨ NEW                                 │
│  • nameMatchStatus: IdNameMatchStatus ✨ NEW                    │
│  • idAvailabilityStatus: IdAvailabilityStatus ✨ NEW            │
│  • scanStatus: IdScanStatus                                     │
│  • employmentStatus: String                                     │
│                                                                  │
│  Methods:                                                        │
│  • pickIdImage() → Upload image                                 │
│  • _runOcr() → Extract ID & name                                │
│  • _compareNames() → Match names ✨ NEW                         │
│  • _checkIdAvailability() → Check duplicate ✨ NEW              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         UI WIDGETS                               │
│                                                                  │
│  • _IdDocumentScanner                                           │
│  • _NameMatchingCard ✨ NEW                                     │
│  • _IdAvailabilityCard ✨ NEW                                   │
│  • Submit Button (with validation)                              │
└─────────────────────────────────────────────────────────────────┘
```

---

**Last Updated**: 2026-04-29  
**Version**: 1.0.0
