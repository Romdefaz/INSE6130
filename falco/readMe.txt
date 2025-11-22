This is not a readme.md

This is a readme.txt for environment preparation.

-----------------------------
For falco(from scratch):

sudo apt install curl

sudo apt-get install -y falco=0.35.1

---
# Don't Copy! 
# read, then copy if needed
# if you already install some falco drivers, remove it first with below code in ()
(sudo rmmod falco 2>/dev/null || true
sudo dkms remove -m falco -v 9.0.0+driver --all 2>/dev/null || true)
---

curl -s https://falco.org/script/install | sudo bash -s -- --driver-type kmod --driver-version 4.0.0+driver

sudo falco-driver-loader --compile

----------------------------------------------
# if run into "Exec format error", use below

sudo systemctl daemon-reload

sudo systemctl start falco-kmod.service

------------------------
For docker: 

sudo apt update
sudo apt install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
---------------------

load kernel module
sudo modprobe falco 2>/dev/null || sudo insmod /home/u18/.falco/9.0.0+driver/x86_64/falco_ubuntu-generic_5.4.0-150-generic_167~18.04.1.ko


in the folder:
chmod +x $(pwd)/falco-action.sh

---------------------------------------------
Command for falco container:
sudo docker run --pid=host --rm -it   --name falco   --privileged  -v /sys/kernel/tracing:/sys/kernel/tracing:ro  -v /dev:/host/dev   -v /var/run/docker.sock:/host/var/run/docker.sock   -v /proc:/host/proc:ro   -v /etc:/host/etc:ro   -v /lib/modules:/host/lib/modules:ro   -v $(pwd)/falco.yaml:/etc/falco/falco.yaml:ro   -v $(pwd)/falco_custom_rules.yaml:/etc/falco/falco_rules.local.yaml:ro   -v $(pwd)/falco-action.sh:/usr/local/bin/falco-action.sh    falcosecurity/falco:0.35.1 
---------------------------------------------

Debug codes:
sudo docker exec falco cat /var/log/falco-actions.log
sudo docker run  -w /proc/self/fd/8 --name attack --rm -it debian:bookworm   (if in wrong runC, just delete the 8, falco will still detect it.)
sudo docker run -it alpine sh
