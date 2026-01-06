#!/bin/bash
# =============================================================================
# Generate CLAUDE.md Context from Analysis
# =============================================================================
#
# Generates markdown content for CLAUDE.md from analysis JSON files.
# Run this AFTER analyze-metadata.sh has generated analysis files.
#
# Usage: ./generate-claude-context.sh [analysis-dir] [output-file]
#
# =============================================================================

set -euo pipefail

ANALYSIS_DIR="${1:-docs/discovery/analysis}"
OUTPUT_FILE="${2:-docs/discovery/analysis/claude-context.md}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1"
}

warning() {
    echo -e "${YELLOW}$1${NC}"
}

# Check for jq
HAS_JQ=false
if command -v jq &> /dev/null; then
    HAS_JQ=true
else
    warning "Warning: jq not found. Using fallback parsing (some features may be limited)."
    warning "Install jq for better results: sudo apt install jq (Linux) or brew install jq (macOS)"
    echo ""
fi

# Fallback JSON extraction functions (no jq)
extract_json_value() {
    local file="$1"
    local key="$2"
    grep -oP "\"$key\":\s*[0-9]+" "$file" 2>/dev/null | grep -oP '[0-9]+' | head -1 || echo "0"
}

extract_json_string() {
    local file="$1"
    local key="$2"
    grep -oP "\"$key\":\s*\"[^\"]*\"" "$file" 2>/dev/null | sed 's/.*"\([^"]*\)"$/\1/' | head -1 || echo ""
}

# =============================================================================
# Main
# =============================================================================

log "Generating CLAUDE.md context from analysis..."

# Create output directory
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Start document
cat > "$OUTPUT_FILE" << 'EOF'
# Auto-Generated CLAUDE.md Content

> This content was auto-generated from retrieved metadata.
> Copy relevant sections into your CLAUDE.md file and customize.

---

EOF

# -----------------------------------------------------------------------------
# Component Summary
# -----------------------------------------------------------------------------
if [ -f "$ANALYSIS_DIR/component-summary.json" ]; then
    log "  Adding component summary..."

    cat >> "$OUTPUT_FILE" << 'EOF'
## Component Inventory

| Component Type | Count |
|----------------|-------|
EOF

    if [ "$HAS_JQ" = true ]; then
        jq -r '.counts | to_entries | .[] | "| \(.key) | \(.value) |"' \
            "$ANALYSIS_DIR/component-summary.json" >> "$OUTPUT_FILE" 2>/dev/null || echo "| (parse error) | - |" >> "$OUTPUT_FILE"
    else
        # Fallback: extract counts manually
        apex=$(extract_json_value "$ANALYSIS_DIR/component-summary.json" "apexClasses")
        triggers=$(extract_json_value "$ANALYSIS_DIR/component-summary.json" "apexTriggers")
        lwc=$(extract_json_value "$ANALYSIS_DIR/component-summary.json" "lwcComponents")
        aura=$(extract_json_value "$ANALYSIS_DIR/component-summary.json" "auraComponents")
        flows=$(extract_json_value "$ANALYSIS_DIR/component-summary.json" "flows")
        objects=$(extract_json_value "$ANALYSIS_DIR/component-summary.json" "objects")
        permsets=$(extract_json_value "$ANALYSIS_DIR/component-summary.json" "permissionSets")
        profiles=$(extract_json_value "$ANALYSIS_DIR/component-summary.json" "profiles")
        layouts=$(extract_json_value "$ANALYSIS_DIR/component-summary.json" "layouts")

        echo "| Apex Classes | $apex |" >> "$OUTPUT_FILE"
        echo "| Apex Triggers | $triggers |" >> "$OUTPUT_FILE"
        echo "| LWC Components | $lwc |" >> "$OUTPUT_FILE"
        echo "| Aura Components | $aura |" >> "$OUTPUT_FILE"
        echo "| Flows | $flows |" >> "$OUTPUT_FILE"
        echo "| Objects | $objects |" >> "$OUTPUT_FILE"
        echo "| Permission Sets | $permsets |" >> "$OUTPUT_FILE"
        echo "| Profiles | $profiles |" >> "$OUTPUT_FILE"
        echo "| Layouts | $layouts |" >> "$OUTPUT_FILE"
    fi

    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Object Summary
# -----------------------------------------------------------------------------
if [ -f "$ANALYSIS_DIR/object-analysis.json" ]; then
    log "  Adding object summary..."

    cat >> "$OUTPUT_FILE" << 'EOF'
## Data Model Summary

### Custom Objects

