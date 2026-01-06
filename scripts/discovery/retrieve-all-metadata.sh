#!/bin/bash
# =============================================================================
# Comprehensive Metadata Retrieval Script
# =============================================================================
#
# Actually retrieves source files into force-app/main/default/ using
# sf project retrieve start. Handles large orgs via chunked retrieval.
#
# Usage: ./retrieve-all-metadata.sh <org-alias>
#
# =============================================================================

set -euo pipefail

# Configuration
ORG_ALIAS="${1:-}"
OUTPUT_DIR="force-app/main/default"
LOG_DIR="logs/retrieval"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Metadata Type Groups (chunked to avoid timeouts)
# =============================================================================

# Group 1: Apex Code
APEX_TYPES="ApexClass,ApexTrigger,ApexComponent,ApexPage,ApexTestSuite"

# Group 2: Lightning Components
LIGHTNING_TYPES="LightningComponentBundle,AuraDefinitionBundle,LightningMessageChannel"

# Group 3: Custom Objects (retrieved separately - can be large)
# Will use wildcard: CustomObject

# Group 4: Automation
AUTOMATION_TYPES="Flow,WorkflowRule,WorkflowFieldUpdate,WorkflowAlert,WorkflowTask"

# Group 5: Security
SECURITY_TYPES="Profile,PermissionSet,PermissionSetGroup"

# Group 6: App Configuration
APP_TYPES="CustomApplication,FlexiPage,CustomTab,Layout,CustomLabel,HomePageLayout"

# Group 7: Integration & Platform
INTEGRATION_TYPES="NamedCredential,ExternalDataSource,RemoteSiteSetting,ConnectedApp,CustomMetadata,PlatformEventChannel"

# Group 8: Reports & Dashboards
REPORT_TYPES="Report,Dashboard,ReportType"

# Group 9: Email & Documents
EMAIL_TYPES="EmailTemplate,Letterhead,Document,StaticResource"

# Group 10: Other common types
OTHER_TYPES="CustomPermission,Queue,Group,Role,GlobalValueSet,StandardValueSet,QuickAction,CompactLayout,RecordType"

# =============================================================================
# Functions
# =============================================================================

usage() {
    echo "Usage: $0 <org-alias>"
    echo ""
    echo "Retrieves ALL metadata from a Salesforce org into force-app/main/default/"
    echo ""
    echo "Examples:"
    echo "  $0 prod          # Retrieve from production"
    echo "  $0 dev-sandbox   # Retrieve from sandbox"
    echo ""
    echo "Prerequisites:"
    echo "  sf org login web --alias <org-alias>"
    exit 1
}

log() {
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1"
}

success() {
    echo -e "${GREEN}$1${NC}"
}

warning() {
    echo -e "${YELLOW}$1${NC}"
}

error() {
    echo -e "${RED}$1${NC}"
}

# Check if jq is available
has_jq() {
    command -v jq &> /dev/null
}

# Parse JSON field without jq (fallback)
parse_json_field() {
    local json="$1"
    local field="$2"
    # Simple grep-based extraction for basic JSON
    echo "$json" | grep -oP "\"$field\":\s*\"[^\"]*\"" | sed -E "s/\"$field\":\s*\"([^\"]*)\"/\1/" | head -1
}

# Verify org connection
verify_org() {
    log "Verifying connection to org: $ORG_ALIAS"

    if ! sf org display --target-org "$ORG_ALIAS" > /dev/null 2>&1; then
        error "ERROR: Cannot connect to org '$ORG_ALIAS'"
        echo "Please authenticate first:"
        echo "  sf org login web --alias $ORG_ALIAS"
        exit 1
    fi

    # Get org info
    local org_info
    org_info=$(sf org display --target-org "$ORG_ALIAS" --json 2>/dev/null)

    local username instance
    if has_jq; then
        username=$(echo "$org_info" | jq -r '.result.username // "Unknown"')
        instance=$(echo "$org_info" | jq -r '.result.instanceUrl // "Unknown"')
    else
        username=$(parse_json_field "$org_info" "username")
        instance=$(parse_json_field "$org_info" "instanceUrl")
        [ -z "$username" ] && username="Unknown"
        [ -z "$instance" ] && instance="Unknown"
    fi

    success "Connected to: $username"
    echo "  Instance: $instance"
    echo ""
}

