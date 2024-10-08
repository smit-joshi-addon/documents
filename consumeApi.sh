#!/bin/bash

# Constants
API_URL="http://localhost:8080/api/pull"
AUTH_TOKEN="eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJwcmVtaWVyX2xhdyIsImlhdCI6MTcyNzE3MzIyMSwiZXhwIjoyMDQyNTMzMjIxfQ.qQdD2snmvV7Jmdn7QOAv97sRYwVnA4uNftR1H54c9F0ck8H2p05rkimlhkCG01bBkpC9L13sRECmhWOHPLBtjA"
HEADER_AUTH="Authorization: Bearer $AUTH_TOKEN"

# List of endpoints
ENDPOINTS=("default" "default2" "default3" "default4")

fetch_data() {
    # Randomly select an endpoint
    local random_index=$((RANDOM % ${#ENDPOINTS[@]}))
    local selected_endpoint=${ENDPOINTS[$random_index]}

    # Fetch data from the selected endpoint
    response=$(curl -s -w "%{http_code}" -o response.json -H "$HEADER_AUTH" "$API_URL/$selected_endpoint")
    http_code=$(echo "$response" | tail -n1)

    # Check if request was successful
    if [ "$http_code" -ne 200 ]; then
        echo "Request to $selected_endpoint failed with HTTP code $http_code."
        return 1
    fi

    # Process the data (print it in this example)
    # cat response.json
    
    # Print success message
    echo "$selected_endpoint API Called Successfully"

    return 0
}

main() {
    while true; do
        if ! fetch_data; then
            break
        fi
        # Optional: sleep 5  # Delay of 5 seconds between requests
    done
}

main

