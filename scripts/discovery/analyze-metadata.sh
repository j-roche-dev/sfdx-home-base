#!/bin/bash
# =============================================================================
# Metadata Analysis Script
# =============================================================================
#
# Analyzes retrieved source files in force-app/ and generates analysis JSON.
# Run this AFTER retrieve-all-metadata.sh has populated force-app/.
#
# Usage: ./analyze-metadata.sh [source-dir]
#
# =============================================================================

set -euo pipefail

# Configuration
SOURCE_DIR="${1:-force-app/main/default}"
OUTPUT_DIR="docs/discovery/analysis"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1"
}

success() {
    echo -e "${GREEN}$1${NC}"
}

warning() {
    echo -e "${YELLOW}$1${NC}"
}

# =============================================================================
# Analysis Functions
# =============================================================================

# Analyze Apex classes
analyze_apex_classes() {
    local classes_dir="$SOURCE_DIR/classes"
    local output_file="$OUTPUT_DIR/apex-analysis.json"

    log "Analyzing Apex classes..."

    if [ ! -d "$classes_dir" ] || [ -z "$(ls -A "$classes_dir" 2>/dev/null)" ]; then
        warning "  No Apex classes found"
        echo '{"classes": [], "summary": {"total": 0}}' > "$output_file"
        return
    fi

    # Start JSON
    echo '{"classes": [' > "$output_file"

    local first=true
    local total=0
    local test_count=0
    local controller_count=0
    local service_count=0
    local batch_count=0
    local integration_count=0

    for cls in "$classes_dir"/*.cls; do
        [ -f "$cls" ] || continue

        local name=$(basename "$cls" .cls)
        local lines=$(wc -l < "$cls" 2>/dev/null || echo "0")

        # Detect patterns
        local is_test=false
        local has_http=false
        local has_future=false
        local is_queueable=false
        local is_batch=false
        local is_schedulable=false

        if grep -qiE "@isTest|testMethod" "$cls" 2>/dev/null; then
            is_test=true
            test_count=$((test_count + 1))
        fi
        if grep -q "HttpRequest\|HttpResponse\|Http\." "$cls" 2>/dev/null; then
            has_http=true
            integration_count=$((integration_count + 1))
        fi
        if grep -q "@future" "$cls" 2>/dev/null; then
            has_future=true
        fi
        if grep -q "implements Queueable" "$cls" 2>/dev/null; then
            is_queueable=true
        fi
        if grep -q "implements Database.Batchable" "$cls" 2>/dev/null; then
            is_batch=true
            batch_count=$((batch_count + 1))
        fi
        if grep -q "implements Schedulable" "$cls" 2>/dev/null; then
            is_schedulable=true
        fi

        # Categorize
        local category="Utility"
        if [ "$is_test" = true ]; then
            category="Test"
        elif echo "$name" | grep -qiE "Controller$|Ctrl$"; then
            category="Controller"
            controller_count=$((controller_count + 1))
        elif echo "$name" | grep -qiE "Service$|Svc$"; then
            category="Service"
            service_count=$((service_count + 1))
        elif echo "$name" | grep -qiE "TriggerHandler|Handler$"; then
            category="TriggerHandler"
        elif echo "$name" | grep -qiE "Selector$|DAO$"; then
            category="DataAccess"
        elif [ "$is_batch" = true ]; then
            category="Batch"
        elif [ "$is_queueable" = true ]; then
            category="Queueable"
        elif [ "$has_http" = true ]; then
            category="Integration"
        fi

        [ "$first" = true ] && first=false || echo "," >> "$output_file"

        cat >> "$output_file" << EOF
  {
    "name": "$name",
    "lines": $lines,
    "category": "$category",
    "isTest": $is_test,
    "hasHttpCallout": $has_http,
    "hasFuture": $has_future,
    "isQueueable": $is_queueable,
    "isBatch": $is_batch,
    "isSchedulable": $is_schedulable
  }
EOF
        total=$((total + 1))
    done

    # Close JSON with summary
    cat >> "$output_file" << EOF
],
"summary": {
  "total": $total,
  "tests": $test_count,
  "controllers": $controller_count,
  "services": $service_count,
  "batches": $batch_count,
  "integrations": $integration_count
}
}
EOF

    success "  Found $total classes (Tests: $test_count, Controllers: $controller_count)"
}

# Analyze Apex triggers
analyze_triggers() {
    local triggers_dir="$SOURCE_DIR/triggers"
    local output_file="$OUTPUT_DIR/trigger-analysis.json"

    log "Analyzing Apex triggers..."

    if [ ! -d "$triggers_dir" ] || [ -z "$(ls -A "$triggers_dir" 2>/dev/null)" ]; then
        warning "  No Apex triggers found"
        echo '{"triggers": [], "summary": {"total": 0}}' > "$output_file"
        return
    fi

    echo '{"triggers": [' > "$output_file"

    local first=true
    local total=0

    for trg in "$triggers_dir"/*.trigger; do
        [ -f "$trg" ] || continue

        local name=$(basename "$trg" .trigger)

        # Parse trigger header to extract object and events
        local header=$(head -10 "$trg" | tr '\n' ' ')

        # Extract object name (trigger X on OBJECT)
        local sobject=$(echo "$header" | sed -n 's/.*trigger[[:space:]]*[A-Za-z_]*[[:space:]]*on[[:space:]]*\([A-Za-z_]*\).*/\1/p' | head -1)

        # Check events (use grep -c and ensure single integer result)
        local before_insert=$(grep -ci "before insert" "$trg" 2>/dev/null | head -1 || echo "0")
        local after_insert=$(grep -ci "after insert" "$trg" 2>/dev/null | head -1 || echo "0")
        local before_update=$(grep -ci "before update" "$trg" 2>/dev/null | head -1 || echo "0")
        local after_update=$(grep -ci "after update" "$trg" 2>/dev/null | head -1 || echo "0")
        local before_delete=$(grep -ci "before delete" "$trg" 2>/dev/null | head -1 || echo "0")
        local after_delete=$(grep -ci "after delete" "$trg" 2>/dev/null | head -1 || echo "0")
        local after_undelete=$(grep -ci "after undelete" "$trg" 2>/dev/null | head -1 || echo "0")
        # Set to 0 if empty
        [ -z "$before_insert" ] && before_insert=0
        [ -z "$after_insert" ] && after_insert=0
        [ -z "$before_update" ] && before_update=0
        [ -z "$after_update" ] && after_update=0
        [ -z "$before_delete" ] && before_delete=0
        [ -z "$after_delete" ] && after_delete=0
        [ -z "$after_undelete" ] && after_undelete=0

        # Detect handler pattern
        local handler_class=$(grep -oE '[A-Za-z_]+Handler\.[A-Za-z_]+|TriggerHandler\.[A-Za-z_]+' "$trg" 2>/dev/null | head -1 || echo "")

        [ "$first" = true ] && first=false || echo "," >> "$output_file"

        cat >> "$output_file" << EOF
  {
    "name": "$name",
    "object": "${sobject:-Unknown}",
    "handlerClass": "${handler_class:-null}",
    "events": {
      "beforeInsert": $([ "$before_insert" -gt 0 ] && echo "true" || echo "false"),
      "afterInsert": $([ "$after_insert" -gt 0 ] && echo "true" || echo "false"),
      "beforeUpdate": $([ "$before_update" -gt 0 ] && echo "true" || echo "false"),
      "afterUpdate": $([ "$after_update" -gt 0 ] && echo "true" || echo "false"),
      "beforeDelete": $([ "$before_delete" -gt 0 ] && echo "true" || echo "false"),
      "afterDelete": $([ "$after_delete" -gt 0 ] && echo "true" || echo "false"),
      "afterUndelete": $([ "$after_undelete" -gt 0 ] && echo "true" || echo "false")
    }
  }
EOF
        total=$((total + 1))
    done

    echo '],' >> "$output_file"
    echo '"summary": {"total": '$total'}}' >> "$output_file"

    success "  Found $total triggers"
}

