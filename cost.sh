#!/bin/bash

SUBSCRIPTION_ID="a4a9ae3c-3366-48b8-9030-d035a7ea4119"

FROM=$(date -u -d "1 day ago" +"%Y-%m-%dT00:00:00Z")
TO=$(date -u +"%Y-%m-%dT00:00:00Z")

RESULT=$(az rest \
  --method post \
  --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.CostManagement/query?api-version=2023-03-01" \
  --body "{
    \"type\": \"ActualCost\",
    \"timeframe\": \"Custom\",
    \"timePeriod\": {
      \"from\": \"$FROM\",
      \"to\": \"$TO\"
    },
    \"dataset\": {
      \"granularity\": \"None\",
      \"aggregation\": {
        \"totalCost\": {
          \"name\": \"Cost\",
          \"function\": \"Sum\"
        }
      },
      \"grouping\": [
        {
          \"type\": \"Dimension\",
          \"name\": \"ResourceId\"
        }
      ]
    }
  }")

# Exit if Azure returned an error
if echo "$RESULT" | jq -e '.error' >/dev/null; then
    echo "Azure API Error:"
    echo "$RESULT" | jq .
    exit 1
fi

VM_COST=$(echo "$RESULT" | jq -r '
.properties.rows[]
| select(.[1] | test("/virtualMachines/VM1$"; "i"))
| .[0] // 0
')

DISK_COST=$(echo "$RESULT" | jq -r '
.properties.rows[]
| select(.[1] | test("vm1_osdisk"; "i"))
| .[0] // 0
')

PIP_COST=$(echo "$RESULT" | jq -r '
.properties.rows[]
| select(.[1] | test("vm1-ip"; "i"))
| .[0] // 0
')

TOTAL_COST=$(awk "BEGIN {printf \"%.2f\", $VM_COST + $DISK_COST + $PIP_COST}")

echo "VM Cost      : ₹$VM_COST"
echo "Disk Cost    : ₹$DISK_COST"
echo "Public IP    : ₹$PIP_COST"
echo "---------------------------"
echo "Total Cost   : ₹$TOTAL_COST"
