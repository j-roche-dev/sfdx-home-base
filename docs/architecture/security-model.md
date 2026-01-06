# Security Model Documentation

## Security Model Overview

**Approach**: [Profile-based / Permission Set-based / Hybrid]

```
User
  └── Profile (baseline permissions)
        └── Permission Set Groups
              └── Permission Sets (additive)
                    └── Permission Set Licenses
```

---

## Profiles

### Standard Profiles in Use

| Profile | User Type | Approx Users | Notes |
|---------|-----------|--------------|-------|
| System Administrator | Admin | | Full access |
| Standard User | Sales | | Base sales access |
| [Custom Profile] | | | |

### Custom Profiles

| Profile Name | Based On | Purpose | Users |
|--------------|----------|---------|-------|
| | | | |

> **Best Practice**: Minimize custom profiles; use Permission Sets for granular access

---

## Permission Sets

### Permission Set Strategy

| Category | Naming Convention | Example |
|----------|-------------------|---------|
| Feature Access | `[Feature]_Access` | `CPQ_Access` |
| Object Access | `[Object]_[Level]` | `Account_Edit` |
| App Access | `[App]_User` | `ServiceConsole_User` |

### Permission Set Inventory

| Permission Set | Purpose | Assigned To |
|----------------|---------|-------------|
| `API_Integration_User` | API access for integrations | Integration users |
| `Report_Builder` | Create/edit reports | Power users |
| | | |

### Permission Set Groups

| Group Name | Included Permission Sets | Assigned To |
|------------|-------------------------|-------------|
| `Sales_User_Group` | Base_Access, Account_Edit, Opp_Edit | Sales users |
| | | |

---

## Object-Level Security

### Custom Object Access

| Object | Profile/PermSet | Read | Create | Edit | Delete |
|--------|-----------------|------|--------|------|--------|
| Custom_Object__c | Standard User | X | X | X | |
| Custom_Object__c | Sales_Manager | X | X | X | X |

---

## Field-Level Security

### Sensitive Fields

| Object | Field | Restricted To | Reason |
|--------|-------|---------------|--------|
| Contact | SSN__c | Admin, Compliance | PII |
| Account | Revenue__c | Sales Leadership | Confidential |

### Field Access Matrix

| Object.Field | Standard User | Manager | Admin |
|--------------|---------------|---------|-------|
| Account.AnnualRevenue | Read | Edit | Edit |
| | | | |

---

## Record-Level Security

### Organization-Wide Defaults (OWD)

| Object | Internal | External | Notes |
|--------|----------|----------|-------|
| Account | Private | Private | |
| Contact | Controlled by Parent | | |
| Opportunity | Private | | |
| Case | Private | | |
| [Custom_Object__c] | | | |

### Role Hierarchy

```
CEO
├── VP Sales
│   ├── Sales Director - East
│   │   └── Sales Reps
│   └── Sales Director - West
│       └── Sales Reps
├── VP Service
│   └── Service Managers
│       └── Service Agents
└── VP Operations
```

### Sharing Rules

| Object | Rule Name | Type | Share With | Access |
|--------|-----------|------|------------|--------|
| Account | Share_With_Partners | Criteria | Partner Role | Read |
| | | | | |

### Manual Sharing

| Object | Enabled | Common Use Case |
|--------|---------|-----------------|
| Account | Yes | Ad-hoc collaboration |
| | | |

### Apex Sharing (Programmatic)

| Object | Apex Class | Purpose |
|--------|------------|---------|
| | | |

### Teams

| Object | Team Type | Use Case |
|--------|-----------|----------|
| Account | Account Team | Sales collaboration |
| Opportunity | Opportunity Team | Deal teams |

---

## Public Groups

| Group Name | Type | Members | Used For |
|------------|------|---------|----------|
| All_Sales | Regular | Sales roles | Sharing rules |
| | | | |

## Queues

| Queue Name | Objects | Members | Purpose |
|------------|---------|---------|---------|
| Support_Queue | Case | Service Agents | Case routing |
| | | | |

---

## Login & Authentication

### Single Sign-On (SSO)

| Provider | Protocol | Users |
|----------|----------|-------|
| [Okta/Azure AD/etc.] | SAML 2.0 | All employees |

### Multi-Factor Authentication

| Setting | Value |
|---------|-------|
| MFA Required | [All Users / High Assurance Only] |
| Methods Allowed | [Salesforce Authenticator, TOTP, etc.] |

### Login Policies

| Profile | Login Hours | IP Restrictions |
|---------|-------------|-----------------|
| System Administrator | 24/7 | None |
| Standard User | Business hours | Office IPs only |

---

## Data Access Considerations

### Person Accounts

| Setting | Value |
|---------|-------|
| Person Accounts Enabled | Yes/No |
| Record Types | |

### Territory Management

| Status | Notes |
|--------|-------|
| Enabled/Disabled | |

### Experience Cloud (Community) Access

| Community | License | External Objects |
|-----------|---------|------------------|
| | | |

---

## Audit & Compliance

### Field History Tracking

| Object | Fields Tracked |
|--------|----------------|
| Account | Name, Owner, Type |
| Opportunity | Stage, Amount, CloseDate |

### Setup Audit Trail

- Retention: 180 days (standard)
- Extended retention: [Yes/No]

### Event Monitoring

| Enabled | Log Types |
|---------|-----------|
| Yes/No | Login, API, Report Export |

---

## Security Health Check

> Run Setup > Security > Health Check periodically

| Last Run | Score | Critical Issues |
|----------|-------|-----------------|
| YYYY-MM-DD | X/100 | |

---

## Notes

[Additional security considerations, planned changes, compliance requirements]