| Object | Fields | Validation Rules | Record Types |
|--------|--------|------------------|--------------|
EOF

    if [ "$HAS_JQ" = true ]; then
        jq -r '.objects[] | select(.isCustom == true) | "| `\(.name)` | \(.fieldCount) | \(.validationRuleCount) | \(.recordTypeCount) |"' \
            "$ANALYSIS_DIR/object-analysis.json" 2>/dev/null | head -30 >> "$OUTPUT_FILE" || echo "| (no data) | - | - | - |" >> "$OUTPUT_FILE"
    else
        # Fallback: check for custom objects
        if grep -q '"isCustom": true' "$ANALYSIS_DIR/object-analysis.json" 2>/dev/null; then
            grep -B1 '"isCustom": true' "$ANALYSIS_DIR/object-analysis.json" | grep '"name"' | \
                sed 's/.*"name": "\([^"]*\)".*/| `\1` | - | - | - |/' >> "$OUTPUT_FILE" || echo "| (no data) | - | - | - |" >> "$OUTPUT_FILE"
        else
            echo "| (no custom objects) | - | - | - |" >> "$OUTPUT_FILE"
        fi
    fi

    echo "" >> "$OUTPUT_FILE"

    # Standard objects with customizations
    cat >> "$OUTPUT_FILE" << 'EOF'
### Standard Objects with Customizations

| Object | Custom Fields | Validation Rules |
|--------|---------------|------------------|
EOF

    if [ "$HAS_JQ" = true ]; then
        jq -r '.objects[] | select(.isCustom == false and .fieldCount > 0) | "| `\(.name)` | \(.fieldCount) | \(.validationRuleCount) |"' \
            "$ANALYSIS_DIR/object-analysis.json" 2>/dev/null | head -20 >> "$OUTPUT_FILE" || echo "| (no data) | - | - |" >> "$OUTPUT_FILE"
    else
        # Fallback: list standard objects
        if grep -q '"isCustom": false' "$ANALYSIS_DIR/object-analysis.json" 2>/dev/null; then
            grep -B1 '"isCustom": false' "$ANALYSIS_DIR/object-analysis.json" | grep '"name"' | \
                sed 's/.*"name": "\([^"]*\)".*/| `\1` | - | - |/' >> "$OUTPUT_FILE" || echo "| (no data) | - | - |" >> "$OUTPUT_FILE"
        else
            echo "| (none found) | - | - |" >> "$OUTPUT_FILE"
        fi
    fi

    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Apex Classes
# -----------------------------------------------------------------------------
if [ -f "$ANALYSIS_DIR/apex-analysis.json" ]; then
    log "  Adding Apex analysis..."

    cat >> "$OUTPUT_FILE" << 'EOF'
## Apex Classes

### Summary by Category

EOF

    if [ "$HAS_JQ" = true ]; then
        jq -r '.summary | "- **Total Classes**: \(.total)\n- **Test Classes**: \(.tests)\n- **Controllers**: \(.controllers)\n- **Services**: \(.services)\n- **Batch Classes**: \(.batches)\n- **Integration Classes**: \(.integrations)"' \
            "$ANALYSIS_DIR/apex-analysis.json" >> "$OUTPUT_FILE" 2>/dev/null || echo "- (summary not available)" >> "$OUTPUT_FILE"
    else
        # Fallback: extract summary manually
        total=$(extract_json_value "$ANALYSIS_DIR/apex-analysis.json" "total")
        tests=$(extract_json_value "$ANALYSIS_DIR/apex-analysis.json" "tests")
        controllers=$(extract_json_value "$ANALYSIS_DIR/apex-analysis.json" "controllers")
        services=$(extract_json_value "$ANALYSIS_DIR/apex-analysis.json" "services")
        batches=$(extract_json_value "$ANALYSIS_DIR/apex-analysis.json" "batches")
        integrations=$(extract_json_value "$ANALYSIS_DIR/apex-analysis.json" "integrations")

        echo "- **Total Classes**: $total" >> "$OUTPUT_FILE"
        echo "- **Test Classes**: $tests" >> "$OUTPUT_FILE"
        echo "- **Controllers**: $controllers" >> "$OUTPUT_FILE"
        echo "- **Services**: $services" >> "$OUTPUT_FILE"
        echo "- **Batch Classes**: $batches" >> "$OUTPUT_FILE"
        echo "- **Integration Classes**: $integrations" >> "$OUTPUT_FILE"
    fi

    echo "" >> "$OUTPUT_FILE"

    # Integration classes (HTTP callouts)
    cat >> "$OUTPUT_FILE" << 'EOF'
### Integration Classes (HTTP Callouts)

These classes make external HTTP calls:

