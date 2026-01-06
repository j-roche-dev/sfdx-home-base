#!/bin/bash
# =============================================================================
# Generate Human-Readable Discovery Report
# =============================================================================
#
# Usage: ./generate-report.sh [input-dir]
#
# This script parses JSON outputs from discovery scripts and generates a
# markdown report suitable for review and documentation.
#
# =============================================================================

INPUT_DIR="${1:-docs/discovery/metadata-inventory}"
OUTPUT_FILE="docs/discovery/analysis/discovery-report.md"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo "Generating discovery report..."
echo "Input:  $INPUT_DIR"
echo "Output: $OUTPUT_FILE"
echo ""

mkdir -p "$(dirname "$OUTPUT_FILE")"

# Start report
cat > "$OUTPUT_FILE" << EOF
# Salesforce Org Discovery Report

**Generated**: $TIMESTAMP
**Source**: $INPUT_DIR

---

EOF

# -----------------------------------------------------------------------------
# Org Info
# -----------------------------------------------------------------------------
if [ -f "$INPUT_DIR/org-info.json" ]; then
    echo "Processing org info..."
    cat >> "$OUTPUT_FILE" << 'EOF'
## Org Information

EOF
    # Extract key fields
    jq -r '.result | "| Field | Value |\n|-------|-------|\n| Username | \(.username // "N/A") |\n| Org ID | \(.id // "N/A") |\n| Instance URL | \(.instanceUrl // "N/A") |\n| API Version | \(.apiVersion // "N/A") |"' "$INPUT_DIR/org-info.json" >> "$OUTPUT_FILE" 2>/dev/null || echo "Unable to parse org info" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Custom Objects
# -----------------------------------------------------------------------------
if [ -f "$INPUT_DIR/custom-objects.json" ]; then
    echo "Processing custom objects..."
    COUNT=$(jq '.result | length' "$INPUT_DIR/custom-objects.json" 2>/dev/null || echo "0")
    cat >> "$OUTPUT_FILE" << EOF
## Custom Objects

**Total**: $COUNT custom objects

| Object API Name |
|-----------------|
EOF
    jq -r '.result[] | "| \(.) |"' "$INPUT_DIR/custom-objects.json" >> "$OUTPUT_FILE" 2>/dev/null || true
    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Apex Classes
# -----------------------------------------------------------------------------
if [ -f "$INPUT_DIR/apex-classes.json" ]; then
    echo "Processing Apex classes..."
    TOTAL=$(jq '.result.records | length' "$INPUT_DIR/apex-classes.json" 2>/dev/null || echo "0")
    CUSTOM=$(jq '[.result.records[] | select(.NamespacePrefix == null)] | length' "$INPUT_DIR/apex-classes.json" 2>/dev/null || echo "0")

    cat >> "$OUTPUT_FILE" << EOF
## Apex Classes

**Total**: $TOTAL classes ($CUSTOM custom, $((TOTAL - CUSTOM)) from packages)

### Custom Apex Classes (non-namespaced)

| Name | Status | API Version | Lines (excl. comments) |
|------|--------|-------------|------------------------|
EOF
    jq -r '.result.records[] | select(.NamespacePrefix == null) | "| \(.Name) | \(.Status) | \(.ApiVersion) | \(.LengthWithoutComments // "N/A") |"' "$INPUT_DIR/apex-classes.json" >> "$OUTPUT_FILE" 2>/dev/null || true
    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Apex Triggers
# -----------------------------------------------------------------------------
if [ -f "$INPUT_DIR/apex-triggers.json" ]; then
    echo "Processing Apex triggers..."
    COUNT=$(jq '[.result.records[] | select(.NamespacePrefix == null)] | length' "$INPUT_DIR/apex-triggers.json" 2>/dev/null || echo "0")

    cat >> "$OUTPUT_FILE" << EOF
## Apex Triggers

**Total Custom Triggers**: $COUNT

| Trigger | Object | Before Insert | After Insert | Before Update | After Update | Before Delete | After Delete |
|---------|--------|---------------|--------------|---------------|--------------|---------------|--------------|
EOF
    jq -r '.result.records[] | select(.NamespacePrefix == null) | "| \(.Name) | \(.TableEnumOrId) | \(if .UsageBeforeInsert then "X" else "" end) | \(if .UsageAfterInsert then "X" else "" end) | \(if .UsageBeforeUpdate then "X" else "" end) | \(if .UsageAfterUpdate then "X" else "" end) | \(if .UsageBeforeDelete then "X" else "" end) | \(if .UsageAfterDelete then "X" else "" end) |"' "$INPUT_DIR/apex-triggers.json" >> "$OUTPUT_FILE" 2>/dev/null || true
    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Flows
# -----------------------------------------------------------------------------
if [ -f "$INPUT_DIR/flows.json" ]; then
    echo "Processing flows..."
    COUNT=$(jq '.result.records | length' "$INPUT_DIR/flows.json" 2>/dev/null || echo "0")

    cat >> "$OUTPUT_FILE" << EOF
## Active Flows

**Total**: $COUNT active flows

