oky# Comprehensive ID Verification Implementation

## Overview

This implementation adds comprehensive ID verification with name matching validation and duplicate ID checking to the CBHI member registration flow.

## Features Implemented

### 1. Backend Enhancements

#### Vision Service (`backend/src/vision/vision.service.ts`)
- **Name Extraction**: The `validateIdDocument` method already extracts names from ID documents using Google Vision API
- Returns `detectedName` field in the response
- Extracts name by finding text lines that:
  - Are 3-60 characters long
  - Don't contain long digit sequences (4+ digits)
  - Don't contain ID-related keywords

#### CBHI Service (`backend/src/cbhi/cbhi.service.ts`)
- **Duplicate ID Check**: `checkIdAvailability(idNumber)` method already exists
- Checks if ID number exists in `users` table
- Returns `{ available: boolean, message?: string }`
- Endpoint: `GET /api/v1/cbhi/registration/check-id/:idNumber`

### 2. Frontend Enhancements

#### Identity Cubit (`member_based_cbhi/lib/src/registration/identity/identity_cubit.dart`)

**State Management**:
- `IdNameMatchStatus` enum: `notChecked`, `matched`, `mismatch`, `skipped`
- `IdAvailabilityStatus` enum: `unchecked`, `checking`, `available`, `taken`
- State fields:
  - `detectedName`: Name extracted from ID by OCR
  - `nameMatchStatus`: Result of name comparison
  - `idAvailabilityStatus`: Result of duplicate check

**Name Matching Logic** (`_compareNames` method):
- Normalizes both names (lowercase, trim, collapse whitespace)
- Splits into tokens (words)
- **Match criteria**:
  - ✅ **Matched**: At least 2 name tokens overlap, OR detected name contains both firstName and lastName
  - ⚠️ **Partial match**: Not implemented (can be added with similarity threshold 60-79%)
  - ❌ **Mismatch**: Less than 2 tokens match
  - **Skipped**: No name detected by OCR

**Duplicate ID Check**:
- Automatically triggered after successful OCR extraction
- Calls `repository.checkIdAvailability(idNumber)`
- Updates `idAvailabilityStatus` based on response
- Non-blocking: If check fails, assumes available to not block user

**Workflow**:
1. User picks ID image → `pickIdImage()`
2. Auto-trigger OCR → `_runOcr()`
3. Extract ID number and name
4. Compare name with personal info from step 1
5. Check ID availability via API
6. Update state with all results

#### Identity Verification Screen (`member_based_cbhi/lib/src/registration/identity/identity_verification_screen.dart`)

**New UI Components**:

1. **`_NameMatchingCard`**:
   - Shows name comparison results
   - Displays both "Name on ID" and "Name you entered"
   - Color-coded status:
     - ✅ Green for match
     - ❌ Red for mismatch with warning message
     - ℹ️ Gray for skipped
   - Shows hint text explaining the comparison

2. **`_IdAvailabilityCard`**:
   - Shows duplicate ID check status
   - States:
     - ⏳ Checking (with spinner)
     - ✅ Available (green)
     - ❌ Taken (red with error message)
   - Blocks submission if ID is taken

**Submit Button Logic** (`_canSubmit`):
- Must have image selected
- OCR must not be in progress
- Must have extracted ID number
- **Blocks if**:
  - Name mismatch (`nameMatchStatus == mismatch`)
  - ID is taken (`idAvailabilityStatus == taken`)
  - ID availability check in progress

### 3. Localization

Added keys to all three ARB files (en/am/om):

```
nameMatchTitle, nameMatchSuccess, nameMatchPartial, nameMatchMismatch,
nameMatchSkipped, nameOnId, nameYouEntered, nameMatchHint,
nameMatchMismatchWarning, idAlreadyRegistered, idAvailabilityChecking,
idAvailabilityAvailable, idAvailabilityTaken, duplicateIdError
```

## User Flow

