# sfdx-home-base

A reusable Salesforce DX project template designed for consultants and developers who frequently work with unfamiliar orgs. Includes automated discovery scripts, comprehensive documentation templates, and Claude AI prompts for rapid org understanding and documentation.

## The Problem This Solves

When stepping into an existing Salesforce environment, you often face:
- No git repository
- Poor or missing documentation
- Work done by various teams over multiple years
- Tribal knowledge locked in people's heads

This template provides a structured approach to quickly understand and document any Salesforce org.

## Features

### CLAUDE.md Context File
A comprehensive context file for AI-assisted development that captures:
- Environment summary (production + sandboxes)
- Architecture overview (data model, automation, integrations)
- Known issues and technical debt
- Key contacts and tribal knowledge
- Code conventions and deployment notes

### Automated Discovery Scripts
Shell scripts that retrieve org metadata using the Salesforce CLI:

| Script | Purpose |
|--------|---------|
| `retrieve-metadata.sh` | Master script - fetches objects, Apex, flows, packages, permissions |
| `inventory-objects.sh` | Detailed object/field descriptions |
| `inventory-automation.sh` | Flows, Process Builders, triggers by type |
| `inventory-integrations.sh` | Named credentials, connected apps, platform events |
| `inventory-security.sh` | Profiles, permission sets, roles |
| `generate-report.sh` | Converts JSON outputs to readable markdown |

### Documentation Templates
Pre-structured templates in `docs/` for:

- **Org Landscape**: Production profile, sandbox inventory, org relationships
- **Architecture**: Data model, integrations, automation, security model
- **Tribal Knowledge**: Known issues, gotchas, historical context, contacts
- **Processes**: Deployment procedures, support runbook

### Claude Prompts
Ready-to-use prompts in `prompts/` for:
- **Discovery Checklist**: Structured workflow for analyzing discovery output
- **Stakeholder Interviews**: Questions for admins, business owners, developers
- **Code Review**: Apex architecture, trigger analysis, LWC assessment

## Quick Start

### For a New Engagement

```bash
# 1. Clone this template
git clone https://github.com/j-roche-dev/sfdx-home-base.git [client]-salesforce
cd [client]-salesforce

# 2. Remove template git history (optional - start fresh)
rm -rf .git && git init

# 3. Authenticate to the org
sf org login web --alias prod

# 4. Run discovery
./scripts/discovery/retrieve-metadata.sh prod

# 5. Generate readable report
./scripts/discovery/generate-report.sh

# 6. Review report and update CLAUDE.md
cat docs/discovery/analysis/discovery-report.md
```

### NPM Scripts

```bash
# Individual discovery scripts
npm run discover prod
npm run discover:objects prod
npm run discover:automation prod
npm run discover:integrations prod
npm run discover:security prod
npm run discover:report

# Run all discovery (pass org alias via --org flag)
npm run discover:all --org=prod
```

## Project Structure

```
├── CLAUDE.md                    # AI context file (fill this in!)
├── docs/
│   ├── org-landscape/           # Org profiles and relationships
│   ├── architecture/            # Data model, integrations, automation
│   ├── tribal-knowledge/        # Issues, gotchas, history, contacts
│   ├── processes/               # Deployment, support runbook
│   └── discovery/               # Auto-generated outputs (gitignored)
├── scripts/
│   ├── discovery/               # Metadata retrieval scripts
│   ├── apex/                    # Apex scripts
│   └── soql/                    # SOQL queries
├── prompts/                     # Claude prompts for discovery
├── templates/                   # Setup guides
└── force-app/                   # Salesforce metadata (standard SFDX)
```

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf` commands)
- [Node.js](https://nodejs.org/) (for npm scripts and dev tooling)
- `jq` (for JSON parsing in report generation) - optional but recommended
- Authenticated access to target Salesforce org(s)

## Workflow

1. **Clone** this template for each new engagement
2. **Authenticate** to the client's org(s)
3. **Run discovery** scripts to pull metadata
4. **Review** the generated report
5. **Use Claude prompts** to analyze findings
6. **Fill in templates** with what you learn
7. **Maintain** CLAUDE.md as your ongoing context file

## Included Dev Tooling

- **ESLint**: Configured for Aura and LWC
- **Prettier**: Code formatting for Apex, XML, JavaScript
- **Jest**: LWC unit testing with sfdx-lwc-jest
- **Husky**: Pre-commit hooks for linting and formatting

## Contributing

Found an improvement? PRs welcome! Areas that could use enhancement:
- Additional discovery queries
- More documentation templates
- Enhanced report generation
- Additional Claude prompts

## License

MIT

---

*Built for Salesforce consultants who are tired of inheriting undocumented orgs.*
