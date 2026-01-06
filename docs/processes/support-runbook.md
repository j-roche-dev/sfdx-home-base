# Support Runbook

## Common Issues & Resolutions

### Quick Reference

| Symptom | Likely Cause | Quick Fix |
|---------|--------------|-----------|
| User can't log in | SSO issue / Frozen user | Check login history, unfreeze |
| Record won't save | Validation rule | Check error message, adjust data |
| Integration failing | Named Credential expired | Re-authenticate Named Credential |
| Report shows wrong data | Filter/sharing issue | Check report filters, user access |
| Flow error | Unhandled scenario | Check flow debug logs |

---

## User Access Issues

### Issue: User Cannot Log In

**Symptoms**: User gets "authentication failed" or is redirected unexpectedly

**Diagnostic Steps**:
1. Check Setup > Users > [User] > Login History
2. Verify user status is Active (not Frozen)
3. Check if password is expired
4. Verify SSO configuration (if applicable)

**Resolution Options**:
| Cause | Fix |
|-------|-----|
| Frozen user | Setup > Users > [User] > Unfreeze |
| Password expired | Reset password |
| SSO issue | Check identity provider, SAML assertions |
| IP restriction | Check profile login IP ranges |

---

### Issue: User Missing Record Access

**Symptoms**: User can't see records they should have access to

**Diagnostic Steps**:
1. Run sharing hierarchy debug
2. Check user's role in hierarchy
3. Verify OWD for the object
4. Check sharing rules

```
Setup > Sharing Settings > [Object] > Sharing Hierarchy
```

**Resolution Options**:
| Cause | Fix |
|-------|-----|
| Role too low | Adjust role or sharing rule |
| Manual share removed | Re-add manual share |
| Record owner changed | Update owner or add sharing |

---

### Issue: User Missing Field/Button

**Symptoms**: User can't see a field or button that others see

**Diagnostic Steps**:
1. Check page layout assignment
2. Check field-level security
3. Check Lightning page assignment
4. Verify record type

**Resolution Options**:
| Cause | Fix |
|-------|-----|
| Page layout | Assign correct layout to profile |
| FLS | Grant field access via permission set |
| Lightning page | Check app/record type assignment |

---

## Data Issues

### Issue: Record Won't Save (Validation Error)

**Symptoms**: Error message when trying to save a record

**Diagnostic Steps**:
1. Read the error message carefully
2. Identify which validation rule fired
3. Check the rule's criteria

**Resolution Options**:
| Cause | Fix |
|-------|-----|
| Missing required field | Populate the field |
| Invalid data format | Correct the data |
| Business rule violation | Follow business process or request exception |

**Common Validation Rules**:
| Rule | Object | Criteria | Resolution |
|------|--------|----------|------------|
| [Rule name] | [Object] | [When it fires] | [How to resolve] |

---

### Issue: Data Doesn't Match Report

**Symptoms**: User sees different data than a report shows

**Diagnostic Steps**:
1. Check report filters
2. Verify user's access to records
3. Check report date range
4. Verify formula field calculations

**Resolution Options**:
- Adjust report filters
- Run report as user to see their view
- Check sharing model impact on reports

---

### Issue: Duplicate Records Created

**Symptoms**: Multiple records for the same entity

**Diagnostic Steps**:
1. Check duplicate rules (Setup > Duplicate Rules)
2. Review integration logs for duplicate sends
3. Check for multiple automation paths

**Resolution Options**:
| Cause | Fix |
|-------|-----|
| Duplicate rules disabled | Enable appropriate rules |
| Integration sending duplicates | Fix integration logic |
| Manual user error | Merge duplicates, train users |

---

## Integration Issues

### Issue: Integration Failing

**Symptoms**: Data not syncing, errors in integration logs

**Diagnostic Steps**:
1. Check `Integration_Log__c` or `Integration_Error__c` for errors
2. Verify Named Credential is authenticated
3. Check external system availability
4. Review Apex debug logs

```bash
# Query recent integration errors
sf data query --query "SELECT Id, Error_Message__c, CreatedDate FROM Integration_Error__c ORDER BY CreatedDate DESC LIMIT 10" --target-org prod
```

**Resolution Options**:
| Cause | Fix |
|-------|-----|
| Auth expired | Re-authenticate Named Credential |
| External system down | Wait for system recovery, retry |
| Data validation failure | Fix source data |
| API limit exceeded | Wait for reset, optimize calls |

---

### Issue: Callout Timeout

**Symptoms**: "Read timed out" or "Connection timeout" errors

**Resolution Options**:
- Retry the operation (often succeeds)
- If persistent, check external system performance
- Consider increasing timeout (if configurable)
- Break large requests into smaller batches

