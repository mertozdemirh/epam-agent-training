# Lead Capture Form — Solution Description

**Project:** EPAM Agent Training  
**Branch:** feature/lead-capture-form  
**Org:** resilient-unicorn-c7192x (Developer Edition)  
**Completed:** 2026-06-12

---

## Overview

A Lightning Web Component (`leadCaptureForm`) placed on the Account Lightning Record Page that allows users to capture Lead information directly from an Account context. All form processing is handled server-side via an Apex controller, with full validation, error handling, and security controls.

---

## Component Architecture

### LWC: `leadCaptureForm`
**Location:** `force-app/main/default/lwc/leadCaptureForm/`

| File | Purpose |
|---|---|
| `leadCaptureForm.html` | Template with all form fields and layout |
| `leadCaptureForm.js` | Controller: wire, validation, Apex callout, toast |
| `leadCaptureForm.js-meta.xml` | Metadata: exposed on `lightning__RecordPage` for Account |

**Key capabilities:**
- Receives `recordId` via `@api` from the record page context
- Uses `@wire getRecord` to auto-populate Company from Account Name on load
- Client-side validation before any Apex call:
  - Required fields: Last Name, Email, Company, Lead Source
  - Email format validation via regex
  - Notes max 500 character check
- Calls `LeadCaptureController.createLead()` via `@AuraEnabled`
- On success: shows toast with Lead name, resets form (Company stays populated)
- On error: shows sticky error toast with the failure reason

### Apex: `LeadCaptureController`
**Location:** `force-app/main/default/classes/`

- `with sharing` enforces org sharing rules
- Single `@AuraEnabled` method `createLead()` accepting all Lead fields
- Maps `notes` → `Capture_Notes__c` and `sourceAccountId` → `Source_Account__c`
- Error handling: `DmlException` and `Exception` are caught and re-thrown as `AuraHandledException`

### Apex Test: `LeadCaptureControllerTest`
- 5 test methods, **100% pass rate**
- Covers: success path, optional fields, source account linking, missing Last Name exception, missing Email scenario
- Uses `@TestSetup` for Account fixture data

### FlexiPage: `Account_Lead_Capture_Page`
**Location:** `force-app/main/default/flexipages/`

- Type: `RecordPage` for `Account` object
- Template: `flexipage:recordHomeTemplateDesktop`
- Activated as **Org Default** for Desktop
- `leadCaptureForm` placed in the main region

---

## Data Model

### Custom Fields on Lead

| API Name | Label | Type | Description |
|---|---|---|---|
| `Source_Account__c` | Source Account | Lookup(Account) | Links the Lead back to the Account it was captured from |
| `Capture_Notes__c` | Capture Notes | Long Text Area(500) | Notes entered via the capture form |

### Field Mapping (Form → Lead)

| Form Field | Lead Field |
|---|---|
| First Name | `FirstName` |
| Last Name | `LastName` |
| Email | `Email` |
| Phone | `Phone` |
| Company (auto from Account) | `Company` |
| Lead Source | `LeadSource` |
| Notes | `Capture_Notes__c` |
| Account recordId | `Source_Account__c` |

---

## Security Model

### Permission Set: `Lead_Capture_Access`
**Location:** `force-app/main/default/permissionsets/`

| Access Type | Target | Level |
|---|---|---|
| Object | Lead | Read, Create |
| Field | `Source_Account__c` | Read, Edit |
| Field | `Capture_Notes__c` | Read, Edit |
| Apex Class | `LeadCaptureController` | Enabled |

The permission set must be assigned to any user who needs to use the Lead Capture Form.

---

## Deployment Summary

All metadata deployed via `sf project deploy start` to `epam agent training` org:

| Component | Status |
|---|---|
| `Lead.Source_Account__c` custom field | ✅ Deployed |
| `Lead.Capture_Notes__c` custom field | ✅ Deployed |
| `LeadCaptureController` Apex class | ✅ Deployed |
| `LeadCaptureControllerTest` Apex class | ✅ Deployed (6/6 tests passing) |
| `leadCaptureForm` LWC | ✅ Deployed |
| `Lead_Capture_Access` Permission Set | ✅ Deployed & Assigned |
| `Account_Lead_Capture_Page` FlexiPage | ✅ Deployed & Activated as Org Default |

---

## Testing Results

| Test Scenario | Result |
|---|---|
| Form renders on Account record page | ✅ |
| Company auto-populates from Account Name | ✅ |
| Lead Source dropdown shows 4 options | ✅ |
| Valid submission creates Lead record | ✅ |
| Source_Account__c links to correct Account | ✅ |
| Capture_Notes__c stores notes | ✅ |
| Form resets after successful submission | ✅ |
| Required field validation (Last Name, Email, Lead Source) | ✅ |
| Email format validation | ✅ |
| Apex test coverage: 100% pass rate | ✅ |
