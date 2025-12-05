

check:
dpkg -l | grep docker
dpkg -l | grep containerd
dpkg -l | grep runc

===============================Content for docker_reinstall.sh==========================================
rm:
sudo dpkg --purge docker-ce docker-ce-cli containerd.io runc
sudo dpkg --purge docker docker-engine docker.io
sudo rm -f /usr/bin/docker /usr/bin/dockerd /usr/bin/docker-containerd* /usr/bin/runc
sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker

install:
sudo dpkg -i containerd.io_1.2.0-1_amd64.deb
sudo dpkg -i docker-ce-cli_18.09.0~3-0~ubuntu-bionic_amd64.deb
sudo dpkg -i docker-ce_18.09.0~3-0~ubuntu-xenial_amd64.deb
========================================================================================================


Local falco Setup:
cd falco

sudo cp falco.yaml /etc/falco/falco.yaml 
sudo cp falco_custom_rules.yaml /etc/falco/falco_rules.local.yaml
sudo cp falco-action.sh /usr/local/bin/falco-action.sh
sudo chmod +x /usr/local/bin/falco-action.sh

sudo cp cleanup_lab.sh /usr/local/bin/cleanup_lab.sh 
sudo chmod +x /usr/local/bin/cleanup_lab.sh
sudo cp docker_reinstall.sh /usr/local/bin/docker_reinstall.sh 
sudo chmod +x /usr/local/bin/docker_reinstall.sh


For the demo, we need the the dockerfile in the CVE-2019-5736 branch to build the malicious iamges first.
That's why I would copy falco folder to local directory, then switch branch back to CVE-2019-5736




Demo:
lsb_release -a


Reinstall RunC and Docker environment:

cd falco
sudo ./docker_reinstall.sh   (pay attention to the path in the script)


Set up the cve environment-> building images and run a excution container to receive the connection. (don't run falco here, falco will stop the building process)
cd ~/INSE6130
sudo ./cve_setup.sh


falco:

cd falco

sudo falco -c /etc/falco/falco.yaml



CVE-2019-5736:

sudo apparmor_parser -r -W docker-hardened

============content of cve_setup.sh=============================
sudo docker build -t cve:execution ./execution
sudo docker run -d --rm --name control cve:execution
sudo docker exec control bash
================================================================

new terminal:
nc -nvlp 2345

sudo docker build -t cve:malicious_image ./malicious_image
sudo docker run --rm --security-opt apparmor=docker-hardened cve:malicious_image           # will not succeed

Without AppArmor:
sudo docker run --rm cve:malicious_image





ls /usr/local/bin
cat /var/log/falco-actions.log
cat /var/log/falco_response.log




























sudo docker run --pid=host --rm -it   --name falco   --privileged  -v /sys/kernel/tracing:/sys/kernel/tracing:ro  -v /dev:/host/dev   -v /var/run/docker.sock:/var/run/docker.sock   -v /proc:/host/proc:ro   -v /etc:/host/etc:ro -v /boot:/host/boot:ro -v /usr:/host/usr:ro  -v /lib/modules:/host/lib/modules:ro -v /usr/bin/docker:/usr/bin/docker:ro -v /var/log:/var/log -v $(pwd)/falco.yaml:/etc/falco/falco.yaml:ro   -v $(pwd)/falco_custom_rules.yaml:/etc/falco/falco_rules.local.yaml:ro   -v $(pwd)/falco-action.sh:/usr/local/bin/falco-action.sh    falcosecurity/falco:0.35.1
