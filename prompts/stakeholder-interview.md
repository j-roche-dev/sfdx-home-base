# Stakeholder Interview Guide

Use these questions when meeting with different stakeholders to capture tribal knowledge and fill documentation gaps.

---

## Pre-Interview Preparation

Before any interview:
1. Review discovery report for the relevant area
2. Prepare specific questions based on findings
3. Have CLAUDE.md open to update during/after
4. Record the session (with permission) or take detailed notes

---

## For Salesforce Administrators

### System History & Context

1. **How long has this Salesforce org been in use?**
   - When was it originally implemented?
   - Has it been through any major migrations or re-implementations?

2. **Who was involved in the original implementation?**
   - Internal team, SI partner, consultant?
   - Is any of that team still available?

3. **What's the history of major changes?**
   - Any significant projects or additions over the years?
   - When were major features like [CPQ, Service Cloud, etc.] added?

### Current State & Pain Points

4. **What are the most business-critical processes in Salesforce?**
   - What would cause the biggest disruption if it broke?
   - Which reports does leadership rely on?

5. **What keeps you up at night about this org?**
   - Known issues that haven't been fixed?
   - Areas that feel fragile?

6. **What integrations cause the most support issues?**
   - Which ones break most often?
   - How do you know when they fail?

7. **Are there any "don't touch" areas?**
   - Components that are critical but poorly understood?
   - Things that broke in the past when changed?

### Documentation & Knowledge

8. **Where is existing documentation?**
   - Confluence, SharePoint, Google Docs?
   - Is it up to date?

9. **Who knows the most about [specific area]?**
   - Data model? Integrations? Security?
   - Any single points of knowledge failure?

10. **Are there undocumented critical processes?**
    - Manual steps that people just "know" to do?
    - Workarounds that aren't written down?

### Change Management

11. **What's the current deployment process?**
    - Change sets, SFDX, third-party tool?
    - Who approves changes?

12. **How are sandboxes used and refreshed?**
    - Which sandbox for which purpose?
    - Refresh schedule?

13. **Are there deployment blackout periods?**
    - Month-end, quarter-end, holidays?

---

## For Business Process Owners

### Process Understanding

1. **Walk me through the [Sales/Service/etc.] process from start to finish.**
   - What triggers the start of the process?
   - What's the end state / success criteria?
   - Who's involved at each step?

2. **What Salesforce features are most critical to your team?**
   - What would make work impossible if it wasn't working?

3. **What pain points do users experience?**
   - What do they complain about?
   - What takes too long?
   - What's confusing?

4. **What's working really well that we should preserve?**
   - Successful automations?
   - Reports people love?

### Data & Reporting

5. **What reports and dashboards does leadership rely on?**
   - Daily, weekly, monthly?
   - Who creates them?

6. **Are there data quality issues?**
   - Duplicate records?
   - Missing data?
   - Stale data?

7. **How do you measure success?**
   - KPIs tracked in Salesforce?
   - Data that feeds into other systems?

### Future State

8. **What improvements have been requested but not implemented?**
   - Feature requests in backlog?
   - Things promised but never delivered?

9. **Are there planned business changes that will affect Salesforce?**
   - New products/services?
   - Organizational changes?
   - New compliance requirements?

10. **If you could change one thing about how Salesforce works for your team, what would it be?**

---

## For Integration / IT Teams

### Integration Architecture

1. **What integration platform/middleware is in use?**
   - MuleSoft, Boomi, Workato, custom?
   - Point-to-point or hub-and-spoke?

2. **Which integrations are mission-critical vs. nice-to-have?**
   - What's the business impact of each failing?

3. **What's the monitoring and alerting strategy?**
   - How do you know when integrations fail?
   - Who gets notified?

4. **Have there been any recent integration failures?**
   - What happened? How was it resolved?
   - Lessons learned?

### Technical Details

5. **What authentication methods are used?**
   - OAuth, API keys, certificates?
   - Where are credentials stored?

6. **What are the data volumes and frequencies?**
   - Real-time vs. batch?
   - Records per day/hour?

7. **Are there retry and error handling standards?**
   - What happens when a call fails?
   - Dead letter queues?

### Security & Compliance

8. **What compliance requirements affect Salesforce?**
   - HIPAA, SOX, GDPR, PCI?
   - What controls are in place?

9. **How is sensitive data handled?**
   - Encryption at rest/in transit?
   - Data masking in sandboxes?

10. **Are there data residency requirements?**
    - Where must data be stored?
    - Cross-border transfer restrictions?

### Technical Debt

11. **What would you rebuild if you could?**
    - Integration patterns you'd change?
    - Technical decisions you'd reverse?

12. **Are there known performance issues?**
    - Slow queries, timeout issues?
    - API limit concerns?

---

## For Previous Developers (If Available)

### Architecture Decisions

1. **Why was [specific pattern/approach] chosen?**
   - What were the alternatives considered?
   - What constraints existed at the time?

2. **Are there any "gotchas" in the codebase?**
   - Non-obvious behavior?
   - Things that look wrong but are intentional?

3. **What would you do differently with hindsight?**
   - Technical debt you'd address?
   - Patterns you'd change?

### Undocumented Knowledge

4. **Are there special deployment considerations?**
   - Order of operations?
   - Manual steps required?

5. **What data dependencies exist that aren't obvious?**
   - Hidden relationships?
   - Assumed data states?

6. **Are there any scripts or tools not in source control?**
   - Data loader mappings?
   - One-off scripts?

7. **What were you working on that didn't get finished?**
   - Incomplete features?
   - Abandoned initiatives?

---

## For End Users (Power Users)

### Daily Usage

1. **What's your typical day-to-day workflow in Salesforce?**
   - What do you do first thing?
   - Most common tasks?

2. **What's the most frustrating part of using Salesforce?**
   - What makes you say "ugh" every day?

3. **What workarounds have you developed?**
   - Things you do because the system doesn't support what you need?

4. **What features do you wish existed?**
   - Things that would save you time?

### Training & Adoption

5. **How were you trained on Salesforce?**
   - Formal training? Learn from coworkers? Self-taught?

6. **What do new team members struggle with most?**
   - Confusing features?
   - Non-obvious workflows?

7. **Are there features you know exist but don't know how to use?**

---

## Post-Interview Actions

After each interview:

1. **Update documentation immediately** while context is fresh
2. **Add to CLAUDE.md** any critical context
3. **Create issues/tickets** for problems discovered
4. **Update contacts.md** with expertise areas
5. **Share findings** with the team
6. **Schedule follow-ups** if more detail is needed

---

## Interview Notes Template

```markdown
## Interview: [Name] - [Role]
**Date**: YYYY-MM-DD
**Duration**: X minutes
**Attendees**: [list]

### Key Topics Discussed
- [topic 1]
- [topic 2]

### Important Findings
1. [finding]
2. [finding]

### Pain Points Identified
- [pain point]

### Action Items
- [ ] [action]
- [ ] [action]

### Questions for Follow-up
- [question]

### Documentation Updates Needed
- [ ] Update [file] with [info]
```