# Analyze custom objects
analyze_objects() {
    local objects_dir="$SOURCE_DIR/objects"
    local output_file="$OUTPUT_DIR/object-analysis.json"

    log "Analyzing custom objects..."

    if [ ! -d "$objects_dir" ] || [ -z "$(ls -A "$objects_dir" 2>/dev/null)" ]; then
        warning "  No objects found"
        echo '{"objects": [], "summary": {"total": 0}}' > "$output_file"
        return
    fi

    echo '{"objects": [' > "$output_file"

    local first=true
    local total=0
    local custom_count=0

    for obj_dir in "$objects_dir"/*; do
        [ -d "$obj_dir" ] || continue

        local obj_name=$(basename "$obj_dir")

        # Count fields
        local field_count=0
        if [ -d "$obj_dir/fields" ]; then
            field_count=$(ls "$obj_dir/fields/"*.field-meta.xml 2>/dev/null | wc -l || echo "0")
        fi

        # Count validation rules
        local vr_count=0
        if [ -d "$obj_dir/validationRules" ]; then
            vr_count=$(ls "$obj_dir/validationRules/"*.validationRule-meta.xml 2>/dev/null | wc -l || echo "0")
        fi

        # Count record types
        local rt_count=0
        if [ -d "$obj_dir/recordTypes" ]; then
            rt_count=$(ls "$obj_dir/recordTypes/"*.recordType-meta.xml 2>/dev/null | wc -l || echo "0")
        fi

        # Check if custom object
        local is_custom=false
        if [[ "$obj_name" == *"__c" ]]; then
            is_custom=true
            custom_count=$((custom_count + 1))
        fi

        [ "$first" = true ] && first=false || echo "," >> "$output_file"

        cat >> "$output_file" << EOF
  {
    "name": "$obj_name",
    "isCustom": $is_custom,
    "fieldCount": $field_count,
    "validationRuleCount": $vr_count,
    "recordTypeCount": $rt_count
  }
EOF
        total=$((total + 1))
    done

    echo '],' >> "$output_file"
    echo '"summary": {"total": '$total', "custom": '$custom_count'}}' >> "$output_file"

    success "  Found $total objects ($custom_count custom)"
}

# Analyze flows
analyze_flows() {
    local flows_dir="$SOURCE_DIR/flows"
    local output_file="$OUTPUT_DIR/flow-analysis.json"

    log "Analyzing flows..."

    if [ ! -d "$flows_dir" ] || [ -z "$(ls -A "$flows_dir" 2>/dev/null)" ]; then
        warning "  No flows found"
        echo '{"flows": [], "summary": {"total": 0}}' > "$output_file"
        return
    fi

    echo '{"flows": [' > "$output_file"

    local first=true
    local total=0
    local record_triggered=0
    local screen_flows=0
    local scheduled=0

    for flow in "$flows_dir"/*.flow-meta.xml; do
        [ -f "$flow" ] || continue

        local name=$(basename "$flow" .flow-meta.xml)

        # Parse flow XML
        local process_type=$(grep -oP '<processType>\K[^<]+' "$flow" 2>/dev/null | head -1 || echo "Unknown")
        local trigger_type=$(grep -oP '<triggerType>\K[^<]+' "$flow" 2>/dev/null | head -1 || echo "")
        local status=$(grep -oP '<status>\K[^<]+' "$flow" 2>/dev/null | head -1 || echo "Unknown")
        local trigger_object=$(grep -oP '<object>\K[^<]+' "$flow" 2>/dev/null | head -1 || echo "")

        # Categorize
        if [ -n "$trigger_type" ] && [ "$trigger_type" != "null" ]; then
            if [[ "$trigger_type" == *"Record"* ]]; then
                record_triggered=$((record_triggered + 1))
            elif [[ "$trigger_type" == "Scheduled" ]]; then
                scheduled=$((scheduled + 1))
            fi
        elif [[ "$process_type" == "Flow" ]]; then
            screen_flows=$((screen_flows + 1))
        fi

        [ "$first" = true ] && first=false || echo "," >> "$output_file"

        cat >> "$output_file" << EOF
  {
    "name": "$name",
    "processType": "$process_type",
    "triggerType": "${trigger_type:-Manual}",
    "triggerObject": "${trigger_object:-N/A}",
    "status": "$status"
  }
EOF
        total=$((total + 1))
    done

    echo '],' >> "$output_file"
    cat >> "$output_file" << EOF
"summary": {
  "total": $total,
  "recordTriggered": $record_triggered,
  "screenFlows": $screen_flows,
  "scheduled": $scheduled
}
}
EOF

    success "  Found $total flows (Record-triggered: $record_triggered, Screen: $screen_flows)"
}

# Generate component summary
generate_summary() {
    local output_file="$OUTPUT_DIR/component-summary.json"

    log "Generating component summary..."

    local apex_count=$(find "$SOURCE_DIR/classes" -name "*.cls" 2>/dev/null | wc -l || echo "0")
    local trigger_count=$(find "$SOURCE_DIR/triggers" -name "*.trigger" 2>/dev/null | wc -l || echo "0")
    local lwc_count=$(find "$SOURCE_DIR/lwc" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l || echo "0")
    local aura_count=$(find "$SOURCE_DIR/aura" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l || echo "0")
    local flow_count=$(find "$SOURCE_DIR/flows" -name "*.flow-meta.xml" 2>/dev/null | wc -l || echo "0")
    local object_count=$(find "$SOURCE_DIR/objects" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l || echo "0")
    local custom_object_count=$(find "$SOURCE_DIR/objects" -mindepth 1 -maxdepth 1 -type d -name "*__c" 2>/dev/null | wc -l || echo "0")
    local permset_count=$(find "$SOURCE_DIR/permissionsets" -name "*.permissionset-meta.xml" 2>/dev/null | wc -l || echo "0")
    local profile_count=$(find "$SOURCE_DIR/profiles" -name "*.profile-meta.xml" 2>/dev/null | wc -l || echo "0")
    local layout_count=$(find "$SOURCE_DIR/layouts" -name "*.layout-meta.xml" 2>/dev/null | wc -l || echo "0")
    local flexipage_count=$(find "$SOURCE_DIR/flexipages" -name "*.flexipage-meta.xml" 2>/dev/null | wc -l || echo "0")
    local static_resource_count=$(find "$SOURCE_DIR/staticresources" -name "*.resource-meta.xml" 2>/dev/null | wc -l || echo "0")

    cat > "$output_file" << EOF
{
  "generatedAt": "$(date -Iseconds)",
  "sourceDirectory": "$SOURCE_DIR",
  "counts": {
    "apexClasses": $apex_count,
    "apexTriggers": $trigger_count,
    "lwcComponents": $lwc_count,
    "auraComponents": $aura_count,
    "flows": $flow_count,
    "objects": $object_count,
    "customObjects": $custom_object_count,
    "permissionSets": $permset_count,
    "profiles": $profile_count,
    "layouts": $layout_count,
    "flexipages": $flexipage_count,
    "staticResources": $static_resource_count
  }
}
EOF

    success "  Summary generated"
}

# =============================================================================
# Main Execution
# =============================================================================

echo "=========================================="
echo "Metadata Analysis"
echo "=========================================="
echo "Source: $SOURCE_DIR"
echo "Output: $OUTPUT_DIR"
echo "=========================================="
echo ""

# Check if source directory has content
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}ERROR: Source directory not found: $SOURCE_DIR${NC}"
    echo "Run retrieve-all-metadata.sh first to retrieve source files."
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run analysis
analyze_apex_classes
analyze_triggers
analyze_objects
analyze_flows
generate_summary

echo ""
echo "=========================================="
success "Analysis complete!"
echo "=========================================="
echo ""
echo "Output files:"
ls -la "$OUTPUT_DIR"/*.json 2>/dev/null | awk '{print "  " $NF}'
echo ""
echo "Next steps:"
echo "  1. Run ./scripts/discovery/generate-claude-context.sh"
echo "  2. Review analysis files in $OUTPUT_DIR"
echo ""
