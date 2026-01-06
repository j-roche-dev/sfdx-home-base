# Sandbox Inventory

## Sandbox Overview

| Name | Type | Source | Purpose | Refresh Cadence | Last Refresh | Owner |
|------|------|--------|---------|-----------------|--------------|-------|
| DEV | Developer | Production | Development | On-demand | YYYY-MM-DD | Dev Team |
| QA | Developer Pro | Production | QA Testing | Weekly | YYYY-MM-DD | QA Team |
| UAT | Partial Copy | Production | User Acceptance | Monthly | YYYY-MM-DD | BA Team |
| STG | Full Copy | Production | Pre-Prod | Quarterly | YYYY-MM-DD | DevOps |

## Sandbox Types Reference

| Type | Data | Storage | Refresh Interval |
|------|------|---------|------------------|
| Developer | Config only | 200 MB | 1 day |
| Developer Pro | Config only | 1 GB | 1 day |
| Partial Copy | Config + sample | 5 GB | 5 days |
| Full Copy | Full data copy | Same as prod | 29 days |

---

## Sandbox Details

### DEV Sandbox

| Field | Value |
|-------|-------|
| Alias | `dev-sb` |
| Org ID | 00D... |
| Login URL | https://[company]--dev.sandbox.my.salesforce.com |
| Username Suffix | `.dev` |

**Purpose**: Primary development environment

**Primary Users**:
- Developer 1
- Developer 2

**Post-Refresh Configuration**:
- [ ] Update Named Credentials to dev endpoints
- [ ] Disable outbound email deliverability
- [ ] Run `scripts/post-refresh/dev-setup.apex` (if exists)
- [ ] Reset test user passwords

**Integration Endpoints**:
| Integration | Sandbox Endpoint |
|-------------|------------------|
| ERP | https://erp-dev.example.com |

---

### QA Sandbox

| Field | Value |
|-------|-------|
| Alias | `qa-sb` |
| Org ID | 00D... |
| Login URL | https://[company]--qa.sandbox.my.salesforce.com |
| Username Suffix | `.qa` |

**Purpose**: QA and regression testing

**Primary Users**:
- QA Lead
- QA Testers

**Post-Refresh Configuration**:
- [ ] [Steps specific to this sandbox]

---

### UAT Sandbox

| Field | Value |
|-------|-------|
| Alias | `uat-sb` |
| Org ID | 00D... |
| Login URL | https://[company]--uat.sandbox.my.salesforce.com |
| Username Suffix | `.uat` |

**Purpose**: User acceptance testing before production deployment

**Primary Users**:
- Business Analysts
- Power Users
- Stakeholders

**Post-Refresh Configuration**:
- [ ] [Steps specific to this sandbox]

---

## Refresh Procedures

### Pre-Refresh Checklist

- [ ] Notify all sandbox users at least 24 hours in advance
- [ ] Confirm no active development/testing in progress
- [ ] Export any work-in-progress that hasn't been committed
- [ ] Document post-refresh configuration requirements
- [ ] Review Apex jobs - pause any that shouldn't run on refresh

### Refresh Process

1. Navigate to Setup > Sandboxes
2. Click "Refresh" next to the sandbox
3. Select sandbox template (if using Partial Copy)
4. Confirm refresh

### Post-Refresh Standard Tasks

| Task | DEV | QA | UAT | STG |
|------|-----|-----|-----|-----|
| Update Named Credentials | X | X | X | X |
| Disable email deliverability | X | X | | |
| Reset test passwords | X | X | X | |
| Run data setup scripts | X | | | |
| Notify users | X | X | X | X |
| Deploy pending changes | X | | | |
| Verify integrations | X | X | X | X |

### Sandbox Templates (Partial Copy)

| Template Name | Objects Included | Record Limits |
|---------------|------------------|---------------|
| [Template 1] | Account, Contact, Opportunity | 10,000 each |

## Notes

[Any additional sandbox-specific information or procedures]
