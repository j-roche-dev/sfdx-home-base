# Automation Documentation

## Automation Overview

| Type | Count | Status |
|------|-------|--------|
| Apex Triggers | | Active |
| Record-Triggered Flows | | Active |
| Screen Flows | | Active |
| Scheduled Flows | | Active |
| Platform Event Flows | | Active |
| Process Builders | | Legacy - migrate |
| Workflow Rules | | Legacy - migrate |

## Order of Execution Reference

For each object, automation executes in this order:
1. Before Triggers
2. Validation Rules
3. After Triggers
4. Assignment Rules
5. Auto-response Rules
6. Workflow Rules
7. Processes (Process Builder)
8. Flows (Record-Triggered)
9. Escalation Rules
10. Roll-up Summary Fields

---

## Automation by Object

### Account

| Type | Name | Purpose | Active |
|------|------|---------|--------|
| Trigger | AccountTrigger | [Handler dispatch] | Yes |
| Flow | Account_Update_Flow | [purpose] | Yes |
| Process Builder | Account_Process | [purpose] | Yes - MIGRATE |

**Trigger Details**:
- Handler: `AccountTriggerHandler.cls`
- Events: Before Insert, Before Update, After Insert, After Update

**Known Conflicts/Issues**: [None / describe]

---

### Contact

| Type | Name | Purpose | Active |
|------|------|---------|--------|
| Trigger | ContactTrigger | | Yes |

---

### Opportunity

| Type | Name | Purpose | Active |
|------|------|---------|--------|
| Trigger | OpportunityTrigger | | Yes |
| Flow | Opp_Stage_Update | | Yes |

---

### [Custom Object]

| Type | Name | Purpose | Active |
|------|------|---------|--------|

---

## Apex Triggers

### Trigger Framework

**Pattern Used**: [Trigger Handler / Domain Layer / Ad-hoc / None]

**Framework Classes**:
| Class | Purpose |
|-------|---------|
| `TriggerHandler.cls` | Base handler class |
| `TriggerDispatcher.cls` | Routing logic |

### Trigger Inventory

| Trigger | Object | Events | Handler Class | Notes |
|---------|--------|--------|---------------|-------|
| AccountTrigger | Account | BI, BU, AI, AU | AccountTriggerHandler | |
| ContactTrigger | Contact | AI, AU | ContactTriggerHandler | |

**Event Key**: BI=Before Insert, AI=After Insert, BU=Before Update, AU=After Update, BD=Before Delete, AD=After Delete, AUD=After Undelete

---

## Flows

### Record-Triggered Flows

| Flow Name | Object | Trigger | Runs | Purpose |
|-----------|--------|---------|------|---------|
| | Account | After Create | Async | |
| | Opportunity | Before Save | Sync | |

### Screen Flows

| Flow Name | Launch From | Purpose |
|-----------|-------------|---------|
| | Quick Action | |
| | Lightning Page | |

### Scheduled Flows

| Flow Name | Schedule | Purpose | Last Run |
|-----------|----------|---------|----------|
| | Daily 2am | | |

### Platform Event Flows

| Flow Name | Event | Purpose |
|-----------|-------|---------|
| | Platform_Event__e | |

---

## Process Builders (Legacy)

> **Migration Status**: These should be migrated to Flows

| Process Name | Object | Criteria | Actions | Migration Priority |
|--------------|--------|----------|---------|-------------------|
| | | | | High/Medium/Low |

---

## Workflow Rules (Legacy)

> **Migration Status**: These should be migrated to Flows

| Rule Name | Object | Criteria | Actions | Migration Priority |
|-----------|--------|----------|---------|-------------------|
| | | | | High/Medium/Low |

---

## Scheduled Apex

| Class Name | Schedule | Purpose | Active |
|------------|----------|---------|--------|
| BatchCleanup | Daily 1am | Archive old records | Yes |
| | | | |

## Batch Apex

| Class Name | Scope | Purpose | Typical Run Time |
|------------|-------|---------|------------------|
| | | | |

## Queueable Apex

| Class Name | Chained? | Purpose |
|------------|----------|---------|
| | Yes/No | |

---

## Automation Conflicts & Dependencies

### Known Conflicts

| Object | Conflict | Impact | Resolution |
|--------|----------|--------|------------|
| | Trigger + Flow both update same field | | |

### Execution Dependencies

| Automation | Depends On | Notes |
|------------|------------|-------|
| | | |

---

## Best Practices for This Org

1. **New triggers**: Use [framework pattern]
2. **New automation**: Prefer [Flows / Apex] for [reason]
3. **Bypass mechanism**: Use `Bypass_Automation__c` custom setting

## Notes

[Additional automation notes, planned changes, tech debt items]
