# Apex & LWC Code Review Prompts

Use these prompts with Claude to analyze and understand code in unfamiliar Salesforce orgs.

---

## Apex Architecture Review

### Overall Architecture Assessment

```
I've retrieved the Apex classes from this org. Here's the list with metadata:

[Paste apex-classes.json or class list with sizes/API versions]

Please analyze the overall architecture:
1. What architectural patterns are being used?
   - Trigger handler framework (which one?)
   - Service layer pattern
   - Selector/Domain pattern (fflib?)
   - Or ad-hoc/no clear pattern?

2. How is the code organized?
   - Clear separation of concerns?
   - Naming conventions?
   - Test organization?

3. What's the overall code health?
   - API version distribution (old versions = tech debt)
   - Class size distribution (huge classes = potential issues)
   - Test class coverage (by naming convention)

4. What patterns should I follow for new development?

5. What are the biggest architecture concerns?
```

### Trigger Analysis

```
Here are all the triggers in this org:

[Paste trigger code or trigger list]

Please analyze:

1. **Trigger Pattern/Framework**
   - Is there a consistent pattern?
   - One trigger per object?
   - Handler class pattern?

2. **Bulkification Assessment**
   - Are triggers properly bulkified?
   - SOQL/DML in loops?

3. **Recursion Protection**
   - Is there recursion prevention?
   - What pattern is used?

4. **Order of Execution Risks**
   - Multiple triggers on same object?
   - Potential conflicts?

5. **Recommendations**
   - What should be refactored?
   - What pattern should new triggers follow?
```

### Single Class Deep Dive

```
Please analyze this Apex class:

```apex
[Paste full class code]
```

Provide:
1. **Purpose**: What does this class do?
2. **Pattern**: What design pattern is it using?
3. **Dependencies**: What other classes/objects does it depend on?
4. **Quality Assessment**:
   - Bulkification
   - Error handling
   - SOQL/DML efficiency
   - Code readability
5. **Security Concerns**: CRUD/FLS enforcement, injection risks
6. **Test Coverage Needs**: What test scenarios are needed?
7. **Technical Debt**: What should be improved?
8. **Documentation**: Key points to document
```

### Test Class Review

```
Here's a test class:

```apex
[Paste test class code]
```

Please evaluate:
1. **Coverage Strategy**: Unit tests? Integration tests? Both?
2. **Test Data**: Using TestDataFactory? SeeAllData? Setup methods?
3. **Assertions**: Are there meaningful assertions?
4. **Bulk Testing**: Does it test with multiple records?
5. **Negative Testing**: Does it test error scenarios?
6. **Best Practices Compliance**:
   - Isolated from org data?
   - Uses Test.startTest()/stopTest()?
   - Proper governor limit testing?
7. **Gaps**: What scenarios are missing?
```

---

## Integration Code Review

### Callout Class Analysis

```
Here's an Apex class that makes HTTP callouts:

```apex
[Paste callout class code]
```

Analyze for:
1. **Integration Pattern**: Synchronous? Queueable? Future? Batch?
2. **Authentication**: How are credentials handled?
3. **Error Handling**:
   - HTTP error codes handled?
   - Retry logic?
   - Logging?
4. **Bulkification**: Can it handle multiple records?
5. **Governor Limits**: Callout limits considered?
6. **Testability**: Is there a mock class?
7. **Security**: Credentials in code? Hardcoded endpoints?
8. **Recommendations**: What should be improved?
```

### Queueable/Batch Analysis

```
Here's an async Apex class:

```apex
[Paste Queueable or Batch class code]
```

Analyze:
1. **Purpose**: What does this job do?
2. **Trigger**: What kicks off this job?
3. **Data Processing**: How does it handle data?
4. **Error Handling**: What happens when it fails?
5. **Monitoring**: How do you know if it failed?
6. **Chaining**: Does it chain to other jobs?
7. **Governor Limits**: Scope size appropriate?
8. **Recovery**: Can failed jobs be re-run?
```

---

## LWC Review

### Component Analysis

