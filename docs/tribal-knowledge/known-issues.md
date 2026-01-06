# Known Issues & Technical Debt Registry

## Summary

| Severity | Open | In Progress | Resolved |
|----------|------|-------------|----------|
| Critical | 0 | 0 | 0 |
| High | 0 | 0 | 0 |
| Medium | 0 | 0 | 0 |
| Low | 0 | 0 | 0 |

---

## Critical Issues

### ISSUE-001: [Brief Title]

| Attribute | Value |
|-----------|-------|
| ID | ISSUE-001 |
| Severity | Critical |
| Status | Open / In Progress / Workaround / Resolved |
| Affected Area | [Object/Feature/Integration] |
| Discovered | YYYY-MM-DD |
| Discovered By | [Name] |
| Owner | [Person/Team responsible for fix] |
| Related Ticket | [JIRA/Case number if applicable] |

**Description**:
[Detailed description of the issue - what's broken, when it occurs]

**Impact**:
- Business impact: [What business processes are affected]
- User impact: [How many users, what they experience]
- Data impact: [Any data integrity concerns]

**Root Cause**:
[If known - technical explanation of why this happens]

**Reproduction Steps**:
1. [Step 1]
2. [Step 2]
3. [Expected vs Actual result]

**Workaround**:
[Current workaround, if any - how users are coping]

**Resolution Plan**:
- Planned fix: [Description]
- Dependencies: [What needs to happen first]
- Estimated effort: [T-shirt size: S/M/L/XL]

**Resolution Notes** (once fixed):
- Fixed date: YYYY-MM-DD
- Fixed by: [Name]
- Solution: [What was done]

---

## High Priority Issues

### ISSUE-002: [Title]

[Use same template as above]

---

## Medium Priority Issues

### ISSUE-003: [Title]

---

## Low Priority Issues

### ISSUE-004: [Title]

---

## Technical Debt Items

> Items that aren't broken but should be improved

### DEBT-001: Legacy Process Builders Need Migration

| Attribute | Value |
|-----------|-------|
| Priority | Medium |
| Effort | Large (40+ hours) |
| Impact Area | Performance, Maintainability |
| Owner | [TBD] |

**Description**:
[X] active Process Builders should be migrated to Record-Triggered Flows per Salesforce best practices and Winter '25 retirement.

**Affected Components**:
| Process Name | Object | Complexity |
|--------------|--------|------------|
| Account_Update_Process | Account | Medium |
| Opp_Stage_Handler | Opportunity | High |

**Migration Notes**:
[Any gotchas discovered during analysis]

**Migration Priority Order**:
1. [Process with highest impact]
2. [Next]

---

### DEBT-002: [Title]

---

## Deprecated Components

> Components marked for removal - DO NOT USE in new development

| Component | Type | Reason | Replacement | Remove After |
|-----------|------|--------|-------------|--------------|
| `OldHelper.cls` | Apex Class | Legacy | `NewService.cls` | Q1 2025 |
| `Old_Flow` | Flow | Replaced | `New_Flow_v2` | [date] |
| `Legacy_Field__c` | Field | Unused | [none] | [date] |

---

## Configuration Quirks

> Non-obvious configurations that might confuse developers

### 1. Validation Rule Exception for Testing

**Object**: Account
**Rule**: `Industry_Required`
**Quirk**: This rule is deactivated in DEV sandbox for data loading but MUST be active in all other environments including production.
**Why**: Historical data loads require bypassing this rule.

### 2. Custom Setting Override

**Setting**: `Integration_Settings__c.Bypass_Validation__c`
**Quirk**: This setting exists to bypass validation rules during data migrations. NEVER leave this enabled after a migration.
**Who Can Change**: System Administrators only

### 3. [Next quirk...]

---

## Recently Resolved

> Keep recent resolutions for reference

### RESOLVED-001: [Title]

- **Resolved Date**: YYYY-MM-DD
- **Original Issue**: [Brief description]
- **Solution**: [What was done]
- **Lessons Learned**: [Any takeaways]

---

## Notes

[Additional context about the technical debt situation, planned cleanup initiatives, etc.]
