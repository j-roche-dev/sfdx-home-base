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
        jq -r '.result | "  Label: \(.label)\n  API Name: \(.name)\n  Custom: \(.custom)\n  Field Count: \(.fields | length)\n  Record Types: \(.recordTypeInfos | length)"' "$OUTPUT_DIR/${OBJECT_NAME}.json" 2>/dev/null || echo "  (Unable to parse)"
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

    OBJECTS=$(echo "$OBJECTS_JSON" | jq -r '.result[]' 2>/dev/null)
    TOTAL=$(echo "$OBJECTS" | wc -l)

    echo "Found $TOTAL custom objects"
    echo ""

    COUNT=0
    for OBJ in $OBJECTS; do
        COUNT=$((COUNT + 1))
        echo -n "[$COUNT/$TOTAL] $OBJ... "

        if sf sobject describe --sobject "$OBJ" --target-org "$ORG_ALIAS" --json > "$OUTPUT_DIR/${OBJ}.json" 2>/dev/null; then
            FIELD_COUNT=$(jq '.result.fields | length' "$OUTPUT_DIR/${OBJ}.json" 2>/dev/null || echo "?")
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
