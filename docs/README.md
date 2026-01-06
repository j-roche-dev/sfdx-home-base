# Documentation Index

This folder contains structured documentation for the Salesforce org(s) in this engagement.

## Folder Structure

```
docs/
├── org-landscape/        # Multi-org documentation
│   ├── production.md     # Production org profile
│   ├── sandboxes.md      # Sandbox inventory
│   └── org-relationships.md
├── architecture/         # Technical architecture
│   ├── data-model.md     # Object relationships
│   ├── integrations.md   # External systems
│   ├── automation.md     # Flows, triggers, etc.
│   └── security-model.md # Permissions
├── tribal-knowledge/     # Undocumented knowledge
│   ├── known-issues.md   # Technical debt
│   ├── gotchas.md        # Quirks and traps
│   ├── history.md        # Historical context
│   └── contacts.md       # Who knows what
├── processes/            # Operational docs
│   ├── deployment.md     # CI/CD procedures
│   └── support-runbook.md
└── discovery/            # Auto-generated outputs
    ├── metadata-inventory/  # Script JSON outputs
    └── analysis/            # Generated reports
```

## Quick Links

- [Production Org Profile](org-landscape/production.md)
- [Sandbox Inventory](org-landscape/sandboxes.md)
- [Data Model](architecture/data-model.md)
- [Integrations](architecture/integrations.md)
- [Known Issues](tribal-knowledge/known-issues.md)
- [Key Contacts](tribal-knowledge/contacts.md)
- [Deployment Process](processes/deployment.md)

## Updating Documentation

1. Run discovery scripts to refresh metadata inventory:
   ```bash
   npm run discover:all [org-alias]
   ```

2. Review generated report at `discovery/analysis/discovery-report.md`

3. Update relevant documentation files with findings

4. Update `CLAUDE.md` in project root with key context

## Discovery Outputs

The `discovery/` folder contains auto-generated outputs from discovery scripts:

- **metadata-inventory/**: Raw JSON files from `sf` CLI queries
- **analysis/**: Processed markdown reports

These files are gitignored by default. Re-run discovery scripts to regenerate.
