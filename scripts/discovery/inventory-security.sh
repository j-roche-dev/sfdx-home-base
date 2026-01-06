#!/bin/bash
# =============================================================================
# Security Model Inventory
# =============================================================================
#
# Usage: ./inventory-security.sh <org-alias>
#
# This script discovers security-related configuration including Profiles,
# Permission Sets, Permission Set Groups, and sharing configuration.
#
# =============================================================================

set -e

ORG_ALIAS="${1:-}"
OUTPUT_DIR="docs/discovery/metadata-inventory/security"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$ORG_ALIAS" ]; then
    echo -e "${RED}Error: Org alias is required${NC}"
    echo ""
    echo "Usage: $0 <org-alias>"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "=========================================="
echo "Security Model Inventory"
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
        COUNT=$(jq '.result.records | length' "$OUTPUT_DIR/$output_file" 2>/dev/null || echo "0")
        echo -e "${GREEN}OK${NC} ($COUNT found)"
    else
        echo -e "${YELLOW}SKIPPED${NC}"
    fi
}

# -----------------------------------------------------------------------------
# Profiles
# -----------------------------------------------------------------------------
echo "[1/7] Profiles"
run_query "All profiles" \
    "SELECT Id, Name, Description, UserType FROM Profile ORDER BY Name" \
    "profiles.json"

run_query "Profile user counts" \
    "SELECT Profile.Name, COUNT(Id) UserCount FROM User WHERE IsActive = true GROUP BY Profile.Name ORDER BY COUNT(Id) DESC" \
    "profile-user-counts.json"

# -----------------------------------------------------------------------------
# Permission Sets
# -----------------------------------------------------------------------------
echo ""
echo "[2/7] Permission Sets"
run_query "Custom permission sets" \
    "SELECT Id, Name, Label, Description, IsCustom, NamespacePrefix, Type, LicenseId FROM PermissionSet WHERE IsOwnedByProfile = false ORDER BY Label" \
    "permission-sets.json"

run_query "Permission set assignments" \
    "SELECT PermissionSet.Label, COUNT(AssigneeId) AssignmentCount FROM PermissionSetAssignment WHERE PermissionSet.IsOwnedByProfile = false GROUP BY PermissionSet.Label ORDER BY COUNT(AssigneeId) DESC" \
    "permission-set-assignments.json"

# -----------------------------------------------------------------------------
# Permission Set Groups
# -----------------------------------------------------------------------------
echo ""
echo "[3/7] Permission Set Groups"
run_query "Permission set groups" \
    "SELECT Id, MasterLabel, DeveloperName, Description, Status FROM PermissionSetGroup ORDER BY MasterLabel" \
    "permission-set-groups.json"

# -----------------------------------------------------------------------------
# Roles
# -----------------------------------------------------------------------------
echo ""
echo "[4/7] Role Hierarchy"
run_query "User roles" \
    "SELECT Id, Name, DeveloperName, ParentRoleId, RollupDescription FROM UserRole ORDER BY Name" \
    "roles.json"

# -----------------------------------------------------------------------------
# Groups & Queues
# -----------------------------------------------------------------------------
echo ""
echo "[5/7] Groups & Queues"
run_query "Public groups" \
    "SELECT Id, Name, DeveloperName, Type, DoesIncludeBosses FROM Group WHERE Type IN ('Regular', 'Role', 'RoleAndSubordinates', 'Queue') ORDER BY Type, Name" \
    "groups-and-queues.json"

# -----------------------------------------------------------------------------
# Sharing Rules (limited - full detail requires metadata API)
# -----------------------------------------------------------------------------
echo ""
echo "[6/7] Sharing Configuration"
# Note: Detailed sharing rules require Metadata API retrieval
run_query "Organization-wide defaults hint" \
    "SELECT Id, QualifiedApiName FROM EntityDefinition WHERE IsCustomizable = true AND QualifiedApiName LIKE '%__c' ORDER BY QualifiedApiName LIMIT 50" \
    "custom-objects-for-owd.json"

# -----------------------------------------------------------------------------
# Login & Session Settings
# -----------------------------------------------------------------------------
echo ""
echo "[7/7] User Access"
run_query "Active users by profile" \
    "SELECT Profile.Name ProfileName, COUNT(Id) UserCount, MAX(LastLoginDate) LastLogin FROM User WHERE IsActive = true GROUP BY Profile.Name ORDER BY COUNT(Id) DESC" \
    "users-by-profile.json"

run_query "Recent logins" \
    "SELECT UserId, User.Name, LoginTime, Status, SourceIp, Application FROM LoginHistory WHERE LoginTime = LAST_N_DAYS:7 ORDER BY LoginTime DESC LIMIT 100" \
    "recent-logins.json"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "=========================================="
echo -e "${GREEN}Security inventory complete${NC}"
echo "=========================================="
echo ""
echo "Summary:"

for file in "$OUTPUT_DIR"/*.json; do
    if [ -f "$file" ]; then
        name=$(basename "$file" .json)
        count=$(jq '.result.records | length' "$file" 2>/dev/null || echo "N/A")
        echo "  $name: $count"
    fi
done

echo ""
echo "Output saved to: $OUTPUT_DIR"
echo ""
echo "Note: Full OWD and sharing rule details require Metadata API retrieval."
echo "Consider running:"
echo "  sf project retrieve start --metadata 'SharingRules' --target-org $ORG_ALIAS"
echo ""
echo "Next: Update docs/architecture/security-model.md with findings"