EOF

    if [ "$HAS_JQ" = true ]; then
        integration_classes=$(jq -r '.classes[] | select(.hasHttpCallout == true) | "- `\(.name)` (\(.lines) lines)"' \
            "$ANALYSIS_DIR/apex-analysis.json" 2>/dev/null || echo "")
    else
        # Fallback: grep for HTTP callout classes
        integration_classes=$(grep -B5 '"hasHttpCallout": true' "$ANALYSIS_DIR/apex-analysis.json" 2>/dev/null | \
            grep '"name"' | sed 's/.*"name": "\([^"]*\)".*/- `\1`/' || echo "")
    fi

    if [ -n "$integration_classes" ]; then
        echo "$integration_classes" >> "$OUTPUT_FILE"
    else
        echo "- (none found)" >> "$OUTPUT_FILE"
    fi

    echo "" >> "$OUTPUT_FILE"

    # Batch/Queueable/Schedulable
    cat >> "$OUTPUT_FILE" << 'EOF'
### Async Apex Classes

| Class | Batch | Queueable | Schedulable |
|-------|-------|-----------|-------------|
EOF

    if [ "$HAS_JQ" = true ]; then
        jq -r '.classes[] | select(.isBatch == true or .isQueueable == true or .isSchedulable == true) | "| `\(.name)` | \(if .isBatch then "Yes" else "-" end) | \(if .isQueueable then "Yes" else "-" end) | \(if .isSchedulable then "Yes" else "-" end) |"' \
            "$ANALYSIS_DIR/apex-analysis.json" >> "$OUTPUT_FILE" 2>/dev/null || echo "| (none) | - | - | - |" >> "$OUTPUT_FILE"
    else
        # Fallback: grep for async classes
        if grep -qE '"isBatch": true|"isQueueable": true|"isSchedulable": true' "$ANALYSIS_DIR/apex-analysis.json" 2>/dev/null; then
            grep -B10 '"isBatch": true' "$ANALYSIS_DIR/apex-analysis.json" 2>/dev/null | \
                grep '"name"' | sed 's/.*"name": "\([^"]*\)".*/| `\1` | Yes | - | - |/' >> "$OUTPUT_FILE" || true
        fi
        # Check if we added anything
        if ! grep -q '| `' "$OUTPUT_FILE" 2>/dev/null; then
            echo "| (none found) | - | - | - |" >> "$OUTPUT_FILE"
        fi
    fi

    echo "" >> "$OUTPUT_FILE"

    # Controllers
    cat >> "$OUTPUT_FILE" << 'EOF'
### Controller Classes

EOF

    if [ "$HAS_JQ" = true ]; then
        jq -r '.classes[] | select(.category == "Controller") | "- `\(.name)` (\(.lines) lines)"' \
            "$ANALYSIS_DIR/apex-analysis.json" 2>/dev/null | head -20 >> "$OUTPUT_FILE" || echo "- (none found)" >> "$OUTPUT_FILE"
    else
        # Fallback: grep for controller classes
        if grep -q '"category": "Controller"' "$ANALYSIS_DIR/apex-analysis.json" 2>/dev/null; then
            grep -B3 '"category": "Controller"' "$ANALYSIS_DIR/apex-analysis.json" | \
                grep '"name"' | sed 's/.*"name": "\([^"]*\)".*/- `\1`/' | head -20 >> "$OUTPUT_FILE"
        else
            echo "- (none found)" >> "$OUTPUT_FILE"
        fi
    fi

    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Trigger Summary
# -----------------------------------------------------------------------------
if [ -f "$ANALYSIS_DIR/trigger-analysis.json" ]; then
    log "  Adding trigger analysis..."

    cat >> "$OUTPUT_FILE" << 'EOF'
## Trigger Framework

### Triggers by Object

| Object | Trigger | Handler | Events |
|--------|---------|---------|--------|
EOF

    if [ "$HAS_JQ" = true ]; then
        jq -r '.triggers[] | "| \(.object) | `\(.name)` | \(.handlerClass // "Direct") | \([.events | to_entries[] | select(.value == true) | .key] | join(", ")) |"' \
            "$ANALYSIS_DIR/trigger-analysis.json" >> "$OUTPUT_FILE" 2>/dev/null || echo "| (no triggers) | - | - | - |" >> "$OUTPUT_FILE"
    else
        # Fallback: extract trigger info
        if grep -q '"name"' "$ANALYSIS_DIR/trigger-analysis.json" 2>/dev/null; then
            grep '"name"' "$ANALYSIS_DIR/trigger-analysis.json" | \
                sed 's/.*"name": "\([^"]*\)".*/| - | `\1` | - | - |/' >> "$OUTPUT_FILE" || echo "| (no triggers) | - | - | - |" >> "$OUTPUT_FILE"
        else
            echo "| (no triggers) | - | - | - |" >> "$OUTPUT_FILE"
        fi
    fi

    echo "" >> "$OUTPUT_FILE"

    # Check for objects with multiple triggers (potential issue)
    cat >> "$OUTPUT_FILE" << 'EOF'
