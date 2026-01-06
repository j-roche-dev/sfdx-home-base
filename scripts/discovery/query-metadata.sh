#!/bin/bash
# =============================================================================
# Salesforce Org Discovery - Metadata Query Script
# =============================================================================
#
# Usage: ./query-metadata.sh <org-alias> [output-dir]
#
# This script QUERIES metadata information from a Salesforce org via SOQL.
# It produces JSON files with inventory data (counts, names, descriptions).
#
# NOTE: This does NOT retrieve actual source files. For source retrieval,
# use retrieve-all-metadata.sh which pulls files into force-app/.
#
# All outputs are JSON files that can be parsed by generate-report.sh.
#
# Prerequisites:
#   - Salesforce CLI (sf) installed
#   - Authenticated to target org: sf org login web --alias <alias>
#
# =============================================================================

set -e

# Configuration
ORG_ALIAS="${1:-}"
OUTPUT_DIR="${2:-docs/discovery/metadata-inventory}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Usage
if [ -z "$ORG_ALIAS" ]; then
    echo -e "${RED}Error: Org alias is required${NC}"
    echo ""
    echo "Usage: $0 <org-alias> [output-dir]"
    echo ""
    echo "Examples:"
    echo "  $0 prod                    # Use default output directory"
    echo "  $0 dev-sb ./custom-dir     # Specify output directory"
    echo ""
    echo "Prerequisites:"
    echo "  sf org login web --alias <org-alias>"
    exit 1
fi

echo "=========================================="
echo "Salesforce Org Discovery"
echo "=========================================="
echo "Org Alias:    $ORG_ALIAS"
echo "Output Dir:   $OUTPUT_DIR"
echo "Timestamp:    $TIMESTAMP"
echo "=========================================="
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to run a query and save results
run_query() {
    local description="$1"
    local query="$2"
    local output_file="$3"

    echo -n "  $description... "
    if sf data query --query "$query" --target-org "$ORG_ALIAS" --json > "$OUTPUT_DIR/$output_file" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}SKIPPED${NC} (query may not be supported)"
    fi
}

# Function to run a CLI command and save results
run_command() {
    local description="$1"
    local output_file="$2"
    shift 2

    echo -n "  $description... "
    if "$@" --target-org "$ORG_ALIAS" --json > "$OUTPUT_DIR/$output_file" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}SKIPPED${NC}"
    fi
}

# -----------------------------------------------------------------------------
# 1. Org Information
# -----------------------------------------------------------------------------
echo "[1/10] Org Information"
run_command "Org details" "org-info.json" sf org display

# -----------------------------------------------------------------------------
# 2. Custom Objects Inventory
# -----------------------------------------------------------------------------
echo "[2/10] Objects"
run_command "Custom objects" "custom-objects.json" sf sobject list --sobject-type custom
run_command "All sObjects" "all-sobjects.json" sf sobject list --sobject-type all

# -----------------------------------------------------------------------------
# 3. Apex Classes
# -----------------------------------------------------------------------------
echo "[3/10] Apex Classes"
run_query "Apex classes" \
    "SELECT Id, Name, Status, IsValid, LengthWithoutComments, ApiVersion, NamespacePrefix, CreatedDate, LastModifiedDate FROM ApexClass ORDER BY Name" \
    "apex-classes.json"

# -----------------------------------------------------------------------------
# 4. Apex Triggers
# -----------------------------------------------------------------------------
echo "[4/10] Apex Triggers"
run_query "Apex triggers" \
    "SELECT Id, Name, Status, IsValid, TableEnumOrId, UsageBeforeInsert, UsageAfterInsert, UsageBeforeUpdate, UsageAfterUpdate, UsageBeforeDelete, UsageAfterDelete, UsageAfterUndelete, ApiVersion, NamespacePrefix FROM ApexTrigger ORDER BY TableEnumOrId, Name" \
    "apex-triggers.json"

# -----------------------------------------------------------------------------
# 5. Flows
# -----------------------------------------------------------------------------
echo "[5/10] Flows"
run_query "Active flows" \
    "SELECT Id, MasterLabel, DeveloperName, ProcessType, TriggerType, Status, Description, ApiVersion, LastModifiedDate FROM FlowDefinitionView WHERE IsActive = true ORDER BY ProcessType, MasterLabel" \
    "flows.json"

# -----------------------------------------------------------------------------
# 6. Validation Rules
# -----------------------------------------------------------------------------
echo "[6/10] Validation Rules"
run_query "Validation rules" \
    "SELECT Id, EntityDefinition.QualifiedApiName, ValidationName, Active, Description, ErrorMessage FROM ValidationRule WHERE Active = true ORDER BY EntityDefinition.QualifiedApiName" \
    "validation-rules.json"

# -----------------------------------------------------------------------------
# 7. Installed Packages
# -----------------------------------------------------------------------------
echo "[7/10] Installed Packages"
run_command "Installed packages" "installed-packages.json" sf package installed list

# -----------------------------------------------------------------------------
# 8. Named Credentials & Remote Sites
# -----------------------------------------------------------------------------
echo "[8/10] Integration Configuration"
run_query "Named Credentials" \
    "SELECT Id, MasterLabel, DeveloperName, Endpoint FROM NamedCredential ORDER BY MasterLabel" \
    "named-credentials.json"

run_query "Connected Apps" \
    "SELECT Id, Name, ContactEmail, Description, MasterLabel FROM ConnectedApplication ORDER BY Name" \
    "connected-apps.json"

# -----------------------------------------------------------------------------
# 9. Permission Sets
# -----------------------------------------------------------------------------
echo "[9/10] Security Configuration"
run_query "Permission Sets" \
    "SELECT Id, Name, Label, Description, IsCustom, NamespacePrefix, Type FROM PermissionSet WHERE IsOwnedByProfile = false ORDER BY Label" \
    "permission-sets.json"

run_query "Profiles" \
    "SELECT Id, Name, UserType FROM Profile ORDER BY Name" \
    "profiles.json"

# -----------------------------------------------------------------------------
# 10. User Information
# -----------------------------------------------------------------------------
echo "[10/10] Users"
run_query "Active users" \
    "SELECT Id, Name, Username, Email, Profile.Name, IsActive, LastLoginDate FROM User WHERE IsActive = true ORDER BY LastLoginDate DESC NULLS LAST" \
    "active-users.json"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "=========================================="
echo -e "${GREEN}Discovery complete!${NC}"
echo "=========================================="
echo ""
echo "Output files saved to: $OUTPUT_DIR"
echo ""
echo "Files created:"
ls -la "$OUTPUT_DIR"/*.json 2>/dev/null | awk '{print "  " $NF}'
echo ""
echo "Next steps:"
echo "  1. Run ./scripts/discovery/generate-report.sh to create markdown report"
echo "  2. Run individual inventory scripts for deeper analysis:"
echo "     - ./scripts/discovery/inventory-objects.sh $ORG_ALIAS"
echo "     - ./scripts/discovery/inventory-automation.sh $ORG_ALIAS"
echo "     - ./scripts/discovery/inventory-integrations.sh $ORG_ALIAS"
echo "     - ./scripts/discovery/inventory-security.sh $ORG_ALIAS"
echo "  3. Review outputs and update docs/ with findings"
echo "  4. Update CLAUDE.md with key context"
echo "=========================================="
