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

The discovery system has two main components:

#### 1. Metadata Retrieval (Source Files)
Retrieves actual source code into `force-app/main/default/`:

| Script | Purpose |
|--------|---------|
| `retrieve-all-metadata.sh` | **Main script** - Retrieves all Apex, LWC, Flows, Objects, etc. as source files |
| `analyze-metadata.sh` | Analyzes retrieved source files and generates JSON analysis |
| `generate-claude-context.sh` | Generates CLAUDE.md content from analysis |

#### 2. Query-Based Inventory (Supplemental Data)
Queries metadata that isn't available via retrieval:

| Script | Purpose |
|--------|---------|
| `query-metadata.sh` | SOQL queries for runtime metadata (installed packages, etc.) |
| `inventory-objects.sh` | Detailed object/field descriptions |
| `inventory-automation.sh` | Flows, Process Builders, triggers by type |
| `inventory-integrations.sh` | Named credentials, connected apps, platform events |
| `inventory-security.sh` | Profiles, permission sets, roles |
| `generate-report.sh` | Converts JSON outputs to readable markdown |

#### 3. Full Pipeline
| Script | Purpose |
|--------|---------|
| `full-discovery.sh` | **Runs entire pipeline** - retrieve, query, analyze, generate docs |

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

# 2. Remove template git history (start fresh)
rm -rf .git && git init

# 3. Install dependencies
npm install

# 4. Authenticate to the org
sf org login web --alias prod

# 5. Run FULL discovery pipeline (recommended)
./scripts/discovery/full-discovery.sh prod

# 6. Review generated documentation
cat docs/discovery/analysis/claude-context.md
```

### Step-by-Step (Manual)

```bash
# 1. Retrieve all source code from org
./scripts/discovery/retrieve-all-metadata.sh prod

# 2. Run supplemental SOQL queries
./scripts/discovery/query-metadata.sh prod

# 3. Analyze retrieved metadata
./scripts/discovery/analyze-metadata.sh

# 4. Generate CLAUDE.md content
./scripts/discovery/generate-claude-context.sh

# 5. Review and copy to CLAUDE.md
cat docs/discovery/analysis/claude-context.md
```

### NPM Scripts

```bash
# Full discovery pipeline
npm run discover:full prod

# Individual scripts
npm run retrieve prod          # Retrieve all metadata
npm run query prod             # Query supplemental data
npm run analyze                # Analyze retrieved files
npm run context:generate       # Generate CLAUDE.md content

# Detailed inventories
npm run discover:objects prod
npm run discover:automation prod
npm run discover:integrations prod
npm run discover:security prod
npm run discover:report
```

## Project Structure

```
├── CLAUDE.md                    # AI context file (fill this in!)
├── docs/
│   ├── org-landscape/           # Org profiles and relationships
│   ├── architecture/            # Data model, integrations, automation
│   ├── tribal-knowledge/        # Issues, gotchas, history, contacts
│   ├── processes/               # Deployment, support runbook
│   └── discovery/               # Auto-generated outputs
│       ├── metadata-inventory/  # Query results (JSON)
│       └── analysis/            # Analysis and reports
│           ├── apex-analysis.json
│           ├── trigger-analysis.json
│           ├── object-analysis.json
│           ├── flow-analysis.json
│           ├── component-summary.json
│           └── claude-context.md   # Copy to CLAUDE.md
├── scripts/
│   └── discovery/               # Discovery scripts
│       ├── full-discovery.sh           # Master orchestration
│       ├── retrieve-all-metadata.sh    # Source retrieval
│       ├── query-metadata.sh           # SOQL queries
│       ├── analyze-metadata.sh         # Source analysis
│       ├── generate-claude-context.sh  # Doc generation
│       └── inventory-*.sh              # Detailed inventories
├── prompts/                     # Claude prompts for discovery
├── templates/                   # Setup guides
├── force-app/main/default/      # Retrieved Salesforce metadata
│   ├── classes/                 # Apex classes
│   ├── triggers/                # Apex triggers
│   ├── flows/                   # Flow definitions
│   ├── lwc/                     # Lightning Web Components
│   ├── aura/                    # Aura components
│   └── objects/                 # Custom objects & fields
└── logs/                        # Execution logs
```

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf` commands)
- [Node.js](https://nodejs.org/) (for npm scripts and dev tooling)
- `jq` (optional but recommended for better report generation)
- Authenticated access to target Salesforce org(s)

### Installing jq (optional)
```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq

# Windows (with chocolatey)
choco install jq
```

## Workflow

1. **Clone** this template for each new engagement
2. **Authenticate** to the client's org(s)
3. **Run `full-discovery.sh`** to retrieve metadata and generate analysis
4. **Review** the generated `claude-context.md`
5. **Copy relevant sections** to your `CLAUDE.md`
6. **Use Claude prompts** to analyze the retrieved code
7. **Fill in templates** with what you learn from stakeholders
8. **Maintain** CLAUDE.md as your ongoing context file

## What Gets Retrieved

The `retrieve-all-metadata.sh` script pulls:
- **Apex**: Classes, Triggers, Components, Pages
- **Lightning**: LWC, Aura components
- **Objects**: Custom objects, fields, validation rules, record types
- **Automation**: Flows, Process Builders
- **Security**: Profiles, Permission Sets
- **UI**: Layouts, FlexiPages, Tabs, Applications
- **Integration**: Named Credentials, Remote Site Settings, Connected Apps
- **Reports**: Reports, Dashboards, Report Types
- **Email**: Email Templates, Letterheads

## Generated Analysis

After running the discovery pipeline, you get:

| File | Contents |
|------|----------|
| `apex-analysis.json` | Categorized Apex classes (Test, Controller, Service, Batch, Integration) |
| `trigger-analysis.json` | Triggers mapped to objects with event types |
| `object-analysis.json` | Objects with field counts, validation rules, record types |
| `flow-analysis.json` | Flows categorized by type (Record-Triggered, Screen, Scheduled) |
| `component-summary.json` | Total counts of all component types |
| `claude-context.md` | **Ready to copy into CLAUDE.md** |

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