### Objects with Multiple Triggers (Review for Conflicts)

EOF

    if [ "$HAS_JQ" = true ]; then
        multi_triggers=$(jq -r '[.triggers[].object] | group_by(.) | map(select(length > 1)) | .[] | "- **\(.[0])**: \(length) triggers"' \
            "$ANALYSIS_DIR/trigger-analysis.json" 2>/dev/null || echo "")
        if [ -n "$multi_triggers" ]; then
            echo "$multi_triggers" >> "$OUTPUT_FILE"
        else
            echo "- (none - good!)" >> "$OUTPUT_FILE"
        fi
    else
        echo "- (analysis requires jq)" >> "$OUTPUT_FILE"
    fi

    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Flow Summary
# -----------------------------------------------------------------------------
if [ -f "$ANALYSIS_DIR/flow-analysis.json" ]; then
    log "  Adding flow analysis..."

    cat >> "$OUTPUT_FILE" << 'EOF'
## Automation (Flows)

### Summary

EOF

    if [ "$HAS_JQ" = true ]; then
        jq -r '.summary | "- **Total Flows**: \(.total)\n- **Record-Triggered**: \(.recordTriggered)\n- **Screen Flows**: \(.screenFlows)\n- **Scheduled**: \(.scheduled)"' \
            "$ANALYSIS_DIR/flow-analysis.json" >> "$OUTPUT_FILE" 2>/dev/null || echo "- (summary not available)" >> "$OUTPUT_FILE"
    else
        # Fallback: extract flow summary
        flow_total=$(extract_json_value "$ANALYSIS_DIR/flow-analysis.json" "total")
        flow_record=$(extract_json_value "$ANALYSIS_DIR/flow-analysis.json" "recordTriggered")
        flow_screen=$(extract_json_value "$ANALYSIS_DIR/flow-analysis.json" "screenFlows")
        flow_scheduled=$(extract_json_value "$ANALYSIS_DIR/flow-analysis.json" "scheduled")

        echo "- **Total Flows**: $flow_total" >> "$OUTPUT_FILE"
        echo "- **Record-Triggered**: $flow_record" >> "$OUTPUT_FILE"
        echo "- **Screen Flows**: $flow_screen" >> "$OUTPUT_FILE"
        echo "- **Scheduled**: $flow_scheduled" >> "$OUTPUT_FILE"
    fi

    echo "" >> "$OUTPUT_FILE"

    # Active flows by type
    cat >> "$OUTPUT_FILE" << 'EOF'
### Active Flows

| Flow Name | Type | Trigger | Object |
|-----------|------|---------|--------|
EOF

    if [ "$HAS_JQ" = true ]; then
        jq -r '.flows[] | select(.status == "Active") | "| `\(.name)` | \(.processType) | \(.triggerType) | \(.triggerObject) |"' \
            "$ANALYSIS_DIR/flow-analysis.json" 2>/dev/null | head -30 >> "$OUTPUT_FILE" || echo "| (none) | - | - | - |" >> "$OUTPUT_FILE"
    else
        # Fallback: count active flows
        active_count=$(grep -c '"status": "Active"' "$ANALYSIS_DIR/flow-analysis.json" 2>/dev/null || echo "0")
        echo "| ($active_count active flows - install jq for details) | - | - | - |" >> "$OUTPUT_FILE"
    fi

    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Footer
# -----------------------------------------------------------------------------
cat >> "$OUTPUT_FILE" << EOF
---

## How to Use This Information

1. **Copy relevant sections** to your main \`CLAUDE.md\` file
2. **Add engagement-specific details** (contacts, known issues, etc.)
3. **Keep CLAUDE.md updated** as you learn more about the org

## Key Files for Claude to Reference

When asking Claude about this org, mention:
- \`force-app/main/default/classes/\` - Apex source code
- \`force-app/main/default/triggers/\` - Trigger source code
- \`force-app/main/default/flows/\` - Flow definitions (XML)
- \`force-app/main/default/objects/\` - Object and field definitions

## Example Questions for Claude

- "Where is the Account.Name field updated in this codebase?"
- "Explain what the [ClassName] class does"
- "Review the [TriggerName] trigger for best practices"
- "What integrations exist in this org based on the HTTP callout classes?"

---

*Generated from retrieved metadata. Last updated: $(date)*
EOF

echo ""
echo -e "${GREEN}=========================================="
echo "Context generation complete!"
echo "==========================================${NC}"
echo ""
echo "Output: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "  1. Review the generated content"
echo "  2. Copy relevant sections to CLAUDE.md"
echo "  3. Add client-specific details"
echo ""
