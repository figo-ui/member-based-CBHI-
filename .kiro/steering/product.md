# Maya City CBHI — Product Overview

Maya City CBHI (Community-Based Health Insurance) is a digital platform for managing health insurance enrollment, coverage, claims, and payments in an Ethiopian context.

## Applications

| App | Description |
|-----|-------------|
| `member_based_cbhi` | Flutter mobile/web app for household members — registration, coverage, payments, digital card, grievances |
| `cbhi_admin_desktop` | Flutter web app for CBHI officers and system admins — claims management, indigent approvals, reports, user management |
| `cbhi_facility_desktop` | Flutter web app for health facility staff — eligibility verification via QR scan, claim submission |
| `backend` | NestJS REST API serving all three apps |

## Domain Concepts

- **Household**: The primary enrollment unit; one head, multiple beneficiaries
- **Coverage**: Annual insurance coverage with statuses: `ACTIVE`, `PENDING_RENEWAL`, `WAITING_PERIOD`, `EXPIRED`, `SUSPENDED`, `REJECTED`, `INACTIVE`
- **Indigent**: Low-income members who qualify for subsidized or free coverage
- **Digital Card**: QR-code-based membership card used for facility eligibility checks
- **Claim**: Medical service claim submitted by a facility on behalf of a member
- **Grievance**: Member complaint or appeal against a claim or coverage decision

## Supported Languages

English (`en`), Amharic (`am`), Afaan Oromo (`om`)

## User Roles

`SYSTEM_ADMIN`, `CBHI_OFFICER`, `HOUSEHOLD_HEAD`, `BENEFICIARY`, `HEALTH_FACILITY_STAFF`