```
Here's a Lightning Web Component:

**JavaScript:**
```javascript
[Paste JS file]
```

**HTML:**
```html
[Paste HTML file]
```

**Meta XML:**
```xml
[Paste meta file]
```

Please analyze:
1. **Purpose**: What does this component do?
2. **Data Flow**:
   - Wire adapters used?
   - Imperative Apex calls?
   - Property decorators (@api, @track)?
3. **Event Handling**: Custom events? Standard events?
4. **Error Handling**: How are errors displayed?
5. **Performance Considerations**:
   - Unnecessary re-renders?
   - Cached data?
6. **Accessibility**: ARIA attributes? Keyboard navigation?
7. **Security**: Data sanitization? XSS prevention?
8. **Best Practices Compliance**
9. **Documentation Needs**
```

### Apex Controller Review (for LWC)

```
Here's an Apex controller used by LWC:

```apex
[Paste controller class]
```

Analyze:
1. **Methods Exposed**: What @AuraEnabled methods exist?
2. **Cacheability**: Which methods are cacheable? Should they be?
3. **Security**:
   - CRUD/FLS enforced?
   - WITH SECURITY_ENFORCED used?
   - Sharing context correct?
4. **Parameter Validation**: Input validated?
5. **Error Handling**: Exceptions handled properly for LWC?
6. **Performance**: Efficient queries?
7. **Testability**: Easy to test?
```

---

## Flow Analysis (via Apex)

### Flow-Invocable Action Review

```
Here's an Invocable Apex class called from Flows:

```apex
[Paste invocable class]
```

Analyze:
1. **Purpose**: What Flow action does this provide?
2. **Input/Output**: What parameters? What returns?
3. **Bulkification**: Can it handle List inputs properly?
4. **Error Handling**: How are errors surfaced to Flow?
5. **Governor Limits**: Considerations for Flow calling multiple times?
6. **Documentation**: How should Flow builders use this?
```

---

## Security-Focused Review

### CRUD/FLS Analysis

```
Please review this code for CRUD/FLS compliance:

```apex
[Paste code]
```

Check for:
1. **Object-Level Security**:
   - Schema.SObjectType checks?
   - WITH SECURITY_ENFORCED?
   - stripInaccessible()?
2. **Field-Level Security**:
   - Field accessibility checks?
   - Safe field access patterns?
3. **Sharing Context**:
   - `with sharing` / `without sharing` / `inherited sharing`?
   - Is the choice appropriate?
4. **SOQL Injection**: Dynamic SOQL risks?
5. **Recommendations**: How to fix any issues?
```

### Sharing Rule Impact

```
This class runs `without sharing`:

```apex
[Paste code]
```

Is this appropriate? Consider:
1. What data does it access?
2. Who calls this code?
3. What's the business justification?
4. Are there security risks?
5. Should it use a different sharing context?
```

---

## Quick Analysis Prompts

### Quick Class Summary
```
Summarize in 2-3 sentences what this class does:
[Paste code]
```

### Find Potential Bugs
```
Scan this code for potential bugs or issues:
[Paste code]
```

### Suggest Improvements
```
What are the top 3 improvements for this code?
[Paste code]
```

### Document This Code
```
Generate documentation comments for this code:
[Paste code]
```

### Explain This Logic
```
Explain what this code block does step by step:
[Paste code block]
```

---

## Review Checklist Template

Use this checklist when reviewing code:

```markdown
## Code Review: [Class/Component Name]

### General
- [ ] Purpose is clear
- [ ] Naming follows conventions
- [ ] Comments where needed (not excessive)

### Apex Specific
- [ ] Bulkified (no SOQL/DML in loops)
- [ ] Governor limits considered
- [ ] Error handling present
- [ ] CRUD/FLS enforced
- [ ] Sharing context appropriate
- [ ] No hardcoded IDs/credentials

### Test Coverage
- [ ] Test class exists
- [ ] Positive scenarios covered
- [ ] Negative scenarios covered
- [ ] Bulk scenarios covered
- [ ] Meaningful assertions

### LWC Specific
- [ ] @api properties documented
- [ ] Error handling for Apex calls
- [ ] Loading states handled
- [ ] Accessible (ARIA, keyboard)

### Security
- [ ] No injection vulnerabilities
- [ ] Credentials not in code
- [ ] Appropriate access controls

### Documentation
- [ ] Class-level documentation
- [ ] Method documentation
- [ ] Complex logic explained
```
