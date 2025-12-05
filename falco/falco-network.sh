#!/bin/bash

# Read Falco output from STDIN (JSON format)
while read -r log_line; do
    # 1. Extract Container ID and Name using jq
    CONTAINER_ID=$(echo "$log_line" | jq -r '.output_fields["container.id"] // empty')
    CONTAINER_NAME=$(echo "$log_line" | jq -r '.output_fields["container.name"] // empty')
    
    # Check if we actually got a container ID (ignore host events)
    if [[ -n "$CONTAINER_ID" && "$CONTAINER_ID" != "host" ]]; then
        
        echo "[!] Threat detected in $CONTAINER_NAME ($CONTAINER_ID). Initiating response..." >> /var/log/falco_response.log

        # 2. FIND NETWORKS
        # Get list of networks this container is attached to
        NETWORKS=$(docker inspect $CONTAINER_ID --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}')

        # 3. ISOLATE (Disconnect from all networks)
        for net in $NETWORKS; do
            echo "    -> Isolating: Disconnecting from network '$net'..." >> /var/log/falco_response.log
            docker network disconnect -f $net $CONTAINER_ID
        done

        # Optional: Sleep to allow for forensic capture or logging while isolated
        # sleep 10 

        # 4. KILL (Stop and Remove Container)
        echo "    -> Killing container $CONTAINER_ID..." >> /var/log/falco_response.log
        docker rm -f $CONTAINER_ID

        # 5. KILL NETWORK (Attempt to remove the networks)
        # Note: This only works if the network is now empty.
        for net in $NETWORKS; do
            echo "    -> Attempting to remove network '$net'..." >> /var/log/falco_response.log
            docker network rm $net || echo "       (Network $net not removed; likely still in use)" >> /var/log/falco_response.log
        done
    fi
done
