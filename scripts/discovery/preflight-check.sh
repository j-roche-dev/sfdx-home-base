#!/bin/bash
# =============================================================================
# Pre-flight Check Script
# =============================================================================
#
# Verifies prerequisites before running discovery pipeline.
# Warns about issues but continues (non-blocking).
#
# Usage: ./preflight-check.sh <org-alias>
#
# Exit codes:
#   0 - All critical checks passed (may have warnings)
#   1 - Critical failure (sf CLI missing or org not authenticated)
#
# =============================================================================

set -uo pipefail

ORG_ALIAS="${1:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Status symbols
CHECK="✓"
WARN="!"
FAIL="✗"

WARNINGS=0
CRITICAL_FAIL=false

check_pass() {
    echo -e "  [${GREEN}${CHECK}${NC}] $1"
}

check_warn() {
    echo -e "  [${YELLOW}${WARN}${NC}] $1"
    ((WARNINGS++))
}

check_fail() {
    echo -e "  [${RED}${FAIL}${NC}] $1"
    CRITICAL_FAIL=true
}

usage() {
    echo "Usage: $0 <org-alias>"
    echo ""
    echo "Verifies prerequisites for discovery pipeline."
    echo ""
    exit 1
}

# =============================================================================
# Main
# =============================================================================

if [ -z "$ORG_ALIAS" ]; then
    usage
fi

echo ""
echo -e "${CYAN}Pre-flight Check for: ${NC}$ORG_ALIAS"
echo "=========================================="

# -----------------------------------------------------------------------------
# Check 1: Salesforce CLI
# -----------------------------------------------------------------------------
if command -v sf &> /dev/null; then
    SF_VERSION=$(sf --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    check_pass "sf CLI installed (v$SF_VERSION)"
else
    check_fail "sf CLI not installed"
    echo "      Install: https://developer.salesforce.com/tools/salesforcecli"
fi

# -----------------------------------------------------------------------------
# Check 2: jq (optional but recommended)
# -----------------------------------------------------------------------------
if command -v jq &> /dev/null; then
    JQ_VERSION=$(jq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' || echo "unknown")
    check_pass "jq installed (v$JQ_VERSION)"
else
    check_warn "jq not installed (some features will be limited)"
    echo "      Install: sudo apt install jq (Linux) or brew install jq (macOS)"
fi

# -----------------------------------------------------------------------------
# Check 3: Org Authentication
# -----------------------------------------------------------------------------
if [ "$CRITICAL_FAIL" = false ]; then
    if sf org display --target-org "$ORG_ALIAS" > /dev/null 2>&1; then
        # Get org info
        ORG_INFO=$(sf org display --target-org "$ORG_ALIAS" --json 2>/dev/null)

        # Extract username and instance (with jq fallback)
        if command -v jq &> /dev/null; then
            USERNAME=$(echo "$ORG_INFO" | jq -r '.result.username // "Unknown"')
            INSTANCE=$(echo "$ORG_INFO" | jq -r '.result.instanceUrl // "Unknown"')
        else
            USERNAME=$(echo "$ORG_INFO" | grep -oP '"username":\s*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' | head -1)
            INSTANCE=$(echo "$ORG_INFO" | grep -oP '"instanceUrl":\s*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' | head -1)
            [ -z "$USERNAME" ] && USERNAME="Unknown"
            [ -z "$INSTANCE" ] && INSTANCE="Unknown"
        fi

        check_pass "Org authenticated: $USERNAME"
        echo "      Instance: $INSTANCE"
    else
        check_fail "Org '$ORG_ALIAS' not authenticated"
        echo "      Run: sf org login web --alias $ORG_ALIAS"
    fi
fi

# -----------------------------------------------------------------------------
# Check 4: Output Directories Writable
# -----------------------------------------------------------------------------
OUTPUT_DIRS=("force-app/main/default" "docs/discovery" "logs")
ALL_WRITABLE=true

for dir in "${OUTPUT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        if [ -w "$dir" ]; then
            continue
        else
            ALL_WRITABLE=false
            break
        fi
    else
        # Directory doesn't exist, try to create it
        if mkdir -p "$dir" 2>/dev/null; then
            continue
        else
            ALL_WRITABLE=false
            break
        fi
    fi
done

if [ "$ALL_WRITABLE" = true ]; then
    check_pass "Output directories writable"
else
    check_warn "Some output directories may not be writable"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo "=========================================="

if [ "$CRITICAL_FAIL" = true ]; then
    echo -e "${RED}Critical checks failed. Cannot proceed.${NC}"
    echo ""
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}$WARNINGS warning(s) - proceeding with limited functionality${NC}"
    echo ""
    exit 0
else
    echo -e "${GREEN}All checks passed. Ready to proceed.${NC}"
    echo ""
    exit 0
fi
