# Salesforce Project: [CLIENT_NAME]

> **Template Instructions**: Copy this file when starting a new engagement. Replace bracketed placeholders with actual values. Delete this instruction block when done.

## Quick Reference

| Field | Value |
|-------|-------|
| Engagement Start | YYYY-MM-DD |
| Primary Org ID | 00D... |
| API Version | 65.0 |
| Default Alias | `prod` |
| Source Control | [GitHub/Bitbucket URL] |

## Environment Summary

| Alias | Type | Org ID | Purpose | Last Refreshed |
|-------|------|--------|---------|----------------|
| `prod` | Production | 00D... | Live system | N/A |
| `dev-sb` | Developer | 00D... | Development | YYYY-MM-DD |
| `uat-sb` | Partial Copy | 00D... | UAT Testing | YYYY-MM-DD |

## Authentication

```bash
# Login to production
sf org login web --alias prod --instance-url https://login.salesforce.com

# Login to sandbox
sf org login web --alias dev-sb --instance-url https://test.salesforce.com

# List authenticated orgs
sf org list

# Set default org
sf config set target-org prod
```

## Key Commands

```bash
# Run discovery scripts
./scripts/discovery/retrieve-metadata.sh prod

# Full discovery with report
npm run discover:all prod

# Deploy to target org
sf project deploy start --target-org prod

# Retrieve metadata
sf project retrieve start --metadata "ApexClass,ApexTrigger" --target-org prod

# Run tests
sf apex run test --target-org prod --code-coverage --result-format human
```

---

## Project Architecture Overview

### Data Model Summary

> See: [docs/architecture/data-model.md](docs/architecture/data-model.md)

**Key Custom Objects:**
| Object | Purpose | Key Relationships |
|--------|---------|-------------------|
| `Custom_Object__c` | [description] | Account (Master-Detail) |

**Record Types to Know:**
- [Object]: [Record Type] - [purpose]

### Automation Landscape

> See: [docs/architecture/automation.md](docs/architecture/automation.md)

| Type | Count | Notes |
|------|-------|-------|
| Apex Triggers | | |
| Record-Triggered Flows | | |
| Screen Flows | | |
| Scheduled Flows | | |
| Process Builders (legacy) | | Consider migration |
| Workflow Rules (legacy) | | Consider migration |

**Critical Automations:**
- [Object] → [Trigger/Flow name]: [what it does]

### Integration Points

> See: [docs/architecture/integrations.md](docs/architecture/integrations.md)

| System | Direction | Method | Named Credential |
|--------|-----------|--------|------------------|
| [ERP] | Bidirectional | REST API | `ERP_Integration` |
| [Data Warehouse] | Outbound | Platform Events | N/A |

### Managed Packages

| Package | Namespace | Version | Purpose |
|---------|-----------|---------|---------|
| [Package Name] | [NS] | [X.X] | [purpose] |

### Security Model

> See: [docs/architecture/security-model.md](docs/architecture/security-model.md)

**Permission Model:** [Profiles / Permission Sets / Permission Set Groups]

**Key Permission Sets:**
- `[Permission_Set_Name]` - [purpose]

---

## Critical Knowledge

### Known Issues / Technical Debt

> See: [docs/tribal-knowledge/known-issues.md](docs/tribal-knowledge/known-issues.md)

| ID | Issue | Severity | Workaround |
|----|-------|----------|------------|
| ISSUE-001 | [description] | High/Med/Low | [workaround] |

### Deployment Notes

- **Branch Strategy**: [GitFlow / Trunk-based / other]
- **Required Approvals**: [process]
- **Deployment Window**: [if applicable]
- **Post-Deployment Steps**: [any manual steps required]

> See: [docs/processes/deployment.md](docs/processes/deployment.md)

### Key Contacts

| Role | Name | Email | Knows About |
|------|------|-------|-------------|
| SF Admin | | | User mgmt, reports, config |
| SF Developer | | | Apex, LWC, integrations |
| Business Owner | | | Process requirements |
| Integration Lead | | | External systems |

> See: [docs/tribal-knowledge/contacts.md](docs/tribal-knowledge/contacts.md)

---

## Code Conventions

### Apex Standards
- **Trigger Pattern**: [One trigger per object with handler class / Domain pattern / other]
- **Test Class Naming**: `[ClassName]Test.cls`
- **Minimum Coverage**: 85%
- **Naming**: PascalCase for classes, camelCase for methods/variables

### LWC Standards
- **Component Naming**: camelCase
- **Wire vs Imperative**: [guidance for this project]
- **CSS Framework**: [SLDS / custom]

### Metadata Organization
```
force-app/main/default/
├── classes/          # Apex classes
├── triggers/         # Apex triggers
├── lwc/              # Lightning Web Components
├── aura/             # Aura components (legacy)
├── objects/          # Custom objects and fields
├── flows/            # Flows
├── permissionsets/   # Permission sets
└── profiles/         # Profiles (minimize use)
```

---

## Discovery Status

### Completed
- [ ] Org authentication configured
- [ ] Discovery scripts executed
- [ ] Metadata inventory generated
- [ ] Data model documented
- [ ] Automation cataloged
- [ ] Integrations mapped
- [ ] Security model reviewed
- [ ] Deployment pipeline understood
- [ ] Key contacts identified
- [ ] Known issues documented

### Pending Investigation
- [ ] [Area needing investigation]

---

## Session Notes

### [YYYY-MM-DD] - Initial Discovery
**Attendees**: [names]
**Topics Covered**:
- [topic 1]
- [topic 2]

**Key Findings**:
- [finding 1]
- [finding 2]

**Action Items**:
- [ ] [action item]

---

### [YYYY-MM-DD] - [Session Title]
[Notes from subsequent sessions...]

---

*Generated from sfdxHomeBase template. Last updated: YYYY-MM-DD*