# Retrieve a group of metadata types
retrieve_group() {
    local group_name="$1"
    local metadata_types="$2"
    local log_file="$LOG_DIR/${TIMESTAMP}_${group_name}.log"

    echo -n "  [$group_name] "

    # Build -m flags for each metadata type (sf CLI requires separate -m for each type)
    local metadata_flags=""
    IFS=',' read -ra TYPES <<< "$metadata_types"
    for type in "${TYPES[@]}"; do
        metadata_flags="$metadata_flags -m $type"
    done

    # Run retrieve and capture output
    local output
    local exit_code=0

    output=$(sf project retrieve start \
        $metadata_flags \
        --target-org "$ORG_ALIAS" \
        --wait 30 \
        2>&1) || exit_code=$?

    # Save full output to log
    echo "$output" > "$log_file"

    if [ $exit_code -eq 0 ]; then
        # Count retrieved files from output
        local count=$(echo "$output" | grep -oE '[0-9]+ (component|file)' | head -1 | grep -oE '[0-9]+' || echo "?")
        success "OK ($count components)"
        return 0
    else
        # Check if it's a "no components" situation vs actual error
        if echo "$output" | grep -qi "no source-backed components\|no components\|nothing to retrieve"; then
            warning "SKIPPED (no components of this type)"
            return 0
        elif echo "$output" | grep -qi "Missing metadata type definition"; then
            # Some types don't exist in all orgs - not a fatal error
            warning "SKIPPED (type not available)"
            return 0
        else
            error "FAILED (see $log_file)"
            return 1
        fi
    fi
}

# Retrieve custom objects with their children (fields, validation rules, etc.)
retrieve_custom_objects() {
    local log_file="$LOG_DIR/${TIMESTAMP}_CustomObjects.log"

    echo -n "  [CustomObjects] "

    # First, get list of custom objects
    local objects_json
    objects_json=$(sf sobject list --sobject-type custom --target-org "$ORG_ALIAS" --json 2>/dev/null) || true

    local objects
    if has_jq; then
        objects=$(echo "$objects_json" | jq -r '.result[]' 2>/dev/null | grep "__c$" || true)
    else
        # Fallback: extract object names without jq
        objects=$(echo "$objects_json" | grep -oE '"[A-Za-z0-9_]+__c"' | tr -d '"' | sort -u || true)
    fi

    if [ -z "$objects" ]; then
        warning "SKIPPED (no custom objects found)"
        return 0
    fi

    local total=$(echo "$objects" | wc -l)
    echo -n "found $total objects... "

    # Build -m flags for custom objects
    local metadata_flags=""
    while IFS= read -r obj; do
        [ -z "$obj" ] && continue
        metadata_flags="$metadata_flags -m CustomObject:${obj}"
    done <<< "$objects"

    # Retrieve with multiple -m flags
    local output
    local exit_code=0

    output=$(sf project retrieve start \
        $metadata_flags \
        --target-org "$ORG_ALIAS" \
        --wait 60 \
        2>&1) || exit_code=$?

    echo "$output" > "$log_file"

    if [ $exit_code -eq 0 ]; then
        success "OK"
        return 0
    else
        if echo "$output" | grep -qi "no source-backed\|nothing to retrieve"; then
            warning "PARTIAL (some objects may not have source-trackable metadata)"
            return 0
        else
            error "FAILED (see $log_file)"
            return 1
        fi
    fi
}

# Retrieve standard object customizations (custom fields on Account, Contact, etc.)
retrieve_standard_object_customizations() {
    local log_file="$LOG_DIR/${TIMESTAMP}_StandardObjects.log"

    echo -n "  [StandardObjectCustomizations] "

    # Common standard objects that often have customizations
    local std_objects="Account Contact Opportunity Case Lead Task Event User"
    local metadata_flags=""

    for obj in $std_objects; do
        metadata_flags="$metadata_flags -m CustomObject:${obj}"
    done

    local output
    local exit_code=0

    output=$(sf project retrieve start \
        $metadata_flags \
        --target-org "$ORG_ALIAS" \
        --wait 30 \
        2>&1) || exit_code=$?

    echo "$output" > "$log_file"

    if [ $exit_code -eq 0 ]; then
        success "OK"
        return 0
    else
        if echo "$output" | grep -qi "no source-backed\|nothing to retrieve"; then
            warning "SKIPPED (no customizations or not retrievable)"
            return 0
        else
            warning "PARTIAL (see $log_file)"
            return 0
        fi
    fi
}

# Generate a package.xml manifest for everything
generate_manifest() {
    local manifest_file="manifest/full-package.xml"

    log "Generating manifest file..."

    mkdir -p manifest

    cat > "$manifest_file" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>*</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>*</members>
        <name>ApexTrigger</name>
    </types>
    <types>
        <members>*</members>
        <name>ApexComponent</name>
    </types>
    <types>
        <members>*</members>
        <name>ApexPage</name>
    </types>
    <types>
        <members>*</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>*</members>
        <name>AuraDefinitionBundle</name>
    </types>
    <types>
        <members>*</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>*</members>
        <name>Flow</name>
    </types>
    <types>
        <members>*</members>
        <name>PermissionSet</name>
    </types>
    <types>
        <members>*</members>
        <name>Profile</name>
    </types>
    <types>
        <members>*</members>
        <name>CustomApplication</name>
    </types>
    <types>
        <members>*</members>
        <name>FlexiPage</name>
    </types>
    <types>
        <members>*</members>
        <name>Layout</name>
    </types>
    <types>
        <members>*</members>
        <name>CustomTab</name>
    </types>
    <types>
        <members>*</members>
        <name>CustomLabel</name>
    </types>
    <types>
        <members>*</members>
        <name>StaticResource</name>
    </types>
    <types>
        <members>*</members>
        <name>NamedCredential</name>
    </types>
    <types>
        <members>*</members>
        <name>RemoteSiteSetting</name>
    </types>
    <types>
        <members>*</members>
        <name>Report</name>
    </types>
    <types>
        <members>*</members>
        <name>Dashboard</name>
    </types>
    <types>
        <members>*</members>
        <name>EmailTemplate</name>
    </types>
    <types>
        <members>*</members>
        <name>CustomMetadata</name>
    </types>
    <types>
        <members>*</members>
        <name>QuickAction</name>
    </types>
    <types>
        <members>*</members>
        <name>RecordType</name>
    </types>
    <types>
        <members>*</members>
        <name>CompactLayout</name>
    </types>
    <types>
        <members>*</members>
        <name>GlobalValueSet</name>
    </types>
    <version>65.0</version>
</Package>
EOF

    success "  Created $manifest_file"
}