| Flow Name | Type | Trigger Type | API Version |
|-----------|------|--------------|-------------|
EOF
    jq -r '.result.records[] | "| \(.MasterLabel) | \(.ProcessType) | \(.TriggerType // "Manual/Screen") | \(.ApiVersion) |"' "$INPUT_DIR/flows.json" >> "$OUTPUT_FILE" 2>/dev/null || true
    echo "" >> "$OUTPUT_FILE"

    # Flow type breakdown
    cat >> "$OUTPUT_FILE" << EOF

### Flow Type Breakdown

EOF
    jq -r '[.result.records[] | .ProcessType] | group_by(.) | map({type: .[0], count: length}) | .[] | "- \(.type): \(.count)"' "$INPUT_DIR/flows.json" >> "$OUTPUT_FILE" 2>/dev/null || true
    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Installed Packages
# -----------------------------------------------------------------------------
if [ -f "$INPUT_DIR/installed-packages.json" ]; then
    echo "Processing installed packages..."
    COUNT=$(jq '.result | length' "$INPUT_DIR/installed-packages.json" 2>/dev/null || echo "0")

    cat >> "$OUTPUT_FILE" << EOF
## Installed Packages

**Total**: $COUNT packages

| Package Name | Namespace | Version |
|--------------|-----------|---------|
EOF
    jq -r '.result[] | "| \(.SubscriberPackageName) | \(.SubscriberPackageNamespace // "-") | \(.SubscriberPackageVersionNumber) |"' "$INPUT_DIR/installed-packages.json" >> "$OUTPUT_FILE" 2>/dev/null || true
    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Named Credentials
# -----------------------------------------------------------------------------
if [ -f "$INPUT_DIR/named-credentials.json" ]; then
    echo "Processing named credentials..."
    COUNT=$(jq '.result.records | length' "$INPUT_DIR/named-credentials.json" 2>/dev/null || echo "0")

    cat >> "$OUTPUT_FILE" << EOF
## Named Credentials (Integration Points)

**Total**: $COUNT named credentials

| Name | Endpoint |
|------|----------|
EOF
    jq -r '.result.records[] | "| \(.MasterLabel) | \(.Endpoint) |"' "$INPUT_DIR/named-credentials.json" >> "$OUTPUT_FILE" 2>/dev/null || true
    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Permission Sets
# -----------------------------------------------------------------------------
if [ -f "$INPUT_DIR/permission-sets.json" ]; then
    echo "Processing permission sets..."
    TOTAL=$(jq '.result.records | length' "$INPUT_DIR/permission-sets.json" 2>/dev/null || echo "0")
    CUSTOM=$(jq '[.result.records[] | select(.IsCustom == true and .NamespacePrefix == null)] | length' "$INPUT_DIR/permission-sets.json" 2>/dev/null || echo "0")

    cat >> "$OUTPUT_FILE" << EOF
## Permission Sets

**Total**: $TOTAL permission sets ($CUSTOM custom)

### Custom Permission Sets

| Label | API Name | Type |
|-------|----------|------|
EOF
    jq -r '.result.records[] | select(.IsCustom == true and .NamespacePrefix == null) | "| \(.Label) | \(.Name) | \(.Type // "Regular") |"' "$INPUT_DIR/permission-sets.json" >> "$OUTPUT_FILE" 2>/dev/null || true
    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Active Users
# -----------------------------------------------------------------------------
if [ -f "$INPUT_DIR/active-users.json" ]; then
    echo "Processing users..."
    COUNT=$(jq '.result.records | length' "$INPUT_DIR/active-users.json" 2>/dev/null || echo "0")

    cat >> "$OUTPUT_FILE" << EOF
## Active Users

**Total**: $COUNT active users

### Recently Active Users (by last login)

| Name | Profile | Last Login |
|------|---------|------------|
EOF
    jq -r '.result.records[0:20] | .[] | "| \(.Name) | \(.Profile.Name // "N/A") | \(.LastLoginDate // "Never") |"' "$INPUT_DIR/active-users.json" >> "$OUTPUT_FILE" 2>/dev/null || true
    echo "" >> "$OUTPUT_FILE"
fi

# -----------------------------------------------------------------------------
# Footer
# -----------------------------------------------------------------------------
cat >> "$OUTPUT_FILE" << EOF
---

## Next Steps

1. Review this report for anomalies or areas of concern
2. Run detailed inventory scripts for deeper analysis:
   - \`./scripts/discovery/inventory-objects.sh\` - Detailed object/field info
   - \`./scripts/discovery/inventory-automation.sh\` - Automation breakdown
   - \`./scripts/discovery/inventory-integrations.sh\` - Integration details
   - \`./scripts/discovery/inventory-security.sh\` - Security model
3. Update documentation in \`docs/\` with findings
4. Update \`CLAUDE.md\` with key context

---

*This report was auto-generated. Review and validate before relying on this data.*
EOF

echo ""
echo -e "${GREEN}Report generated successfully!${NC}"
echo ""
echo "Output: $OUTPUT_FILE"
echo ""
echo "Open with:"
echo "  cat $OUTPUT_FILE"
echo "  code $OUTPUT_FILE"
