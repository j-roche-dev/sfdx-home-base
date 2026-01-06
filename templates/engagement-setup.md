# New Engagement Setup Guide

Follow this guide when starting work on a new Salesforce org/client.

---

## Pre-Engagement Checklist

### Client Information

| Field | Value |
|-------|-------|
| Client Name | |
| Project/Engagement Name | |
| Start Date | |
| Primary Client Contact | |
| Project Manager | |

### Access Requests

- [ ] **Salesforce org access** - Request System Admin or appropriate profile
  - Production org
  - Sandbox access (list which sandboxes)
- [ ] **Source control access** - GitHub, Bitbucket, Azure DevOps
- [ ] **Documentation access** - Confluence, SharePoint, Google Drive
- [ ] **Communication channels** - Slack, Teams, email distribution lists
- [ ] **Ticketing system** - Jira, ServiceNow, etc.
- [ ] **VPN/Network access** - If required for client systems

---

## Step 1: Clone and Configure Project

### Option A: Create New Project from Template

```bash
# Clone the template repository
cp -r /path/to/sfdxHomeBase /path/to/[client-name]-salesforce
cd [client-name]-salesforce

# Remove existing git history and start fresh
rm -rf .git
git init
git add .
git commit -m "Initial commit from sfdxHomeBase template"

# Connect to client's remote repository (if exists)
git remote add origin [client-repo-url]
git push -u origin main
```

### Option B: Add to Existing Repository

If the client already has a repository:

```bash
# Clone client's repo
git clone [client-repo-url]
cd [client-repo]

# Copy in template files you need
cp -r /path/to/sfdxHomeBase/docs ./docs
cp -r /path/to/sfdxHomeBase/scripts/discovery ./scripts/discovery
cp -r /path/to/sfdxHomeBase/prompts ./prompts
cp /path/to/sfdxHomeBase/CLAUDE.md ./CLAUDE.md
```

### Update Project Configuration

1. Edit `sfdx-project.json`:
   - Update `name` if needed
   - Verify `sourceApiVersion`
   - Update `sfdcLoginUrl` if using custom domain

2. Edit `package.json`:
   - Update `name` field
   - Add discovery scripts (if not already present)

3. Rename `CLAUDE.md` placeholders:
   - Replace `[CLIENT_NAME]` with actual client name

---

## Step 2: Authenticate to Orgs

### Production Org

```bash
# Standard login
sf org login web --alias prod --instance-url https://login.salesforce.com

# My Domain login
sf org login web --alias prod --instance-url https://[company].my.salesforce.com

# Verify
sf org display --target-org prod
```

### Sandbox Orgs

```bash
# Development sandbox
sf org login web --alias dev-sb --instance-url https://test.salesforce.com

# Or with My Domain
sf org login web --alias dev-sb --instance-url https://[company]--[sandbox].sandbox.my.salesforce.com

# List all authenticated orgs
sf org list
```

### Set Default Org

```bash
# Set default for this project
sf config set target-org prod
```

---

## Step 3: Run Discovery Scripts

### Make Scripts Executable (First Time)

```bash
chmod +x scripts/discovery/*.sh
```

### Run Full Discovery

```bash
# Against production
./scripts/discovery/retrieve-metadata.sh prod

# Or use npm script (if configured)
npm run discover prod
```

### Generate Report

```bash
./scripts/discovery/generate-report.sh

# View report
cat docs/discovery/analysis/discovery-report.md
```

### Run Detailed Inventories (Optional)

```bash
# Detailed object descriptions
./scripts/discovery/inventory-objects.sh prod

# Automation inventory
./scripts/discovery/inventory-automation.sh prod

# Integration inventory
./scripts/discovery/inventory-integrations.sh prod

# Security model
./scripts/discovery/inventory-security.sh prod
```

---

## Step 4: Initialize Documentation

### Update CLAUDE.md

Open `CLAUDE.md` and fill in:

1. **Quick Reference** section
   - Org IDs
   - Default aliases
   - API version

2. **Environment Summary** table
   - List all orgs (prod + sandboxes)
   - Record purposes and refresh dates

3. **Authentication** section
   - Actual login commands for this client

### Update Org Documentation

