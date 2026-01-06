# Gotchas & Undocumented Quirks

> Things that will bite you if you don't know about them

---

## Data Model Gotchas

### 1. [Object] Has Multiple Record Types with Different Behavior

**What**: [Object]'s record types behave very differently:
- Type A: [behavior]
- Type B: [behavior]

**Why It Matters**: Code that works for Type A may fail for Type B.

**Watch Out For**: [Specific scenario]

---

### 2. [Field] Is Not What It Seems

**What**: `Object.Field__c` is named [X] but actually contains [Y].

**History**: [Why this happened]

**Impact**: Don't trust the field name - always check the actual values.

---

## Automation Gotchas

### 1. Order of Execution Trap on [Object]

**What**: [Object] has both a trigger AND a flow that update the same field.

**Behavior**: The flow runs AFTER the trigger, so the flow's value always wins.

**Watch Out For**: If you're debugging why trigger changes don't stick.

---

### 2. Recursive Trigger Not Fully Protected

**What**: The trigger on [Object] has recursion protection but it's based on [method], which doesn't account for [scenario].

**How to Trigger**: [Specific steps]

**Workaround**: [How to avoid]

---

## Integration Gotchas

### 1. [Integration] Timeout Is Very Short

**What**: The [System] API times out after only [X] seconds.

**Impact**: Large payloads may fail silently.

**Workaround**: Batch requests to under [X] records.

---

### 2. Named Credential [Name] Requires Manual Token Refresh

**What**: Despite being OAuth, the token doesn't auto-refresh in sandbox.

**When**: After sandbox refresh.

**Fix**: Navigate to Named Credential > Edit > Re-authenticate.

---

## Security Gotchas

### 1. [Permission Set] Grants More Than Expected

**What**: The `[Permission_Set]` permission set includes [unexpected access].

**Why**: It was created for [original purpose] and later repurposed.

**Watch Out For**: Don't assign without understanding full scope.

---

### 2. Sharing Rule [Name] Has Unintended Recipients

**What**: The sharing rule shares [Object] with [Group], but that group includes [unexpected users].

**Impact**: Sensitive data may be visible to [unexpected users].

---

## Deployment Gotchas

### 1. [Component] Must Be Deployed Before [Other Component]

**What**: You cannot deploy [Component B] without first deploying [Component A].

**Error You'll See**: "[Specific error message]"

**Fix**: Deploy in this order: A, then B.

---

### 2. Custom Metadata [Name] Not Included in Change Sets

**What**: `[Custom_Metadata]` records are not included when you add the type to a change set.

**Why**: [Reason - e.g., CMT records must be explicitly selected]

**Fix**: [How to properly deploy]

---

## User Interface Gotchas

### 1. Page Layout [Name] Only Shows for [Condition]

**What**: The [Layout] page layout is assigned to [Record Type/Profile combo] but users don't see expected fields.

**Actual Reason**: [e.g., FLS is blocking, conditional visibility, etc.]

---

### 2. Lightning Component [Name] Breaks in [Context]

**What**: The [Component] LWC works on record pages but breaks in [other context].

**Reason**: [e.g., missing record context, different permissions, etc.]

---

## Data Gotchas

### 1. [Object] Has Orphaned Records

**What**: There are [X] records of [Object] where the parent [Parent_Object] has been deleted.

**Impact**: Reports may show unexpected data, lookups may error.

**Cleanup**: Run [report/query] to identify, decide on cleanup approach.

---

### 2. [Picklist Field] Has Legacy Values

**What**: `Object.Status__c` has inactive values that still exist on old records: [Value1], [Value2].

**Impact**: Reports filtering on status may miss these records.

**Watch Out For**: Validation rules that assume current values only.

---

## Testing Gotchas

### 1. Test Class [Name] Relies on Org Data

**What**: The test class `[TestClass]` uses `SeeAllData=true` and depends on specific records existing.

**Required Records**: [Description of required data]

**Risk**: Test will fail if those records are deleted or modified.

---

### 2. Mock [Name] Doesn't Cover [Scenario]

**What**: The mock class for [Integration] doesn't handle [error scenario].

**Impact**: Error handling code has no test coverage.

---

## Environment Gotchas

### 1. Sandbox [Name] Has Different [Configuration]

**What**: The [DEV/QA] sandbox has [configuration] set differently than production.

**Why**: [Historical reason]

**Impact**: Code that works in sandbox may behave differently in prod.

---

### 2. Feature [Name] Only Works in Production

**What**: [Feature] is not available in sandbox orgs (or behaves differently).

**Examples**: Event Monitoring, certain Einstein features, Shield encryption

---

## Historical Gotchas

### 1. Why [Thing] Is Named [Weird Name]

**History**: [Explanation of why something has a confusing name]

**Original Purpose**: [What it was originally for]

**Current Purpose**: [What it's actually used for now]

---

## Adding New Gotchas

When you discover a new gotcha:
1. Add it to the appropriate section above
2. Include:
   - What the gotcha is
   - Why it matters / what breaks
   - How to avoid or work around it
3. Update CLAUDE.md if it's critical enough
