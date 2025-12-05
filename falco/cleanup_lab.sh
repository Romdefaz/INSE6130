#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root"
  exit
fi

echo "---🔧 STEP 1: Hunting for suspicious Root connections ---"

# 1. Get all PIDs from ESTABLISHED connections
# - exclude 'sshd' (So you don't kill yourself)
# - grep for 'pid=' to isolate the process ID part
# - cut and awk to extract just the number
TARGET_PIDS=$(ss -tunap | grep ESTAB | grep -v "sshd" | grep -o 'pid=[0-9]*' | cut -d= -f2)

if [ -z "$TARGET_PIDS" ]; then
    echo "[$(date)] ℹ️ No suspicious connections found." >> /var/log/falco-actions.log
    echo "[$(date)] 📦 Exiting." >> /var/log/falco-actions.log
    exit
else
    # Loop through found PIDs to verify they are ROOT
    for pid in $TARGET_PIDS; do
        # Check if the process still exists
        if ps -p $pid > /dev/null; then
            # Get the user who owns the process
            PROCESS_OWNER=$(ps -o user= -p $pid)
            
            if [ "$PROCESS_OWNER" == "root" ]; then
                echo "[$(date)] 🔴 [!!!] FOUND ROOT CONNECTION. PID: $pid. Killing now..." >> /var/log/falco-actions.log
                kill -9 $pid
            else
                echo "[$(date)] 📄 [Info] Ignoring PID $pid (Owned by $PROCESS_OWNER, not root)." >> /var/log/falco-actions.log
            fi
        fi
    done
fi

echo "---🔧 STEP 2: Killing all running containers ---"
# Check if there are running containers
if [ -n "$(docker ps -q)" ]; then
    docker kill $(docker ps -q)
    echo "[$(date)] 🔴 Tried to kill all containers." >> /var/log/falco-actions.log
fi

echo "Give containers some time to die alone, sleeping 1.5s"
sleep 1.5

CONTAINER_IDS=$(docker ps -q)

if [ -z "$CONTAINER_IDS" ]; then
    echo "[$(date)] ✅ No running containers found." >> /var/log/falco-actions.log
fi

for id in $CONTAINER_IDS; do
    # Get the Container Name for logging
    NAME=$(docker inspect --format="{{.Name}}" $id | sed 's/\///')
    
    # EXTRACT THE HOST PID
    TARGET_PID=$(docker inspect --format="{{.State.Pid}}" $id)

    # Validate we got a real PID (not 0 or empty)
    if [ -n "$TARGET_PID" ] && [ "$TARGET_PID" -ne 0 ]; then
        echo "[$(date)] 🔴 [Kill] Container: $NAME ($id) -> Host PID: $TARGET_PID" >> /var/log/falco-actions.log
        
        # EXECUTE KILL
        kill -9 $TARGET_PID
    else
        echo "[$(date)] [Skip] Container $NAME ($id) seems to have no PID (Zombie/Already Dead)." >> /var/log/falco-actions.log
    fi
done

echo "---🔧 STEP 3: Running Reinstall Script ---"
if [ -f "./docker_reinstall.sh" ]; then
    echo "[$(date)] 🚀 Here goes JONNY! I mean reinstall of docker and docker binary." >> /var/log/falco-actions.log
    chmod +x ./docker_reinstall.sh
    ./docker_reinstall.sh
else
    echo "[$(date)] ⚠️ Error: 'docker_reinstall.sh' not found in current directory." >> /var/log/falco-actions.log
fi