1. `docs/org-landscape/production.md`
   - Fill in org details from discovery

2. `docs/org-landscape/sandboxes.md`
   - List all sandboxes with purposes

3. `docs/tribal-knowledge/contacts.md`
   - Add client contacts as you learn them

---

## Step 5: Retrieve Existing Metadata (If Applicable)

### If No Source Control Exists

```bash
# Create a package.xml for full retrieve (careful - can be large!)
sf project generate manifest --from-org prod --output-dir manifest

# Retrieve metadata
sf project retrieve start --manifest manifest/package.xml --target-org prod
```

### If Selective Retrieve Needed

```bash
# Retrieve specific types
sf project retrieve start --metadata "ApexClass,ApexTrigger,LightningComponentBundle" --target-org prod

# Retrieve specific components
sf project retrieve start --metadata "ApexClass:MyClass" --target-org prod
```

---

## Step 6: Schedule Discovery Sessions

### Recommended Sessions

| Session | Attendees | Duration | Topics |
|---------|-----------|----------|--------|
| Kickoff | All stakeholders | 1 hour | Project overview, access, timeline |
| Admin Walkthrough | SF Admin | 1-2 hours | Org tour, key processes, known issues |
| Business Process | Process owners | 1 hour each | [Sales/Service/etc.] workflow |
| Integration Briefing | IT/Integration team | 1 hour | External systems, data flows |
| Developer Handoff | Previous dev (if any) | 1-2 hours | Architecture, code patterns, gotchas |

### Use Interview Guides

Refer to `prompts/stakeholder-interview.md` for questions.

---

## Step 7: First Week Deliverables

By end of first week, aim to have:

- [ ] All discovery scripts run against production
- [ ] `CLAUDE.md` populated with key context
- [ ] `docs/org-landscape/` filled in
- [ ] Initial architecture understanding documented
- [ ] Top 3-5 areas of concern identified
- [ ] Key contacts documented
- [ ] Development environment working

---

## Ongoing Workflow

### When Starting Each Day

1. Pull latest from source control
2. Check for any overnight issues (if supporting production)
3. Review/update todo list
4. Check `CLAUDE.md` for context

### When Making Changes

1. Create feature branch
2. Make changes in sandbox
3. Test thoroughly
4. Update documentation if needed
5. Create PR for review
6. Deploy through environments

### When Learning Something New

1. Update relevant documentation immediately
2. Add to `docs/tribal-knowledge/` if it's institutional knowledge
3. Update `CLAUDE.md` if it's critical context

### Monthly Maintenance

1. Re-run discovery scripts to catch changes
2. Review and update documentation
3. Check for stale information in CLAUDE.md
4. Update contacts if team has changed

---

## Troubleshooting

### Authentication Issues

```bash
# Clear cached auth
sf org logout --target-org [alias] --no-prompt

# Re-authenticate
sf org login web --alias [alias] --instance-url [url]
```

### Discovery Script Errors

```bash
# Check org connection
sf org display --target-org [alias]

# Check CLI version
sf version

# Run with debug output
DEBUG=* ./scripts/discovery/retrieve-metadata.sh [alias]
```

### Deployment Issues

```bash
# Validate without deploying
sf project deploy start --target-org [alias] --dry-run

# Check deployment status
sf project deploy report --job-id [job-id]

# Cancel stuck deployment
sf project deploy cancel --job-id [job-id]
```

---

## Quick Reference Commands

```bash
# Org management
sf org list                          # List all orgs
sf org display --target-org [alias]  # Show org details
sf org open --target-org [alias]     # Open org in browser

# Metadata operations
sf project deploy start --target-org [alias]   # Deploy
sf project retrieve start --target-org [alias] # Retrieve
sf project deploy report                       # Check status

# Data operations
sf data query --query "SELECT Id FROM Account LIMIT 1" --target-org [alias]
sf data export tree --query "SELECT Id, Name FROM Account" --target-org [alias]

# Apex operations
sf apex run --file scripts/apex/hello.apex --target-org [alias]
sf apex run test --target-org [alias] --code-coverage

# Discovery (from this project)
npm run discover [alias]
npm run discover:all [alias]
```

---

## Notes

[Add any client-specific notes or variations to the standard process]
