#!/bin/bash
# This script reads Falco event JSON from stdin and kills the offending process.

# Read entire Falco JSON event from stdin
read event
# get container id for pausing
container_id=$(echo "$event" | jq -r '.output_fields["container.id"] // empty')


# Define rules that should trigger container killing
valid_rules_keywords="CVE"

# Extract rule name
rule_name=$(echo "$event" | jq -r '.rule // empty')

STATE_FILE="/tmp/falco_last_event.state"
# Create a unique signature for this event (ID + Rule)
current_signature="${container_id}:${rule_name}"

# Read the last stored signature if the file exists
if [ -f "$STATE_FILE" ]; then
    last_signature=$(cat "$STATE_FILE")
    
    # Compare current event with the last one
    if [ "$current_signature" == "$last_signature" ]; then
        # If they match, we have already handled this. EXIT IMMEDIATELY.
        # We generally don't log this to avoid filling disk space with "Skipping..." logs.
        exit 0
    fi
fi

# If we are here, it is a NEW event. 
# Overwrite the state file with the current signature.
echo "$current_signature" > "$STATE_FILE"
#echo "Rule name: $rule_name" >> /var/log/falco-actions.log
#echo "Valid Rule name: $valid_rules" >> /var/log/falco-actions.log
#echo "Rule name after match: ${valid_rules##*$rule_name*}" >> /var/log/falco-actions.log

#use priority
# valid_pri="WARNING"  # can add "Notice", but we only use warning now

priority=$(echo "$event" | jq -r '.priority // empty')

if [ "$priority" = "Error" ]; then
	exit 0
fi

echo "[$(date)] ⚠️  Priority: $priority - Rule: $rule_name" >> /var/log/falco-actions.log
#echo "Valid Priority: $valid_pri" >> /var/log/falco-actions.log
#echo "Rule name after match: ${valid_pri##*$priority*}" >> /var/log/falco-actions.log

if [ "${rule_name##*$valid_rules_keywords*}" != "$rule_name" ]; then
#if [ "${valid_pri##*$priority*}" != "$valid_pri" ]; then
	if [ -n "$container_id" ]; then
		IS_RUNNING=$(docker inspect --format '{{.State.Running}}' "$container_id" 2>/dev/null)
		if [ "$IS_RUNNING" == "True" ]; then
			docker pause "$container_id"
			echo "[$(date)] ✅ Tried to paused Container" >> /var/log/falco-actions.log
		fi
		# extract process name for logging
		container_name=$(echo "$event" | jq -r '.output_fields["container.name"] // empty')
		echo "[$(date)] 🔧 Found container: $container_name ($container_id)" >> /var/log/falco-actions.log
		

		if [ -f "./cleanup_lab.sh" ]; then
    			echo "🚀 -----------BOOOOOOOOM-------------------."
			chmod +x ./cleanup_lab.sh
    			./cleanup_lab.sh
		else
    			echo "⚠️ Error: 'cleanup_lab.sh' not found in current directory." >> /var/log/falco-actions.log
		fi
		IS_RUNNING=$(docker inspect --format '{{.State.Running}}' "$container_id" 2>/dev/null)
		if [ "$IS_RUNNING" == "true" ]; then
			docker kill "$container_id"
			echo "[$(date)] 🔴  Killing container $container_id" >> /var/log/falco-actions.log
		fi
		

	else
	    echo "[$(date)] ℹ️ Could not find container ID" >> /var/log/falco-actions.log         
	fi
else
	echo "[$(date)] ℹ️  Could not find matching rules in valid_rules_keywords" >> /var/log/falco-actions.log
	IS_RUNNING=$(docker inspect --format '{{.State.Running}}' "$container_id" 2>/dev/null)
	if [ "$IS_RUNNING" == "false" ]; then
		echo "[$(date)] 📦 Falco-action exit because container not running" >> /var/log/falco-actions.log
		exit
	fi	
	docker unpause "$container_id"
	echo "[$(date)] ℹ️  Try to unpause $container_id, in case stuck." >> /var/log/falco-actions.log
	#echo "[$(date)] ℹ️  It's not the Priority to kill" >> /var/log/falco-actions.log        
fi


echo "[$(date)] 📦 Falco-action exit" >> /var/log/falco-actions.log
echo "------------------------------------------------------------------------------------------" >> /var/log/falco-actions.log