---

## Automation Issues

### Issue: Flow Error

**Symptoms**: User sees flow error screen, records not updated

**Diagnostic Steps**:
1. Check Setup > Flows > [Flow] > Debug
2. Review error message in flow fault path
3. Check Apex debug logs if flow calls Apex

**Common Flow Errors**:
| Error | Cause | Fix |
|-------|-------|-----|
| "FIELD_CUSTOM_VALIDATION_EXCEPTION" | Validation rule | Fix data or adjust rule |
| "REQUIRED_FIELD_MISSING" | Missing required field | Ensure flow populates field |
| "INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY" | Missing access to related record | Check user permissions |

---

### Issue: Trigger Not Firing

**Symptoms**: Expected automation didn't run

**Diagnostic Steps**:
1. Verify trigger is active
2. Check if bypass is enabled (Custom Setting)
3. Verify DML operation type matches trigger events
4. Check Apex debug logs

**Resolution Options**:
| Cause | Fix |
|-------|-----|
| Trigger inactive | Activate in Setup > Apex Triggers |
| Bypass enabled | Disable `Bypass_Automation__c` setting |
| Wrong event type | Check trigger events (insert/update/delete) |

---

## Performance Issues

### Issue: Page Loading Slowly

**Symptoms**: Lightning page takes long to load

**Diagnostic Steps**:
1. Check Lightning Usage App for performance metrics
2. Review components on the page
3. Check for inefficient SOQL in controllers
4. Verify no excessive wire calls

**Resolution Options**:
- Remove unnecessary components
- Optimize Apex/SOQL
- Enable caching where appropriate
- Contact developer for investigation

---

### Issue: Report Running Slowly

**Symptoms**: Report times out or takes minutes to load

**Diagnostic Steps**:
1. Check report row count
2. Review filter criteria
3. Check for cross-filters or buckets
4. Verify indexed fields are used in filters

**Resolution Options**:
- Add more filters to reduce row count
- Use indexed fields in primary filters
- Consider report snapshot for historical data
- Break into multiple smaller reports

---

## Escalation Procedures

### Severity Levels

| Level | Definition | Response Time | Examples |
|-------|------------|---------------|----------|
| P1 | System down, no workaround | Immediate | Can't login, all integrations failing |
| P2 | Major impact, workaround exists | 4 hours | Key feature broken, data issues |
| P3 | Minor impact | 1 business day | UI issues, non-critical bugs |
| P4 | Enhancement request | Backlog | New feature requests |

### Escalation Path

1. **Tier 1**: SF Admin - Basic troubleshooting
2. **Tier 2**: SF Developer - Technical investigation
3. **Tier 3**: SF Architect/Vendor - Complex issues
4. **Salesforce Support**: Platform issues, case submission

### Creating a Salesforce Support Case

1. Go to [Salesforce Help](https://help.salesforce.com)
2. Log in with your Trailblazer account
3. Click "Contact Support"
4. Provide:
   - Org ID
   - Detailed description
   - Steps to reproduce
   - Error messages/screenshots
   - Business impact

---

## Monitoring & Health Checks

### Daily Checks

- [ ] Review integration error logs
- [ ] Check scheduled job status
- [ ] Monitor API usage
- [ ] Review critical report dashboards

### Weekly Checks

- [ ] Review Setup Audit Trail
- [ ] Check debug log storage
- [ ] Monitor data storage usage
- [ ] Review user login activity

### Monthly Checks

- [ ] Run Security Health Check
- [ ] Review inactive users
- [ ] Check license utilization
- [ ] Review org limits

---

## Useful Queries

### Recent Errors
```sql
SELECT Id, Name, Error_Message__c, CreatedDate
FROM Integration_Error__c
WHERE CreatedDate = LAST_N_DAYS:7
ORDER BY CreatedDate DESC
```

### User Login History
```sql
SELECT UserId, LoginTime, Status, SourceIp
FROM LoginHistory
WHERE UserId = '[user_id]'
ORDER BY LoginTime DESC
LIMIT 20
```

### Scheduled Jobs
```sql
SELECT Id, CronJobDetail.Name, State, NextFireTime
FROM CronTrigger
WHERE State = 'WAITING'
```

---

## Contact Information

See [contacts.md](../tribal-knowledge/contacts.md) for full contact list.

| Issue Type | Primary Contact |
|------------|-----------------|
| User access | SF Admin |
| Integration | Integration Lead |
| Business process | Business Analyst |
| Technical/code | SF Developer |

---

## Notes

[Additional runbook entries specific to this org]
