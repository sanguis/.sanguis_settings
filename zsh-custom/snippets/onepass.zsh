#!/bin/zsh

k8s_to_onepass() {

SRC_SECRET=$1
OP_SECRET=$2
VAULT=$3


kubectl get secret "$SRC_SECRET" -n "$SRC_NS" -o json | \
jq -r '.data | to_entries[] | "\(.key)=\(.value|@base64d)"' > /tmp/decoded.env


# Build the JSON payload for a “Secure Note” (or “Password” item if you prefer)
[[ -z OP_SECRET ]] &&ITEM_NAME="k8s-${SRC_SECRET}-copy" || ITEM_NAME="$OP_SECRET"

# Read the decoded env file and turn each line into a JSON field object
fields_json=$(while IFS='=' read -r key value; do
    # Escape double quotes for JSON safety
    esc_key=$(printf '%s' "$key"   | sed 's/"/\\"/g')
    esc_val=$(printf '%s' "$value" | sed 's/"/\\"/g')
    printf '{"label":"%s","value":"%s","type":"CONCEALED"},' "$esc_key" "$esc_val"
done < /tmp/decoded.env | paste -sd, -)
# Remove trailing comma
fields_json=${fields_json%,}


# Assemble the final payload JSON
payload=$(cat <<EOF
{
  "title": "$ITEM_NAME",
  "vault": { "id": "$VAULT" },
  "fields": [ $fields_json ]
}
EOF
)
if [[ $DEBUG == "true" ]]; then
  jpay=$(echo "$payload" | jq)
  [[ $? -ne 0 ]] && echo "Invalid JSON payload" && echo "$payload" && return 1
fi

# Create the item
echo $payload |op item create --category "API Credential"
}