# Print summary of retrieved files
print_summary() {
    echo ""
    log "Retrieval Summary"
    echo "=========================================="

    # Count files by type
    local apex_count=$(find "$OUTPUT_DIR/classes" -name "*.cls" 2>/dev/null | wc -l || echo "0")
    local trigger_count=$(find "$OUTPUT_DIR/triggers" -name "*.trigger" 2>/dev/null | wc -l || echo "0")
    local lwc_count=$(find "$OUTPUT_DIR/lwc" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l || echo "0")
    local aura_count=$(find "$OUTPUT_DIR/aura" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l || echo "0")
    local flow_count=$(find "$OUTPUT_DIR/flows" -name "*.flow-meta.xml" 2>/dev/null | wc -l || echo "0")
    local object_count=$(find "$OUTPUT_DIR/objects" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l || echo "0")
    local permset_count=$(find "$OUTPUT_DIR/permissionsets" -name "*.permissionset-meta.xml" 2>/dev/null | wc -l || echo "0")
    local profile_count=$(find "$OUTPUT_DIR/profiles" -name "*.profile-meta.xml" 2>/dev/null | wc -l || echo "0")

    printf "  %-25s %s\n" "Apex Classes:" "$apex_count"
    printf "  %-25s %s\n" "Apex Triggers:" "$trigger_count"
    printf "  %-25s %s\n" "LWC Components:" "$lwc_count"
    printf "  %-25s %s\n" "Aura Components:" "$aura_count"
    printf "  %-25s %s\n" "Flows:" "$flow_count"
    printf "  %-25s %s\n" "Objects:" "$object_count"
    printf "  %-25s %s\n" "Permission Sets:" "$permset_count"
    printf "  %-25s %s\n" "Profiles:" "$profile_count"

    echo "=========================================="
    echo ""
    echo "Output directory: $OUTPUT_DIR"
    echo "Log files: $LOG_DIR"
}

# =============================================================================
# Main Execution
# =============================================================================

if [ -z "$ORG_ALIAS" ]; then
    usage
fi

echo "=========================================="
echo "Comprehensive Metadata Retrieval"
echo "=========================================="
echo "Org Alias:  $ORG_ALIAS"
echo "Output:     $OUTPUT_DIR"
echo "Timestamp:  $TIMESTAMP"
echo "=========================================="
echo ""

# Create directories
mkdir -p "$LOG_DIR"
mkdir -p "$OUTPUT_DIR"

# Verify org connection
verify_org

# Generate manifest (for reference)
generate_manifest

# Retrieve metadata in groups
log "Retrieving metadata by type groups..."
echo ""

# Track failures
FAILURES=0

retrieve_group "Apex" "$APEX_TYPES" || ((FAILURES++))
retrieve_group "Lightning" "$LIGHTNING_TYPES" || ((FAILURES++))
retrieve_custom_objects || ((FAILURES++))
retrieve_standard_object_customizations || ((FAILURES++))
retrieve_group "Automation" "$AUTOMATION_TYPES" || ((FAILURES++))
retrieve_group "Security" "$SECURITY_TYPES" || ((FAILURES++))
retrieve_group "Apps" "$APP_TYPES" || ((FAILURES++))
retrieve_group "Integration" "$INTEGRATION_TYPES" || ((FAILURES++))
retrieve_group "Reports" "$REPORT_TYPES" || ((FAILURES++))
retrieve_group "Email" "$EMAIL_TYPES" || ((FAILURES++))
retrieve_group "Other" "$OTHER_TYPES" || ((FAILURES++))

# Print summary
print_summary

if [ $FAILURES -gt 0 ]; then
    warning "Completed with $FAILURES group(s) having issues. Check logs for details."
else
    success "All metadata retrieved successfully!"
fi

echo ""
echo "Next steps:"
echo "  1. Run ./scripts/discovery/analyze-metadata.sh to analyze retrieved files"
echo "  2. Run ./scripts/discovery/query-metadata.sh $ORG_ALIAS for supplemental data"
echo "  3. Review force-app/main/default/ contents"
echo ""
