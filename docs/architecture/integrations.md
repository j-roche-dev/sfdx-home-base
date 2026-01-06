# Integration Architecture

## Integration Landscape

```
                         +------------------+
                         |    SALESFORCE    |
                         +--------+---------+
                                  |
        +------------+------------+------------+------------+
        |            |            |            |            |
        v            v            v            v            v
   +--------+   +--------+   +--------+   +--------+   +--------+
   |  ERP   |   |  DW    |   |Marketing|  |  Auth  |   | Files  |
   | (REST) |   |(Events)|   |  (API)  |  | (SSO)  |   | (S3)   |
   +--------+   +--------+   +--------+   +--------+   +--------+
```

## Integration Inventory

| # | System | Direction | Method | Frequency | Status |
|---|--------|-----------|--------|-----------|--------|
| 1 | [ERP] | Bidirectional | REST API | Real-time | Active |
| 2 | [Data Warehouse] | Outbound | Platform Events | Real-time | Active |
| 3 | [Marketing] | Inbound | REST API | Batch (nightly) | Active |

---

## Integration Details

### 1. [ERP Integration]

| Attribute | Value |
|-----------|-------|
| External System | [SAP, Oracle, NetSuite, etc.] |
| Direction | Inbound / Outbound / Bidirectional |
| Method | REST API / SOAP / Platform Events / CDC |
| Authentication | OAuth 2.0 / Named Credential / API Key |
| Named Credential | `ERP_Integration` |
| Middleware | [MuleSoft, Dell Boomi, Direct, etc.] |
| Owner | [Team/Person responsible] |

**Endpoints**:
| Environment | URL |
|-------------|-----|
| Production | https://erp.company.com/api/v1 |
| Sandbox | https://erp-sandbox.company.com/api/v1 |

**Data Flow**:

```
Salesforce Account (After Update)
         |
         v
  AccountTrigger.cls
         |
         v
  ERPSyncService.cls
         |
         v
  Callout to ERP API
         |
         v
  ERP Customer Master updated
```

**Objects/Fields Synced**:
| Salesforce Object | SF Field | Direction | External Field |
|-------------------|----------|-----------|----------------|
| Account | Name | → | CustomerName |
| Account | ERP_ID__c | ← | CustomerId |
| Contact | Email | → | EmailAddress |

**Error Handling**:
- Retry policy: 3 attempts with exponential backoff
- Dead letter: `Integration_Error__c` custom object
- Alerting: Email to [integration-team@company.com]

**Key Apex Classes**:
| Class | Purpose |
|-------|---------|
| `ERPSyncService.cls` | Main integration service |
| `ERPCallout.cls` | HTTP callout wrapper |
| `ERPCalloutMock.cls` | Mock for testing |

**Known Issues**:
- [Document any known limitations or issues]

**Monitoring**:
- Dashboard: [link if exists]
- Log object: `Integration_Log__c`

---

### 2. [Next Integration...]

---

## Authentication & Credentials

### Named Credentials

| Name | Purpose | Endpoint | Auth Type | Certificate |
|------|---------|----------|-----------|-------------|
| `ERP_Prod` | ERP Production | https://erp.company.com | OAuth 2.0 | No |
| `ERP_Sandbox` | ERP Sandbox | https://erp-sb.company.com | OAuth 2.0 | No |

### Auth Providers

| Name | Type | Purpose |
|------|------|---------|
| | Google / SAML / OpenID | |

### Certificates

| Certificate Name | Purpose | Expiration |
|------------------|---------|------------|
| | | YYYY-MM-DD |

## Remote Site Settings

| Site Name | URL | Purpose |
|-----------|-----|---------|
| ERP_API | https://erp.company.com | ERP integration |

## Platform Events

| Event Name | Publisher | Subscribers | Volume (daily) |
|------------|-----------|-------------|----------------|
| `Order_Complete__e` | Apex Trigger | External DW | ~1,000 |

## Change Data Capture (CDC)

| Object | External Subscribers |
|--------|---------------------|
| Account | Data Lake |

## Outbound Messages (Legacy)

| Name | Object | Endpoint | Active |
|------|--------|----------|--------|
| | | | |

## API Usage

### Current Consumption
| Metric | Daily Average | Limit |
|--------|---------------|-------|
| API Requests | | |
| Bulk API | | |
| Streaming API | | |

### Heavy API Consumers
| Integration/User | Avg Calls/Day |
|------------------|---------------|
| | |

## Monitoring & Alerting

| Integration | Monitor Method | Alert Channel |
|-------------|----------------|---------------|
| ERP Sync | Custom Object | Email |
| | | |

## Troubleshooting Guide

### Common Issues

**Issue**: [Description]
**Symptoms**: [What you see]
**Resolution**: [How to fix]

---

## Notes

[Additional integration notes, planned changes, etc.]
