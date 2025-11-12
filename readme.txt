Here are the comman to run the falco and test:

🔴Be careful: the pwd need to have falco.yaml, falco_custom_rules.yaml, falco-action.sh to work🔴 


📦For falco rules:

sudo docker run --pid=host --rm -t \
  --name falco \
  --privileged \
  -v /sys/kernel/tracing:/sys/kernel/tracing:ro \
  -v /var/run/docker.sock:/host/var/run/docker.sock \
  -v /proc:/host/proc:ro \
  -v /etc:/host/etc:ro \
  -v $(pwd)/falco.yaml:/etc/falco/falco.yaml:ro \
  -v $(pwd)/falco_custom_rules.yaml:/etc/falco/falco_rules.local.yaml:ro \
  -v $(pwd)/falco-action.sh:/usr/local/bin/falco-action.sh \
  falcosecurity/falco:0.42.0

⚙️Explaination: 
This command sets up the falco in a container.


sudo
=>need this power to run the command

docker run
=>Creates and runs a new container

--pid=host  
=> this will give the container the host's process ID namespace, which allows the container to see which processes are running oh the host system. We need this to kill the container from the host.
(I tried docker inspect but it will not give the container's PID in host, but the process inside the container)

--rm
=> this removes the container after container stops. Using this to quickly test the new config files.

-t
=> for a pseudo-terminal, so that we can see the output in runtime.

--name falco
=> set the name of the container to be "falco"

--privileged
=>  this gives container privilege power, so that it can do powerful things like monitor and kill

-v 
=> volume Mounts, makes the host files visible to the container

:ro 
=> read only

-v /sys/kernel/tracing:/sys/kernel/tracing:ro
=>Mounts the kernel tracing interface, read-only

-v /var/run/docker.sock:/host/var/run/docker.sock
=>Mounts the Docker socket so Falco can detect container start/stop events.

-v /proc:/host/proc:ro
=>Mounts the host’s /proc filesystem, so that falco can reads process, network, and mount info

-v /etc:/host/etc:ro
=>Mounts the host’s /etc, so that Falco can inspect sensitive actions in /etc, example: /etc/shadow

-v $(pwd)/falco.yaml:/etc/falco/falco.yaml:ro
=>Overrides the default Falco configuration inside the container. pwd is the path of work directory now. In falco.yaml, I made some changes on top of default falco file. Details see inside the falco.yaml. Search for "--zijian", you can read my comment.

-v $(pwd)/falco_custom_rules.yaml:/etc/falco/falco_rules.local.yaml:ro
=>Adds custom Falco detection rules, in YAML format. This run with the default rules. I added only on custom rule, which is to detecte chdir to change work directory to proc/self/fd/* files. This is a spectial security measure against CVE-2024-21626

-v $(pwd)/falco-action.sh:/usr/local/bin/falco-action.sh
=>Mounts a custom .sh script into the container. So that we can run some #!/bin/sh commands. This is where the killing of the container happens. This script will read event json output each time falco makes some detection.

falcosecurity/falco:0.42.0
=>Specifies the Falco image and version tag.

📦For testing dockers to run:

sudo docker run  -w /proc/self/fd/8 --name attack --rm -it debian:bookworm

⚙️Explaination:
This command is a CVE-2024-21626 attack.

-w 
=> set work directory.

-w /proc/self/fd/8 
=> set work directory to /proc/self/fd/8, as the CVE-2024-21626 shown, we need to find this leaked fd first. In my vm's case it's /proc/self/fd/8

sudo docker run -it alpine sh

⚙️Explaination:
This command just creates and runs a test container, to show that our falco doesn't kill everthing.

-it 
=> i for interactive, t for pseudo-terminal, so that we can interact and having a proper CLI. 

📦For falco-action.sh's log:

docker exec falco cat /var/log/falco-actions.log
🔴*run this command while falco container is running.*🔴
⚙️Explaination:
Run this command to show the log file from our falco-actions.sh code.

docker exec 
=>This command run an addtional process in a running container

cat /var/log/falco-actions.log
=>Display the log file

📦For falco's log:

docker cp <container_id>:./events.txt ./falco_con.log

example:
	docker cp e05a6fbda079:./events.txt ./falco_con.log
🔴*run this command while falco container is running. In our case, container is removed after stop*🔴
⚙️Explaination:
Run this command to copy the log file outputed by the falco.

    PS:
	In falco.yaml file (you can search "--zijian" in the file to see the command)
		file_output:
		  enabled: true 
		  keep_alive: false 
		  filename: ./events.txt

similar we can have this for .sh code:

docker cp <container_id>:/var/log/falco-actions.log ./falco_action.log
(I'm not going to explain this)
