# Specification: Lead Capture Form
**Project:** EPAM Agent Training  
**Branch:** feature/lead-capture-form  
**Date:** 2026-06-12  
**Status:** Approved

---

## 1. Overview

Build a Lightning Web Component (`leadCaptureForm`) placed on the Account Lightning Record Page that allows users to capture Lead information directly from an Account context. All Lead creation is handled server-side via an Apex controller.

---

## 2. Component: `leadCaptureForm`

### 2.1 Placement
- Deployed on the **Account Lightning Record Page** (FlexiPage)
- Receives the Account `recordId` via `@api recordId`

### 2.2 Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| First Name | Text | No | |
| Last Name | Text | Yes | |
| Email | Email | Yes | Must pass email format validation |
| Phone | Phone | No | |
| Company | Text | Yes | Auto-populated from parent Account Name |
| Lead Source | Picklist | Yes | Values: Web, Phone Inquiry, Partner Referral, Other |
| Notes | Text Area | No | Max 500 characters |

### 2.3 Behavior

- **On load:** Auto-populate `Company` from the parent Account Name using `@wire getRecord`
- **On submit:**
  1. Validate all required fields (Last Name, Email, Company, Lead Source)
  2. Validate email format with regex
  3. Validate Notes ≤ 500 characters
  4. Call Apex controller `LeadCaptureController.createLead()`
- **On success:** Show success toast — `"Lead [First] [Last] created successfully"` — then clear the form
- **On error:** Show error toast with the failure reason from the Apex exception

### 2.4 Component Structure
```
force-app/main/default/lwc/leadCaptureForm/
├── leadCaptureForm.html
├── leadCaptureForm.js
├── leadCaptureForm.js-meta.xml
└── leadCaptureForm.css  (optional)
```

---

## 3. Apex Controller: `LeadCaptureController`

### 3.1 Method Signature
```apex
@AuraEnabled
public static Id createLead(
    String firstName,
    String lastName,
    String email,
    String phone,
    String company,
    String leadSource,
    String notes,
    Id sourceAccountId
)
```

### 3.2 Requirements
- `@AuraEnabled(cacheable=false)` — write operation
- Bulkification-ready structure (single record insert but wrapped for extensibility)
- Proper try/catch — throw `AuraHandledException` on failure
- Map `notes` → `Capture_Notes__c`
- Map `sourceAccountId` → `Source_Account__c`

---

## 4. Apex Test Class: `LeadCaptureControllerTest`

- Minimum **90% code coverage**
- Test cases:
  - `testCreateLead_success` — valid data, assert Lead inserted with correct field values
  - `testCreateLead_missingLastName` — expect exception
  - `testCreateLead_missingEmail` — expect exception
  - `testCreateLead_sourceAccount` — assert `Source_Account__c` populated

---

## 5. Data Model

### 5.1 Custom Fields on Lead Object

| API Name | Label | Type | Notes |
|---|---|---|---|
| `Source_Account__c` | Source Account | Lookup(Account) | Links Lead to originating Account |
| `Capture_Notes__c` | Capture Notes | Long Text Area(500) | Notes from capture form |

### 5.2 Metadata Files
```
force-app/main/default/objects/Lead/fields/Source_Account__c.field-meta.xml
force-app/main/default/objects/Lead/fields/Capture_Notes__c.field-meta.xml
```

---

## 6. Security: Permission Set `Lead_Capture_Access`

| Access Type | Target |
|---|---|
| Object: Lead | Read, Create |
| FLS: `Source_Account__c` | Read, Edit |
| FLS: `Capture_Notes__c` | Read, Edit |
| Apex Class: `LeadCaptureController` | Enabled |

### 6.1 Metadata File
```
force-app/main/default/permissionsets/Lead_Capture_Access.permissionset-meta.xml
```

---

## 7. FlexiPage

- Update or create `Account_Record_Page.flexipage-meta.xml`
- Add `leadCaptureForm` component to the layout

---

## 8. Folder Structure (Final Deliverables)

```
/specs/
  lead-capture-form-spec.md          ← this file

/docs/
  solution.md                        ← architecture description
  solution-diagram.md                ← Mermaid diagram

force-app/main/default/
  objects/Lead/fields/
    Source_Account__c.field-meta.xml
    Capture_Notes__c.field-meta.xml
  permissionsets/
    Lead_Capture_Access.permissionset-meta.xml
  classes/
    LeadCaptureController.cls
    LeadCaptureController.cls-meta.xml
    LeadCaptureControllerTest.cls
    LeadCaptureControllerTest.cls-meta.xml
  lwc/leadCaptureForm/
    leadCaptureForm.html
    leadCaptureForm.js
    leadCaptureForm.js-meta.xml
  flexipages/
    Account_Record_Page.flexipage-meta.xml
```

---

## 9. Acceptance Criteria

- [ ] Form renders on Account record page
- [ ] Company auto-populates from Account Name
- [ ] Required field validation works client-side before Apex call
- [ ] Email format validation works
- [ ] Successful submission creates a Lead record with all fields populated
- [ ] `Source_Account__c` links back to the Account
- [ ] `Capture_Notes__c` stores the notes
- [ ] Success toast shows Lead name and form clears
- [ ] Error toast shows failure reason
- [ ] Apex test class achieves ≥ 90% coverage
- [ ] Permission set deployed and grants correct access
