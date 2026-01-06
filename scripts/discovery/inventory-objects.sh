#!/bin/bash
# =============================================================================
# Custom Object and Field Detailed Inventory
# =============================================================================
#
# Usage: ./inventory-objects.sh <org-alias> [object-name]
#
# This script retrieves detailed object descriptions including all fields,
# relationships, record types, and validation rules.
#
# =============================================================================

set -e

ORG_ALIAS="${1:-}"
OBJECT_NAME="${2:-}"
OUTPUT_DIR="docs/discovery/metadata-inventory/objects"

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

# Fallback: Extract array elements from JSON
extract_json_array() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -oP "\"$key\"\s*:\s*\[[^\]]*\]" | grep -oP '"[^"]+__c"' | tr -d '"' | sort -u
}

# Fallback: Count array length in JSON file
count_json_array() {
    local file="$1"
    local key="$2"
    # Count occurrences of objects in the array - look for "name" fields in fields array
    grep -oP "\"$key\"\s*:" "$file" 2>/dev/null | wc -l || echo "?"
}

# Fallback: Extract string value from JSON
extract_json_string() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -oP "\"$key\"\s*:\s*\"[^\"]*\"" | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
}

# Fallback: Extract boolean value from JSON
extract_json_bool() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -oP "\"$key\"\s*:\s*(true|false)" | head -1 | grep -oP '(true|false)'
}

if [ -z "$ORG_ALIAS" ]; then
    echo -e "${RED}Error: Org alias is required${NC}"
    echo ""
    echo "Usage: $0 <org-alias> [specific-object-name]"
    echo ""
    echo "Examples:"
    echo "  $0 prod                     # Describe all custom objects"
    echo "  $0 prod Account             # Describe specific object"
    echo "  $0 prod Custom_Object__c    # Describe custom object"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "=========================================="
echo "Object Inventory"
echo "=========================================="
echo "Org Alias: $ORG_ALIAS"
echo "Output:    $OUTPUT_DIR"
echo "=========================================="
echo ""

if [ -n "$OBJECT_NAME" ]; then
    # Single object describe
    echo "Describing object: $OBJECT_NAME"
    echo -n "  Fetching schema... "
    if sf sobject describe --sobject "$OBJECT_NAME" --target-org "$ORG_ALIAS" --json > "$OUTPUT_DIR/${OBJECT_NAME}.json" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"

        # Extract summary info
        echo ""
        echo "Summary for $OBJECT_NAME:"
        echo "------------------------"
        if [ "$HAS_JQ" = true ]; then
            jq -r '.result | "  Label: \(.label)\n  API Name: \(.name)\n  Custom: \(.custom)\n  Field Count: \(.fields | length)\n  Record Types: \(.recordTypeInfos | length)"' "$OUTPUT_DIR/${OBJECT_NAME}.json" 2>/dev/null || echo "  (Unable to parse)"
        else
            # Fallback without jq
            JSON_CONTENT=$(cat "$OUTPUT_DIR/${OBJECT_NAME}.json")
            LABEL=$(extract_json_string "$JSON_CONTENT" "label")
            NAME=$(extract_json_string "$JSON_CONTENT" "name")
            CUSTOM=$(extract_json_bool "$JSON_CONTENT" "custom")
            FIELD_COUNT=$(grep -c '"name"\s*:' "$OUTPUT_DIR/${OBJECT_NAME}.json" 2>/dev/null || echo "?")
            echo "  Label: ${LABEL:-Unknown}"
            echo "  API Name: ${NAME:-Unknown}"
            echo "  Custom: ${CUSTOM:-Unknown}"
            echo "  Field Count: ~$FIELD_COUNT (approximate)"
        fi
    else
        echo -e "${RED}FAILED${NC}"
        echo "  Object may not exist or you may not have access"
    fi
else
    # Get all custom objects and describe each
    echo "Fetching list of custom objects..."

    OBJECTS_JSON=$(sf sobject list --sobject-type custom --target-org "$ORG_ALIAS" --json 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to retrieve object list${NC}"
        exit 1
    fi

    if [ "$HAS_JQ" = true ]; then
        OBJECTS=$(echo "$OBJECTS_JSON" | jq -r '.result[]' 2>/dev/null)
    else
        # Fallback: Extract object names from JSON array
        OBJECTS=$(echo "$OBJECTS_JSON" | grep -oP '"[^"]+__c"' | tr -d '"' | sort -u)
    fi
    TOTAL=$(echo "$OBJECTS" | grep -c . || echo "0")

    echo "Found $TOTAL custom objects"
    echo ""

    COUNT=0
    for OBJ in $OBJECTS; do
        COUNT=$((COUNT + 1))
        echo -n "[$COUNT/$TOTAL] $OBJ... "

        if sf sobject describe --sobject "$OBJ" --target-org "$ORG_ALIAS" --json > "$OUTPUT_DIR/${OBJ}.json" 2>/dev/null; then
            if [ "$HAS_JQ" = true ]; then
                FIELD_COUNT=$(jq '.result.fields | length' "$OUTPUT_DIR/${OBJ}.json" 2>/dev/null || echo "?")
            else
                # Fallback: Count "name" occurrences in fields array (approximate)
                FIELD_COUNT=$(grep -c '"name"\s*:' "$OUTPUT_DIR/${OBJ}.json" 2>/dev/null || echo "?")
            fi
            echo -e "${GREEN}OK${NC} ($FIELD_COUNT fields)"
        else
            echo -e "${YELLOW}SKIPPED${NC}"
        fi
    done

    echo ""
    echo "=========================================="
    echo -e "${GREEN}Object inventory complete${NC}"
    echo "=========================================="
    echo ""
    echo "Files saved to: $OUTPUT_DIR"
    echo ""
    echo "To generate a summary, you can run:"
    echo "  for f in $OUTPUT_DIR/*.json; do"
    echo '    echo "$(basename $f .json): $(jq -r ".result.fields | length" $f) fields"'
    echo "  done"
fi
