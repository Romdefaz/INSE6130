
# INSE 6130

This branch is for the falco container set up on ubuntu 18.04

Becuase the version of ubuntu 18.04 and kernel version, we are using kernel modedule instead of eBPF Probe and mordern eBPF.


---

## Falco setup

For ubuntu 18.04, we will use falco 0.35.1. Here is the command to set up it's driver whose version is 4.0.0.

```
curl -s https://falco.org/script/install | sudo bash -s -- --driver-type kmod --driver-version 4.0.0+driver
```
Then compile
```
sudo falco-driver-loader --compile
```
Then load the driver:
```
sudo modprobe falco 2>/dev/null || sudo insmod /home/u18/.falco/9.0.0+driver/x86_64/falco_ubuntu-generic_5.4.0-150-generic_167~18.04.1.ko
```
For my custom program to work, we need to give the right to excute it, using chmod in the folder contains "falco-action.sh":
```
chmod +x $(pwd)/falco-action.sh
```
---
## Runnig Falco

Then here is the command to run the container for the falco:
```
sudo docker run --pid=host --rm -it   --name falco   --privileged -v /sys/kernel/tracing:/sys/kernel/tracing:ro  -v /dev:/host/dev -v /var/run/docker.sock:/host/var/run/docker.sock -v /proc:/host/proc:ro -v /etc:/host/etc:ro   -v /lib/modules:/host/lib/modules:ro -v $(pwd)/falco.yaml:/etc/falco/falco.yaml:ro -v $(pwd)/falco_custom_rules.yaml:/etc/falco/falco_rules.local.yaml:ro -v $(pwd)/falco-action.sh:/usr/local/bin/falco-action.sh falcosecurity/falco:0.35.1 
```
Here is a screenshot of command in terminal:
![screenshot 1](Screenshot 2025-11-22 113610/1FalcoContainerCommand.png)
Run it, then we will see falco starts to monitor:
![screenshot 2](Screenshot 2025-11-22 113610/2FalcoMonitoring.png)
Then we open another terminal to run a CVE container:
(if in wrong runC, just delete the 8, falco will still detect it.)
```
sudo docker run  -w /proc/self/fd/8 --name attack --rm -it debian:bookworm
```
![screenshot 3](Screenshot 2025-11-22 113610/3RunAContainerCVE2024_21626.png)
Then we can see that the falco detects the action:
![screenshot 4](Screenshot 2025-11-22 113610/4FalcoCatchAction_output.png)
Then we can see that the CVE container gets killed right after falco detection.
![screenshot 5](Screenshot 2025-11-22 113610/5CVEcontainerKilled.png)
Here is a command to see the custom program's log:
```
sudo docker exec falco cat /var/log/falco-actions.log
```
![screenshot 6](Screenshot 2025-11-22 113610/6CommandToCheckMyCodeLog.png)
In the screenshot below we cn see the colorful logs I set up (way better than reading json logs)
![screenshot 7](Screenshot 2025-11-22 113610/7MyColorfulLog.png)
Now with the command to run a variable control container with alpine:
```
sudo docker run -it alpine sh
```
![screenshot 8](Screenshot 2025-11-22 113610/8RunANormalContainer.png)
We can see that the falco catch the action of this container spawning a shell:
![screenshot 9](Screenshot 2025-11-22 113610/9FalcoDetectItAsShellInContainer.png)
But as the screenshot shows, the normal container can work normally without restriction:
![screenshot 10](Screenshot 2025-11-22 113610/a_TheNormalContainerWorkNoramlly.png)
Exit the normal container, again, try to run the run the CVE container, it gets killed right away:
![screenshot 11](Screenshot 2025-11-22 113610/b_TheCVEcontainerStillGetsKilled.png)
---
