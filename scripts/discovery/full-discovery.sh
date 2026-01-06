#!/bin/bash
# =============================================================================
# Full Org Discovery - Master Orchestration Script
# =============================================================================
#
# Runs the complete discovery pipeline:
#   1. Verify org connection
#   2. Retrieve all metadata into force-app/
#   3. Run query-based inventory
#   4. Analyze retrieved metadata
#   5. Generate documentation and CLAUDE.md context
#
# Usage: ./full-discovery.sh <org-alias> [--skip-retrieve]
#
# =============================================================================

set -euo pipefail

# Configuration
ORG_ALIAS="${1:-}"
SKIP_RETRIEVE=false

# Check for --skip-retrieve flag
for arg in "$@"; do
    if [ "$arg" = "--skip-retrieve" ]; then
        SKIP_RETRIEVE=true
    fi
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging
LOG_DIR="logs/discovery"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MASTER_LOG="$LOG_DIR/${TIMESTAMP}_full-discovery.log"

log() {
    local msg="[$(date +%H:%M:%S)] $1"
    echo -e "${BLUE}${msg}${NC}"
    echo "$msg" >> "$MASTER_LOG" 2>/dev/null || true
}

success() {
    local msg="[$(date +%H:%M:%S)] $1"
    echo -e "${GREEN}${msg}${NC}"
    echo "$msg" >> "$MASTER_LOG" 2>/dev/null || true
}

warning() {
    local msg="[$(date +%H:%M:%S)] WARNING: $1"
    echo -e "${YELLOW}${msg}${NC}"
    echo "$msg" >> "$MASTER_LOG" 2>/dev/null || true
}

error() {
    local msg="[$(date +%H:%M:%S)] ERROR: $1"
    echo -e "${RED}${msg}${NC}"
    echo "$msg" >> "$MASTER_LOG" 2>/dev/null || true
}

step() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

usage() {
    echo "Usage: $0 <org-alias> [--skip-retrieve]"
    echo ""
    echo "Runs complete org discovery pipeline."
    echo ""
    echo "Options:"
    echo "  --skip-retrieve    Skip metadata retrieval (use existing force-app/)"
    echo ""
    echo "Examples:"
    echo "  $0 prod                    # Full discovery"
    echo "  $0 dev-sb --skip-retrieve  # Skip retrieval, just analyze"
    echo ""
    exit 1
}

# Check if jq is available
HAS_JQ=false
if command -v jq &> /dev/null; then
    HAS_JQ=true
fi

# Fallback JSON extraction (when jq not available)
extract_json_string() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -oP "\"$key\":\s*\"[^\"]*\"" | sed 's/.*"\([^"]*\)"$/\1/' | head -1
}

# =============================================================================
# Main
# =============================================================================

if [ -z "$ORG_ALIAS" ]; then
    usage
fi

# Create log directory
mkdir -p "$LOG_DIR"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          FULL ORG DISCOVERY PIPELINE                         ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║  Org Alias:     ${NC}$ORG_ALIAS"
echo -e "${CYAN}║  Timestamp:     ${NC}$TIMESTAMP"
echo -e "${CYAN}║  Skip Retrieve: ${NC}$SKIP_RETRIEVE"
echo -e "${CYAN}║  Log File:      ${NC}$MASTER_LOG"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Track overall status
ERRORS=0

# -----------------------------------------------------------------------------
# Step 1: Verify Org Connection
# -----------------------------------------------------------------------------
step "Step 1/6: Verifying Org Connection"

log "Connecting to $ORG_ALIAS..."

if sf org display --target-org "$ORG_ALIAS" > /dev/null 2>&1; then
    ORG_INFO=$(sf org display --target-org "$ORG_ALIAS" --json 2>/dev/null)
    if [ "$HAS_JQ" = true ]; then
        USERNAME=$(echo "$ORG_INFO" | jq -r '.result.username // "Unknown"')
        INSTANCE=$(echo "$ORG_INFO" | jq -r '.result.instanceUrl // "Unknown"')
    else
        USERNAME=$(extract_json_string "$ORG_INFO" "username")
        INSTANCE=$(extract_json_string "$ORG_INFO" "instanceUrl")
        [ -z "$USERNAME" ] && USERNAME="Unknown"
        [ -z "$INSTANCE" ] && INSTANCE="Unknown"
    fi
    success "Connected successfully!"
    echo "  Username: $USERNAME"
    echo "  Instance: $INSTANCE"
else
    error "Cannot connect to org '$ORG_ALIAS'"
    echo ""
    echo "Please authenticate first:"
    echo "  sf org login web --alias $ORG_ALIAS"
    exit 1
fi

# -----------------------------------------------------------------------------
# Step 2: Retrieve All Metadata
# -----------------------------------------------------------------------------
step "Step 2/6: Retrieving All Metadata"

