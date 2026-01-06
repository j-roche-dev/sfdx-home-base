# Deployment & Change Management

## Deployment Overview

| Attribute | Value |
|-----------|-------|
| Source Control | [GitHub/Bitbucket/Azure DevOps] |
| CI/CD Tool | [GitHub Actions/Jenkins/CircleCI/None] |
| Deployment Method | [SFDX/Change Sets/Copado/Gearset] |
| Branch Strategy | [GitFlow/Trunk-based/Feature branches] |

---

## Environment Flow

```
Feature Branch → DEV → QA → UAT → PRODUCTION
       │          │      │     │        │
       │          │      │     │        └── Production deployment
       │          │      │     └── User acceptance testing
       │          │      └── QA testing
       │          └── Development/integration testing
       └── Developer sandbox testing
```

---

## Branch Strategy

### Branch Naming

| Branch Type | Pattern | Example |
|-------------|---------|---------|
| Feature | `feature/[ticket]-description` | `feature/SF-123-add-validation` |
| Bug Fix | `bugfix/[ticket]-description` | `bugfix/SF-456-fix-null-error` |
| Hotfix | `hotfix/[ticket]-description` | `hotfix/SF-789-critical-fix` |
| Release | `release/[version]` | `release/2024.01` |

### Protected Branches

| Branch | Protection Rules |
|--------|------------------|
| `main` | Require PR, require approvals, no direct push |
| `develop` | Require PR |

---

## Deployment Process

### Standard Deployment (Feature/Bug Fix)

#### 1. Development Phase

```bash
# Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/SF-123-description

# Make changes, test locally
sf project deploy start --target-org dev-sb --dry-run
sf project deploy start --target-org dev-sb

# Commit and push
git add .
git commit -m "SF-123: Description of changes"
git push origin feature/SF-123-description
```

#### 2. Code Review

- [ ] Create Pull Request to `develop`
- [ ] Assign reviewer(s): [Names/Team]
- [ ] Pass automated checks (if configured)
- [ ] Obtain approval

#### 3. QA Deployment

```bash
# Merge to develop (or deploy from feature branch to QA)
sf project deploy start --target-org qa-sb
```

- [ ] QA team tests changes
- [ ] QA sign-off obtained

#### 4. UAT Deployment

```bash
sf project deploy start --target-org uat-sb
```

- [ ] Business stakeholders test
- [ ] UAT sign-off obtained
- [ ] Document any training needed

#### 5. Production Deployment

```bash
# Final deployment
sf project deploy start --target-org prod --dry-run
sf project deploy start --target-org prod
```

- [ ] Deployment window confirmed
- [ ] Stakeholders notified
- [ ] Post-deployment verification
- [ ] Update documentation

---

### Hotfix Process

For critical production issues:

```bash
# Branch from main/production
git checkout main
git pull origin main
git checkout -b hotfix/SF-789-critical-fix

# Make fix, test
sf project deploy start --target-org prod --dry-run

# Deploy to production
sf project deploy start --target-org prod

# Merge back
git checkout main
git merge hotfix/SF-789-critical-fix
git checkout develop
git merge hotfix/SF-789-critical-fix
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] All tests passing locally
- [ ] Code review approved
- [ ] QA sign-off (for prod deployments)
- [ ] UAT sign-off (for prod deployments)
- [ ] Deployment window confirmed
- [ ] Stakeholders notified
- [ ] Rollback plan documented
- [ ] Dependencies deployed first

### Deployment

- [ ] Run dry-run/validation
- [ ] Execute deployment
- [ ] Monitor for errors
- [ ] Run smoke tests

### Post-Deployment

- [ ] Verify changes in target org
- [ ] Run test class(es)
- [ ] Notify stakeholders of completion
- [ ] Update documentation/tickets
- [ ] Monitor for issues (24-48 hours)

---

## Rollback Procedures

### Apex/LWC Changes

```bash
# Retrieve previous version from source control
git checkout [previous-commit] -- path/to/file
sf project deploy start --target-org prod
```

### Declarative Changes

| Change Type | Rollback Method |
|-------------|-----------------|
| Validation Rule | Deactivate in Setup |
| Flow | Activate previous version |
| Field | Mark inactive (cannot delete if has data) |
| Object | Cannot easily rollback |

### Data Changes

- [ ] Restore from backup (if available)
- [ ] Run corrective data scripts
- [ ] Document data impact

---

## Deployment Tools

### SFDX CLI Commands

```bash
# Validate deployment (dry run)
sf project deploy start --target-org [alias] --dry-run

# Deploy
sf project deploy start --target-org [alias]

# Deploy specific metadata
sf project deploy start --metadata "ApexClass:MyClass" --target-org [alias]

# Deploy with tests
sf project deploy start --target-org [alias] --test-level RunLocalTests

# Quick deploy (after successful validation)
sf project deploy quick --job-id [id] --target-org [alias]

# Retrieve
sf project retrieve start --target-org [alias] --metadata "ApexClass"
```

### Change Sets (if used)

| Environment | Outbound → Inbound |
|-------------|-------------------|
| DEV → QA | Create in DEV, upload, deploy in QA |
| QA → UAT | Create in QA, upload, deploy in UAT |
| UAT → PROD | Create in UAT, upload, deploy in PROD |

### Third-Party Tools (if used)

| Tool | Purpose | Access |
|------|---------|--------|
| [Copado/Gearset/etc.] | [Purpose] | [URL/Access info] |

---

## Test Requirements

### Production Deployments

| Test Level | When Required |
|------------|---------------|
| NoTestRun | Metadata only (no Apex) |
| RunSpecifiedTests | Specify related test classes |
| RunLocalTests | All non-namespaced tests |
| RunAllTestsInOrg | Full test run (rarely needed) |

### Minimum Coverage

- Overall org coverage: 75% (Salesforce requirement)
- Target for new code: 85%+

---

## Deployment Windows

| Window | Time | Use Case |
|--------|------|----------|
| Standard | Business hours | Low-risk changes |
| Off-hours | [Time] | Medium-risk changes |
| Maintenance | [Weekend time] | High-risk, large deployments |

### Blackout Periods

| Period | Reason |
|--------|--------|
| [Dates] | Month-end close |
| [Dates] | Quarter-end |
| [Dates] | Holiday freeze |

---

## Notifications

### Who to Notify

| Deployment Type | Notify |
|-----------------|--------|
| Dev/QA | SF Team only |
| UAT | SF Team + Business stakeholders |
| Production | SF Team + Business stakeholders + Support |

### Notification Template

```
Subject: [Salesforce Deployment] - [Date] - [Brief Description]

Deployment Details:
- Environment: [Production/Sandbox]
- Date/Time: [When]
- Duration: [Expected duration]
- Changes: [Brief summary]

Impact:
- [What users might notice]

Contact:
- [Name] - [Contact info]
```

---

## Troubleshooting Deployments

### Common Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| "Test coverage is 0%" | No tests run | Specify test classes or use RunLocalTests |
| "Dependent class is invalid" | Dependency issue | Deploy dependencies first |
| "Cannot delete field" | Field has data | Remove data first or keep field |

### Deployment Logs

```bash
# Check deployment status
sf project deploy report --job-id [id]

# Resume failed deployment
sf project deploy resume --job-id [id]

# Cancel deployment
sf project deploy cancel --job-id [id]
```

---

## Notes

[Additional deployment notes, org-specific procedures, or exceptions]
