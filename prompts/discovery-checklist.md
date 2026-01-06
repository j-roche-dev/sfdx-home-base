# Salesforce Org Discovery Checklist

Use these prompts with Claude to systematically discover and document an unfamiliar Salesforce org.

---

## Phase 1: Initial Context Gathering

### Prompt 1: Org Overview Analysis

After running the discovery scripts, use this prompt:

```
I've just connected to a new Salesforce org. Here's the discovery report:

[Paste contents of docs/discovery/analysis/discovery-report.md]

Please analyze this and provide:
1. A summary of the org's complexity (small/medium/large enterprise)
2. Key custom objects that appear business-critical based on naming
3. Red flags or areas needing immediate attention (old API versions, many Process Builders, etc.)
4. Initial questions I should ask the client about unclear items
5. Recommended priority order for deeper investigation
```

### Prompt 2: Data Model Analysis

```
Here are the custom object descriptions from this Salesforce org:

[Paste relevant JSON from docs/discovery/metadata-inventory/objects/]

Please:
1. Map the relationships between these objects (parent-child, lookups)
2. Identify the core business objects vs. supporting/junction objects
3. Suggest an ERD structure showing the main relationships
4. Note any unusual patterns (circular references, excessive lookups, etc.)
5. Identify objects that likely need detailed field-level documentation
```

### Prompt 3: Automation Landscape Analysis

```
Here's the automation inventory for this org:

Apex Triggers:
[Paste apex-triggers.json content]

Flows:
[Paste flows.json content]

Process Builders (if any):
[Paste process-builders.json content]

Please analyze:
1. Which objects have the most automation? Are there potential conflicts?
2. What's the order of execution risk for objects with multiple automations?
3. Identify any legacy automation (Process Builders, Workflow Rules) that should be migrated
4. Are there naming convention patterns I should follow?
5. Flag any objects where I should be extra careful making changes
```

---

## Phase 2: Integration Discovery

### Prompt 4: Integration Mapping

```
Here are the integration-related configurations from this Salesforce org:

Named Credentials:
[Paste named-credentials.json]

Connected Apps:
[Paste connected-apps.json]

Remote Sites:
[Paste remote-sites.json]

Platform Events (if any):
[Paste platform-events.json]

Please:
1. Identify all external systems this org likely connects to
2. Categorize by integration pattern (REST API, SOAP, Platform Events, etc.)
3. Flag any security concerns (plain endpoints vs. named credentials)
4. Create a preliminary integration inventory table for documentation
5. List questions to ask about each integration
```

### Prompt 5: Integration Code Review

```
Here are the Apex classes that appear to handle integrations:

[Paste relevant class code or class list]

Please analyze:
1. What integration patterns are used? (Queueable, Future, Batch, Synchronous)
2. Is there consistent error handling?
3. Are there proper test mocks?
4. What credentials/endpoints are referenced?
5. Rate any technical debt or improvement opportunities
```

---

## Phase 3: Security Model

### Prompt 6: Permission Model Review

```
Here's the security configuration:

Profiles:
[Paste profiles.json]

Permission Sets:
[Paste permission-sets.json]

Permission Set Groups:
[Paste permission-set-groups.json]

Users by Profile:
[Paste users-by-profile.json]

Please analyze:
1. Is this org using modern permission set model or legacy profiles?
2. Identify custom permission sets and their likely purpose based on naming
3. Flag any concerning patterns (many custom profiles, over-permissioned sets)
4. Are there orphaned permission sets (0 assignments)?
5. Suggest documentation structure for the permission model
```

---

## Phase 4: Code Quality Review

### Prompt 7: Apex Code Assessment

```
Here's the Apex class inventory:

[Paste apex-classes.json]

Based on class names, sizes, and API versions:
1. Identify likely architectural patterns (trigger handler, service layer, selector, domain)
2. Flag classes that might need attention:
   - Very old API versions (potential technical debt)
   - Very large files (>1000 lines - possible god class)
   - No apparent test class pairing
3. Identify test classes and estimate coverage strategy
4. Note any naming convention patterns
5. Rate overall code organization: Excellent / Good / Needs Work / Problematic
```

### Prompt 8: Trigger Pattern Analysis

```
Here are the triggers in this org:

[Paste trigger code or trigger list with their objects]

Analyze for:
1. Is there a consistent trigger pattern/framework?
2. Are there multiple triggers per object? (Red flag)
3. What's the bulkification status?
4. Any obvious recursion protection patterns?
5. Recommend any immediate refactoring needs
```

---

## Phase 5: Documentation Generation

### Prompt 9: Generate CLAUDE.md Content

```
Based on all the discovery we've done, here's what I've learned:

[Paste your notes and key findings]

Please help me generate content for CLAUDE.md including:
1. Environment summary table
2. Architecture overview section with key objects and relationships
3. Automation landscape summary
4. Integration points summary
5. Known issues or technical debt items discovered
6. Key contacts section (template - I'll fill in names)
```

### Prompt 10: Generate Architecture Documentation

```
Based on this discovery data:

Objects: [paste summary]
Relationships: [paste summary]
Integrations: [paste summary]

Please generate:
1. A data model documentation section for docs/architecture/data-model.md
2. An integration architecture section for docs/architecture/integrations.md
3. ASCII diagrams where helpful
4. Tables summarizing key configurations
```

---

## Ongoing Discovery Prompts

### When You Encounter Unfamiliar Code

```
I found this Apex class in the org:

[Paste class code]

Please explain:
1. What is this class's purpose?
2. What patterns/frameworks is it using?
3. What objects/data does it work with?
4. Are there any concerns or code smells?
5. What should I document about this?
```

### When You Need to Understand a Flow

```
Here's a Flow definition (exported from org):

[Paste flow XML or describe the flow]

Please explain:
1. What does this flow do step by step?
2. What triggers it? (Record change, screen, schedule, etc.)
3. What data does it read/write?
4. Are there any potential issues (infinite loops, governor limits)?
5. What should I document about this?
```

### When Planning a Change

```
I need to make this change in the Salesforce org:

[Describe the change]

Based on what we know about the org:
- Objects affected: [list]
- Existing automation: [list]
- Integrations: [list]

Please help me:
1. Identify all areas that might be affected
2. Flag potential conflicts with existing automation
3. Suggest a safe implementation approach
4. Recommend testing approach
5. Draft deployment notes
```

---

## Quick Reference Prompts

### Object Quick Analysis
```
Describe this Salesforce object for documentation: [Object API Name]
JSON describe: [paste object describe JSON]
```

### Field Analysis
```
What is the purpose of these fields and any concerns?
[Paste field list or describe output]
```

### Flow Quick Analysis
```
Summarize this flow's purpose and any concerns:
[Paste flow details]
```

### Error Investigation
```
Help me understand this Salesforce error:
Error: [paste error]
Context: [what user was doing]
```

---

## Tips for Effective Discovery

1. **Start broad, then narrow**: Run the master discovery script first, then drill down
2. **Ask clarifying questions**: Don't assume - ask the client
3. **Document as you go**: Update CLAUDE.md and docs/ incrementally
4. **Trust but verify**: Discovery scripts give hints, but verify with actual testing
5. **Note tribal knowledge**: Record explanations from stakeholders immediately