if [ "$SKIP_RETRIEVE" = true ]; then
    warning "Skipping metadata retrieval (--skip-retrieve flag set)"
    echo "Using existing content in force-app/"
else
    log "Running retrieve-all-metadata.sh..."

    if "$SCRIPT_DIR/retrieve-all-metadata.sh" "$ORG_ALIAS" 2>&1 | tee -a "$MASTER_LOG"; then
        success "Metadata retrieval complete"
    else
        warning "Metadata retrieval had some issues (check logs)"
        ((ERRORS++))
    fi
fi

# -----------------------------------------------------------------------------
# Step 3: Run Query-Based Inventory
# -----------------------------------------------------------------------------
step "Step 3/6: Running Query-Based Inventory"

log "Running query-metadata.sh for supplemental data..."

if "$SCRIPT_DIR/query-metadata.sh" "$ORG_ALIAS" 2>&1 | tee -a "$MASTER_LOG"; then
    success "Query inventory complete"
else
    warning "Query inventory had some issues"
    ((ERRORS++))
fi

# -----------------------------------------------------------------------------
# Step 4: Run Detailed Inventories (Parallel)
# -----------------------------------------------------------------------------
step "Step 4/6: Running Detailed Inventories"

log "Running detailed inventory scripts in parallel..."

# Run in background
"$SCRIPT_DIR/inventory-objects.sh" "$ORG_ALIAS" >> "$MASTER_LOG" 2>&1 &
PID_OBJ=$!

"$SCRIPT_DIR/inventory-automation.sh" "$ORG_ALIAS" >> "$MASTER_LOG" 2>&1 &
PID_AUTO=$!

"$SCRIPT_DIR/inventory-integrations.sh" "$ORG_ALIAS" >> "$MASTER_LOG" 2>&1 &
PID_INT=$!

"$SCRIPT_DIR/inventory-security.sh" "$ORG_ALIAS" >> "$MASTER_LOG" 2>&1 &
PID_SEC=$!

# Wait for all to complete
echo "  Waiting for inventory-objects.sh..."
wait $PID_OBJ 2>/dev/null || warning "inventory-objects.sh had issues"

echo "  Waiting for inventory-automation.sh..."
wait $PID_AUTO 2>/dev/null || warning "inventory-automation.sh had issues"

echo "  Waiting for inventory-integrations.sh..."
wait $PID_INT 2>/dev/null || warning "inventory-integrations.sh had issues"

echo "  Waiting for inventory-security.sh..."
wait $PID_SEC 2>/dev/null || warning "inventory-security.sh had issues"

success "Detailed inventories complete"

# -----------------------------------------------------------------------------
# Step 5: Analyze Retrieved Metadata
# -----------------------------------------------------------------------------
step "Step 5/6: Analyzing Retrieved Metadata"

log "Running analyze-metadata.sh..."

if "$SCRIPT_DIR/analyze-metadata.sh" 2>&1 | tee -a "$MASTER_LOG"; then
    success "Metadata analysis complete"
else
    warning "Metadata analysis had some issues"
    ((ERRORS++))
fi

# -----------------------------------------------------------------------------
# Step 6: Generate Documentation
# -----------------------------------------------------------------------------
step "Step 6/6: Generating Documentation"

log "Running generate-report.sh..."
"$SCRIPT_DIR/generate-report.sh" >> "$MASTER_LOG" 2>&1 || warning "Report generation had issues"

log "Running generate-claude-context.sh..."
"$SCRIPT_DIR/generate-claude-context.sh" >> "$MASTER_LOG" 2>&1 || warning "Context generation had issues"

success "Documentation generation complete"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    DISCOVERY COMPLETE                        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    success "All steps completed successfully!"
else
    warning "Completed with $ERRORS step(s) having issues. Check logs for details."
fi

echo ""
echo "Output Locations:"
echo "  ├── force-app/main/default/          <- Retrieved source files"
echo "  ├── docs/discovery/metadata-inventory/ <- Query results (JSON)"
echo "  ├── docs/discovery/analysis/          <- Analysis and reports"
echo "  │   ├── discovery-report.md           <- Human-readable summary"
echo "  │   ├── claude-context.md             <- Ready for CLAUDE.md"
echo "  │   ├── apex-analysis.json"
echo "  │   ├── trigger-analysis.json"
echo "  │   ├── object-analysis.json"
echo "  │   ├── flow-analysis.json"
echo "  │   └── component-summary.json"
echo "  └── logs/discovery/                   <- Execution logs"
echo ""
echo "Next Steps:"
echo "  1. Review: cat docs/discovery/analysis/discovery-report.md"
echo "  2. Review: cat docs/discovery/analysis/claude-context.md"
echo "  3. Update CLAUDE.md with relevant context"
echo "  4. Start exploring the codebase!"
echo ""
echo "Log file: $MASTER_LOG"
echo ""
