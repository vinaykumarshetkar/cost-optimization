#!/bin/bash

SUBSCRIPTION_ID="a4a9ae3c-3366-48b8-9030-d035a7ea4119"

VM_NAME="testVM1"
RESOURCE_GROUP="vinay"

# Get VM Resource ID
VM_ID=$(az vm show \
  -g "$RESOURCE_GROUP" \
  -n "$VM_NAME" \
  --query id \
  -o tsv)

# Get OS Disk Resource ID
DISK_ID=$(az vm show \
  -g "$RESOURCE_GROUP" \
  -n "$VM_NAME" \
  --query "storageProfile.osDisk.managedDisk.id" \
  -o tsv)

# Get NIC Resource ID
NIC_ID=$(az vm show \
  -g "$RESOURCE_GROUP" \
  -n "$VM_NAME" \
  --query "networkProfile.networkInterfaces[0].id" \
  -o tsv)

# Get Public IP Resource ID (if one exists)
PIP_ID=$(az network nic show \
  --ids "$NIC_ID" \
  --query "ipConfigurations[0].publicIPAddress.id" \
  -o tsv)


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
VM_COST=$(echo "$RESULT" | jq -r --arg id "${VM_ID,,}" '
.properties.rows[]
| select((.[1] | ascii_downcase) == $id)
| .[0] // 0
')

DISK_COST=$(echo "$RESULT" | jq -r --arg id "${DISK_ID,,}" '
.properties.rows[]
| select((.[1] | ascii_downcase) == $id)
| .[0] // 0
')

PIP_COST=$(echo "$RESULT" | jq -r --arg id "${PIP_ID,,}" '
.properties.rows[]
| select((.[1] | ascii_downcase) == $id)
| .[0] // 0
')

TOTAL_COST=$(echo "$VM_COST $DISK_COST $PIP_COST" | awk '{printf "%.2f", $1+$2+$3}')
echo "From         : $FROM"
echo "To           : $TO"
echo "VM Cost      : ₹$VM_COST"
echo "Disk Cost    : ₹$DISK_COST"
echo "Public IP    : ₹$PIP_COST"
echo "---------------------------"
echo "Total Cost   : ₹$TOTAL_COST"
