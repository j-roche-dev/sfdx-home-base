# Org Relationships

## Org Landscape Diagram

```
                    +------------------+
                    |   PRODUCTION     |
                    |   (00D...xxx)    |
                    +--------+---------+
                             |
         +-------------------+-------------------+
         |                   |                   |
+--------v-------+  +--------v-------+  +--------v-------+
|     DEV        |  |      QA        |  |     UAT        |
|  (Developer)   |  | (Developer Pro)|  | (Partial Copy) |
+----------------+  +----------------+  +----------------+
         |
         v
    Development
     Workflow
```

## Deployment Path

```
DEV → QA → UAT → PRODUCTION
 │     │     │
 │     │     └── User acceptance sign-off required
 │     └── QA test pass required
 └── Code review required
```

## Org Communication

### Salesforce-to-Salesforce Connections

| Source Org | Target Org | Direction | Objects Shared |
|------------|------------|-----------|----------------|
| | | Inbound/Outbound | |

### Salesforce Connect (External Objects)

| Connection Name | External System | Objects |
|-----------------|-----------------|---------|
| | | |

### Cross-Org Data Sharing

| Method | Source | Target | Frequency |
|--------|--------|--------|-----------|
| Data Loader | Prod | Full Sandbox | On refresh |
| Integration | Prod | External DW | Real-time |

## Environment-Specific Configurations

### Things That Differ Between Orgs

| Configuration | Production | Sandbox (Default) |
|---------------|------------|-------------------|
| Email Deliverability | All email | System email only |
| Named Credentials | Prod endpoints | Test endpoints |
| Custom Settings | Production values | Test values |
| Debug Logs | Limited | Enabled |
| API Limits | Full allocation | Reduced |

### Configuration Management

**How environment-specific configs are handled:**

1. **Named Credentials**: Manual update post-refresh
2. **Custom Settings**: [Describe approach - data scripts, manual, etc.]
3. **Custom Metadata**: [Same across all orgs / varies]

## Multi-Org Considerations

### Managed Packages

| Package | Prod Version | Sandbox Version | Auto-upgrade? |
|---------|--------------|-----------------|---------------|
| | | | Yes/No |

### Sharing Data Between Orgs

| Use Case | Method | Frequency |
|----------|--------|-----------|
| | | |

## Notes

[Document any non-standard org relationships or configurations]
