#!/bin/sh
# This script reads Falco event JSON from stdin and kills the offending process.

# Read entire Falco JSON event from stdin
read event

# Define rules that should trigger container killing
valid_rules_keywords="CVE"

# Extract rule name
rule_name=$(echo "$event" | jq -r '.rule // empty')

#echo "Rule name: $rule_name" >> /var/log/falco-actions.log
#echo "Valid Rule name: $valid_rules" >> /var/log/falco-actions.log
#echo "Rule name after match: ${valid_rules##*$rule_name*}" >> /var/log/falco-actions.log

#use priority
# valid_pri="WARNING"  # can add "Notice", but we only use warning now

priority=$(echo "$event" | jq -r '.priority // empty')

if [ "${valid_pri##*$priority*}" = "Error" ]; then
	exit 0
fi

echo "[$(date)] ⚠️  Priority: $priority - Rule: $rule_name" >> /var/log/falco-actions.log
#echo "Valid Priority: $valid_pri" >> /var/log/falco-actions.log
#echo "Rule name after match: ${valid_pri##*$priority*}" >> /var/log/falco-actions.log

if [ "${rule_name##*$valid_rules_keywords*}" != "$rule_name" ]; then
#if [ "${valid_pri##*$priority*}" != "$valid_pri" ]; then
	# extract process name for logging
	container_name=$(echo "$event" | jq -r '.output_fields["container.name"] // empty')

	# container id for killing
	container_id=$(echo "$event" | jq -r '.output_fields["container.id"] // empty')

	if [ -n "$container_id" ]; then
	    echo "[$(date)] 🔧 Found container: $container_name ($container_id)" >> /var/log/falco-actions.log
	    # Get container's main process PID
	    
		for pid in /proc/[0-9]*; do
		    if grep -q $container_id "$pid/cmdline" 2>/dev/null; then
			# echo ${pid##*/}
			main_pid=${pid##*/}
			break
		    fi
		done 
	    # echo "Dubug Log: PID: $main_pid" >> /var/log/falco-actions.log

	    if [ -n "$main_pid" ] && [ "$main_pid" -gt 0 ] 2>/dev/null; then
	       echo "[$(date)] 🔴 Killing container $container_id (main PID: $main_pid)" >> /var/log/falco-actions.log
	       
	       kill -9 "$main_pid"
	       
	       if [ $? -eq 0 ]; then
		    echo "[$(date)] ✅ Container killed successfully for rule [$rule_name]" >> /var/log/falco-actions.log
		else
		    echo "[$(date)] ❌ Failed to kill container" >> /var/log/falco-actions.log
		fi
	    else
	    	echo "[$(date)] ℹ️  Could not find the PID on host, probably already destroyed" >> /var/log/falco-actions.log
	    fi
	else
	    echo "[$(date)] ℹ️ Could not find container ID" >> /var/log/falco-actions.log         
	fi
else
	echo "[$(date)] ℹ️  Could not find matching rules in valid_rules_keywords" >> /var/log/falco-actions.log  
	#echo "[$(date)] ℹ️  It's not the Priority to kill" >> /var/log/falco-actions.log        
fi

echo "[$(date)] 📦 Falco-action exit" >> /var/log/falco-actions.log
echo "------------------------------------------------------------------------------------------" >> /var/log/falco-actions.log