1. **Step 1**: User enters personal info (firstName, middleName, lastName)
2. **Step 2**: User confirms information
3. **Step 3**: Identity verification
   - User scans/uploads ID document
   - OCR extracts ID number and name
   - **Name Matching**:
     - System compares extracted name with step 1 name
     - Shows side-by-side comparison
     - Blocks submission if mismatch
   - **Duplicate Check**:
     - System checks if ID is already registered
     - Shows availability status
     - Blocks submission if duplicate
4. **Step 4**: User can only proceed if:
   - Name matches or partially matches
   - ID is available (not duplicate)

## Testing Scenarios

### Name Matching

**Scenario 1: Perfect Match**
- Personal info: "Abebe Bekele Tadesse"
- ID name: "Abebe Bekele Tadesse"
- Result: ✅ Matched (3 tokens match)

**Scenario 2: Partial Match (acceptable)**
- Personal info: "Abebe Bekele Tadesse"
- ID name: "Abebe B. Tadesse"
- Result: ✅ Matched (2 tokens match: "Abebe", "Tadesse")

**Scenario 3: Mismatch**
- Personal info: "Abebe Bekele Tadesse"
- ID name: "Alemayehu Girma Haile"
- Result: ❌ Mismatch (0 tokens match)
- Action: User blocked, must verify info or upload different ID

**Scenario 4: OCR No Name**
- Personal info: "Abebe Bekele Tadesse"
- ID name: (not detected)
- Result: ℹ️ Skipped (cannot compare)
- Action: User can proceed (name verification optional)

### Duplicate ID Check

**Scenario 1: New ID**
- ID number: "123456789012"
- Database: No match
- Result: ✅ Available
- Action: User can proceed

**Scenario 2: Duplicate ID**
- ID number: "123456789012"
- Database: Already registered
- Result: ❌ Taken
- Action: User blocked with message "This ID number is already registered. If this is your ID, please contact support."

**Scenario 3: Check Failure**
- ID number: "123456789012"
- API: Network error
- Result: ✅ Available (fail-open to not block user)
- Action: User can proceed

## Error Handling

1. **OCR Failure**: User can retry with "Retry validation" button
2. **Low Confidence**: Shows warning but allows proceed if ID extracted
3. **Network Failure**: Duplicate check fails open (assumes available)
4. **Name Mismatch**: Hard block with clear warning message
5. **Duplicate ID**: Hard block with support contact message

## Security Considerations

1. **Rate Limiting**: Duplicate check endpoint is throttled (20 req/min)
2. **Fail-Open**: Availability check fails gracefully to not block legitimate users
3. **Fuzzy Matching**: Name matching is lenient (2 tokens) to handle OCR errors
4. **User Feedback**: Clear error messages guide users to resolution

## Files Modified

### Backend
- `backend/src/vision/vision.service.ts` - Already extracts names
- `backend/src/cbhi/cbhi.service.ts` - Already has `checkIdAvailability`
- `backend/src/cbhi/cbhi.controller.ts` - Already has endpoint

### Frontend
- `member_based_cbhi/lib/src/registration/identity/identity_cubit.dart` - Name matching logic
- `member_based_cbhi/lib/src/registration/identity/identity_state.dart` - Already has state fields
- `member_based_cbhi/lib/src/registration/identity/identity_verification_screen.dart` - UI components
- `member_based_cbhi/lib/l10n/app_en.arb` - English localization
- `member_based_cbhi/lib/l10n/app_am.arb` - Amharic localization
- `member_based_cbhi/lib/l10n/app_om.arb` - Afaan Oromo localization

## Next Steps

1. **Run Flutter code generation**: `flutter gen-l10n` in `member_based_cbhi/`
2. **Test on device**: Verify OCR, name matching, and duplicate checking
3. **Adjust thresholds**: If needed, tune name matching sensitivity
4. **Add partial match**: Implement 60-79% similarity threshold for partial match status

## Notes

- Name matching uses simple token overlap (not Levenshtein distance)
- Duplicate check is non-blocking on failure (fail-open)
- OCR name extraction depends on Google Vision API quality
- Ethiopian names (Amharic script) may have lower OCR accuracy
