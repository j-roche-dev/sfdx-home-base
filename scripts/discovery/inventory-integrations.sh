#!/bin/bash
# =============================================================================
# Integration Discovery Script
# =============================================================================
#
# Usage: ./inventory-integrations.sh <org-alias>
#
# This script discovers integration-related configuration including Named
# Credentials, External Services, Connected Apps, Remote Sites, and more.
#
# =============================================================================

set -e

ORG_ALIAS="${1:-}"
OUTPUT_DIR="docs/discovery/metadata-inventory/integrations"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if jq is available
HAS_JQ=false
if command -v jq &> /dev/null; then
    HAS_JQ=true
fi

# Fallback: Count records in JSON result
count_records() {
    local file="$1"
    if [ "$HAS_JQ" = true ]; then
        jq '.result.records | length' "$file" 2>/dev/null || echo "0"
    else
        # Count "Id" occurrences in records array as proxy
        grep -c '"Id"\s*:' "$file" 2>/dev/null || echo "0"
    fi
}

if [ -z "$ORG_ALIAS" ]; then
    echo -e "${RED}Error: Org alias is required${NC}"
    echo ""
    echo "Usage: $0 <org-alias>"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "=========================================="
echo "Integration Discovery"
echo "=========================================="
echo "Org Alias: $ORG_ALIAS"
echo "Output:    $OUTPUT_DIR"
echo "=========================================="
echo ""

# Function to run query
run_query() {
    local description="$1"
    local query="$2"
    local output_file="$3"

    echo -n "  $description... "
    if sf data query --query "$query" --target-org "$ORG_ALIAS" --json > "$OUTPUT_DIR/$output_file" 2>/dev/null; then
        COUNT=$(count_records "$OUTPUT_DIR/$output_file")
        echo -e "${GREEN}OK${NC} ($COUNT found)"
    else
        echo -e "${YELLOW}SKIPPED${NC} (query may not be supported)"
    fi
}

# -----------------------------------------------------------------------------
# Named Credentials & Auth
# -----------------------------------------------------------------------------
echo "[1/8] Authentication & Credentials"
run_query "Named Credentials" \
    "SELECT Id, MasterLabel, DeveloperName, Endpoint, PrincipalType FROM NamedCredential ORDER BY MasterLabel" \
    "named-credentials.json"

run_query "Auth Providers" \
    "SELECT Id, DeveloperName, FriendlyName, ProviderType FROM AuthProvider ORDER BY FriendlyName" \
    "auth-providers.json"

# -----------------------------------------------------------------------------
# External Services
# -----------------------------------------------------------------------------
echo ""
echo "[2/8] External Services"
run_query "External Service Registrations" \
    "SELECT Id, MasterLabel, DeveloperName, Description FROM ExternalServiceRegistration ORDER BY MasterLabel" \
    "external-services.json"

# -----------------------------------------------------------------------------
# Connected Apps
# -----------------------------------------------------------------------------
echo ""
echo "[3/8] Connected Apps"
run_query "Connected Apps" \
    "SELECT Id, Name, ContactEmail, Description, MasterLabel, OptionsAllowAdminApprovedUsersOnly FROM ConnectedApplication ORDER BY Name" \
    "connected-apps.json"

# -----------------------------------------------------------------------------
# Remote Sites & CSP
# -----------------------------------------------------------------------------
echo ""
echo "[4/8] Remote Site Settings"
run_query "Remote Sites" \
    "SELECT Id, SiteName, EndpointUrl, Description, IsActive FROM RemoteProxy WHERE IsActive = true ORDER BY SiteName" \
    "remote-sites.json"

# Note: CSP Trusted Sites requires Tooling API, may not work with standard query

# -----------------------------------------------------------------------------
# Platform Events
# -----------------------------------------------------------------------------
echo ""
echo "[5/8] Platform Events"
run_query "Platform Events (Custom)" \
    "SELECT Id, QualifiedApiName, DeveloperName, Description FROM EntityDefinition WHERE IsCustomizable = true AND QualifiedApiName LIKE '%__e' ORDER BY QualifiedApiName" \
    "platform-events.json"

# -----------------------------------------------------------------------------
# Change Data Capture
# -----------------------------------------------------------------------------
echo ""
echo "[6/8] Change Data Capture"
# CDC configuration is typically in metadata, query for CDC-enabled entities
run_query "CDC Enabled Entities (approximate)" \
    "SELECT Id, QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName LIKE '%ChangeEvent' ORDER BY QualifiedApiName" \
    "cdc-entities.json"

# -----------------------------------------------------------------------------
# Outbound Messages
# -----------------------------------------------------------------------------
echo ""
echo "[7/8] Workflow Outbound Messages"
run_query "Outbound Messages" \
    "SELECT Id, Name FROM WorkflowOutboundMessage ORDER BY Name" \
    "outbound-messages.json"

# -----------------------------------------------------------------------------
# Apex Callouts (approximate - classes with Http reference)
# -----------------------------------------------------------------------------
echo ""
echo "[8/8] Apex Classes (potential callouts)"
run_query "Apex classes with Http" \
    "SELECT Id, Name, ApiVersion FROM ApexClass WHERE NamespacePrefix = null AND (Name LIKE '%Callout%' OR Name LIKE '%Integration%' OR Name LIKE '%Api%' OR Name LIKE '%Service%') ORDER BY Name" \
    "potential-integration-classes.json"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "=========================================="
echo -e "${GREEN}Integration discovery complete${NC}"
echo "=========================================="
echo ""
echo "Summary:"

for file in "$OUTPUT_DIR"/*.json; do
    if [ -f "$file" ]; then
        name=$(basename "$file" .json)
        count=$(count_records "$file")
        echo "  $name: $count"
    fi
done

echo ""
echo "Output saved to: $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "  1. Review named credentials for integration endpoints"
echo "  2. Check connected apps for OAuth integrations"
echo "  3. Review potential integration classes for callout patterns"
echo "  4. Update docs/architecture/integrations.md with findings"
