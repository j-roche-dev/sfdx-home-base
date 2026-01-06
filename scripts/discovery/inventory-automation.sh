#!/bin/bash
# =============================================================================
# Automation Inventory - Flows, Process Builders, Workflow Rules
# =============================================================================
#
# Usage: ./inventory-automation.sh <org-alias>
#
# This script retrieves detailed automation inventory categorized by type.
#
# =============================================================================

set -e

ORG_ALIAS="${1:-}"
OUTPUT_DIR="docs/discovery/metadata-inventory/automation"

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
echo "Automation Inventory"
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
        echo -e "${GREEN}OK${NC} ($COUNT records)"
    else
        echo -e "${YELLOW}SKIPPED${NC}"
    fi
}

# -----------------------------------------------------------------------------
# Flows by Type
# -----------------------------------------------------------------------------
echo "[1/7] Record-Triggered Flows"
run_query "Before-save flows" \
    "SELECT Id, MasterLabel, DeveloperName, ProcessType, TriggerType, TriggerObjectOrEventLabel, Description, ApiVersion, LastModifiedDate FROM FlowDefinitionView WHERE IsActive = true AND ProcessType = 'AutoLaunchedFlow' AND TriggerType = 'RecordBeforeSave' ORDER BY TriggerObjectOrEventLabel, MasterLabel" \
    "record-triggered-before.json"

run_query "After-save flows" \
    "SELECT Id, MasterLabel, DeveloperName, ProcessType, TriggerType, TriggerObjectOrEventLabel, Description, ApiVersion, LastModifiedDate FROM FlowDefinitionView WHERE IsActive = true AND ProcessType = 'AutoLaunchedFlow' AND TriggerType = 'RecordAfterSave' ORDER BY TriggerObjectOrEventLabel, MasterLabel" \
    "record-triggered-after.json"

echo ""
echo "[2/7] Screen Flows"
run_query "Screen flows" \
    "SELECT Id, MasterLabel, DeveloperName, ProcessType, Description, ApiVersion, LastModifiedDate FROM FlowDefinitionView WHERE IsActive = true AND ProcessType = 'Flow' ORDER BY MasterLabel" \
    "screen-flows.json"

echo ""
echo "[3/7] Scheduled Flows"
run_query "Scheduled flows" \
    "SELECT Id, MasterLabel, DeveloperName, ProcessType, TriggerType, Description, ApiVersion, LastModifiedDate FROM FlowDefinitionView WHERE IsActive = true AND TriggerType = 'Scheduled' ORDER BY MasterLabel" \
    "scheduled-flows.json"

echo ""
echo "[4/7] Platform Event Flows"
run_query "Platform event flows" \
    "SELECT Id, MasterLabel, DeveloperName, ProcessType, TriggerType, TriggerObjectOrEventLabel, Description, ApiVersion, LastModifiedDate FROM FlowDefinitionView WHERE IsActive = true AND TriggerType = 'PlatformEvent' ORDER BY MasterLabel" \
    "platform-event-flows.json"

echo ""
echo "[5/7] Process Builders (Legacy)"
run_query "Process Builders" \
    "SELECT Id, MasterLabel, DeveloperName, ProcessType, Description, ApiVersion, LastModifiedDate FROM FlowDefinitionView WHERE IsActive = true AND ProcessType = 'Workflow' ORDER BY MasterLabel" \
    "process-builders.json"

echo ""
echo "[6/7] Apex Triggers (by object)"
run_query "Apex triggers" \
    "SELECT Id, Name, TableEnumOrId, Status, UsageBeforeInsert, UsageAfterInsert, UsageBeforeUpdate, UsageAfterUpdate, UsageBeforeDelete, UsageAfterDelete, UsageAfterUndelete, NamespacePrefix FROM ApexTrigger WHERE Status = 'Active' ORDER BY TableEnumOrId, Name" \
    "apex-triggers-detail.json"

echo ""
echo "[7/7] Scheduled Apex Jobs"
run_query "Scheduled jobs" \
    "SELECT Id, CronJobDetail.Name, CronJobDetail.JobType, State, StartTime, NextFireTime, PreviousFireTime, EndTime FROM CronTrigger WHERE State IN ('WAITING', 'ACQUIRED', 'EXECUTING') ORDER BY NextFireTime" \
    "scheduled-jobs.json"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "=========================================="
echo -e "${GREEN}Automation inventory complete${NC}"
echo "=========================================="
echo ""
echo "Summary:"

# Print counts
for file in "$OUTPUT_DIR"/*.json; do
    if [ -f "$file" ]; then
        name=$(basename "$file" .json)
        count=$(jq '.result.records | length' "$file" 2>/dev/null || echo "0")
        echo "  $name: $count"
    fi
done

echo ""
echo "Output saved to: $OUTPUT_DIR"
echo ""
echo "Next: Review outputs and update docs/architecture/automation.md"
