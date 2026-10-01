# Salesforce DX Project Wizard Steps for creating an Account with related records using LWC

A polished, production-ready **multi-step wizard** built with Lightning Web Components (LWC), demonstrating best practices in Salesforce development — from component architecture and inter-component communication to Apex integration and clean UX patterns.
---

## 📋 Purpose

This wizard guides users through a structured, three-step data-entry flow to create related Salesforce records — an **Account**, a **Contact**, and a **Preference** — in a single cohesive session. Rather than navigating across multiple pages or record forms, users progress through a guided experience with a final Review step before committing any data to the database.

The project serves as a **reference implementation** showcasing how to build complex, stateful, multi-screen flows in LWC without relying on Flow Builder, keeping full control over UX, validation logic, and data handling in code.

---

## 🗂️ Project Structure

```
┌─────────────────────────────────────────────────────────────┐
│                      wizardContainer                        │
│                                                             │
│   ┌────────┐    ┌────────┐    ┌────────────┐    ┌────────┐  │
│   │ Step 1 │ →  │ Step 2 │ →  │  Step 3    │ →  │ Review │  │
│   │Account │    │Contact │    │ Preference │    │        │  │
│   └────────┘    └────────┘    └────────────┘    └───┬────┘  │
│                                                     │       │
│                                                     ▼       │
│                                               Apex Call     │
│                                                     │       │
│                                                     ▼       │
│                                          Success / Error    │
│                                               Toast 🔔      │
└─────────────────────────────────────────────────────────────┘
```

```
force-app/main/default/
├── classes/
│   ├── WizardController.cls          # Apex controller (entry point)
│   └── WizardResult.cls              # DTO returned to the client
└── lwc/
├── wizardContainer/              # Orchestrator component
├── wizardStep1/                  # Step 1 – Account
├── wizardStep2/                  # Step 2 – Contact
├── wizardStep3/                  # Step 3 – Preference (with category picklist)
└── wizardReview/                 # Review & submit step
```

Declared with sharing to respect org-level sharing rules

Single @AuraEnabled method accepts structured maps, decoupled from SObject fields — allowing the client payload shape to evolve independently

Performs a unit-of-work pattern: inserts Account → Contact (with AccountId) → Preference (with ContactId) in order, with all-or-nothing rollback via a try/catch that populates the DTO error field

Returns a WizardResult DTO rather than raw SObjects, giving the client a clean, versioned contract

```
Data Transfer Object — WizardResult

public class WizardResult {
    @AuraEnabled public Boolean success;
    @AuraEnabled public String  message;
    @AuraEnabled public Id      accountId;
    @AuraEnabled public Id      contactId;
    @AuraEnabled public Id      preferenceId;
}
```
 I applied the following rules to this project:

| Practice | Where Applied |
| --- | --- |
| `with sharing` on Apex | `WizardController` — enforces record-level security |
| Single Apex callout per transaction | `wizardContainer` submits once; no per-step server calls |
| DTO pattern | `WizardResult` decouples server/client contracts |
| Unidirectional data flow | Parent-down props, child-up events; no sibling coupling |
| Client-side validation | Each step validates before firing `nextstep` |
| Bulkification-ready DML | Apex inserts are sequenced with proper ID chaining |
| Component isolation | Step components have zero direct Apex dependencies |
| LWC naming conventions | camelCase components, kebab-case in HTML templates |
| `@AuraEnabled(cacheable=false)` | Mutation method correctly marked non-cacheable |
