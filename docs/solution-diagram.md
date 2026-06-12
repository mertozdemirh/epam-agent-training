# Solution Architecture Diagram

## Component Architecture

```mermaid
graph TD
    subgraph Salesforce Org
        subgraph Lightning Record Page
            FP[Account_Lead_Capture_Page<br/>FlexiPage]
            LWC[leadCaptureForm<br/>LWC Component]
            FP --> LWC
        end

        subgraph Apex Layer
            CTRL[LeadCaptureController<br/>@AuraEnabled]
            TEST[LeadCaptureControllerTest<br/>100% Pass Rate]
        end

        subgraph Data Layer
            ACC[Account Object<br/>recordId]
            LEAD[Lead Object]
            SRC[Source_Account__c<br/>Lookup to Account]
            NOTES[Capture_Notes__c<br/>Long Text Area 500]
            LEAD --> SRC
            LEAD --> NOTES
        end

        subgraph Security
            PS[Lead_Capture_Access<br/>Permission Set]
            PS -->|Read/Create| LEAD
            PS -->|FLS Read/Edit| SRC
            PS -->|FLS Read/Edit| NOTES
            PS -->|Enabled| CTRL
        end

        LWC -->|@wire getRecord| ACC
        LWC -->|@AuraEnabled callout| CTRL
        CTRL -->|insert| LEAD
        LEAD -->|Source_Account__c| ACC
    end

    USER([User on Account Page]) --> FP
```

## Data Flow Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant LWC as leadCaptureForm (LWC)
    participant APEX as LeadCaptureController (Apex)
    participant DB as Salesforce DB

    U->>LWC: Opens Account record page
    LWC->>DB: @wire getRecord (Account.Name)
    DB-->>LWC: Account Name → auto-fill Company

    U->>LWC: Fills form fields
    U->>LWC: Clicks Submit

    LWC->>LWC: Validate required fields
    LWC->>LWC: Validate email format

    alt Validation fails
        LWC-->>U: Show inline error messages
    else Validation passes
        LWC->>APEX: createLead(firstName, lastName, email,<br/>phone, company, leadSource, notes, sourceAccountId)
        APEX->>DB: insert Lead record

        alt Insert success
            DB-->>APEX: Lead.Id
            APEX-->>LWC: Lead.Id
            LWC-->>U: Success toast "Lead John Doe created successfully!"
            LWC->>LWC: Reset form (keep Company)
        else Insert failure
            DB-->>APEX: DmlException
            APEX-->>LWC: AuraHandledException
            LWC-->>U: Error toast with failure reason
        end
    end
```
