.PHONY: list

# https://stackoverflow.com/a/26339924/
# How do you get the list of targets in a makefile?
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'


#------------------------
# gcp targets
#------------------------

setup_cpu_gcp: check_cf_env_set create_cpu_gcp wait \
ssl_redirect_gcp update_ip_gcp_cf

setup_gpu_gcp: check_cf_env_set create_gpu_gcp \
wait_exist_vm wait wait_running_container \
install_nvidia_container check_nvidia \
install_pyro_container \
ssl_redirect_gcp update_ip_gcp_cf \
restart_container

delete_previous_gcp: print_make_vars stop_previous_gcp detach_data_disk_gcp
	gcloud compute instances delete --quiet $(GCP_VM_PREVIOUS) || true

switch_gcp: stop_previous_gcp detach_data_disk_gcp attach_data_disk_gcp start_gcp wait ssl_redirect_gcp update_ip_gcp_cf

create_cpu_gcp:
	@if [ "$(CHECK_VM)" = "$(GCP_VM)" ]; then\
		echo "* $(GCP_VM) already exists; proceeding to start" ;\
		gcloud compute instances start $(GCP_VM) ;\
	else \
		echo "* $(GCP_VM) DOES NOT exist; proceeding with creation" ;\
	    gcloud compute instances create-with-container $(GCP_VM) \
		--image-project=gce-uefi-images \
		--image-family=cos-stable \
	    --container-image $(DOCKER_URL) \
	    --container-restart-policy on-failure \
	    --container-privileged \
	    --container-stdin \
	    --container-tty \
	    --container-mount-host-path mount-path=/home/jupyter,host-path=/home/jupyter,mode=rw \
	    --container-command "jupyter" \
	    --container-arg="lab" \
	    --container-arg="--ip=0.0.0.0" \
	    --container-arg="--port=8443" \
	    --container-arg="--NotebookApp.allow_origin='*'" \
	    --container-arg="--NotebookApp.ip='*'" \
	    --container-arg="--NotebookApp.certfile='/data/jovyan/certs/cf-cert.pem'" \
	    --container-arg="--NotebookApp.keyfile='/data/jovyan/certs/cf-key.pem'" \
	    --container-arg="--NotebookApp.notebook_dir='/data/jovyan/projects'" \
	    --machine-type n1-standard-4 \
	    --boot-disk-size 200GB \
	    --disk auto-delete=no,boot=no,device-name=data,mode=rw,name=data \
	    --container-mount-disk mode=rw,mount-path=/data,name=data \
	    --tags=http-server,https-server \
	    --preemptible ;\
	fi

create_gpu_gcp:
	@if [ "$(CHECK_VM)" = "$(GCP_VM)" ]; then\
		echo "* $(GCP_VM) already exists; proceeding to start" ;\
		gcloud compute instances start $(GCP_VM) ;\
	else \
		echo "* $(GCP_VM) DOES NOT exist; proceeding with creation" ;\
	    gcloud compute instances create-with-container $(GCP_VM) \
		--image-project=gce-uefi-images \
		--image-family=cos-stable \
	    --container-image $(DOCKER_URL) \
	    --container-restart-policy on-failure \
	    --container-privileged \
	    --container-stdin \
	    --container-tty \
	    --container-mount-host-path mount-path=/home/jupyter,host-path=/home/jupyter,mode=rw \
	    --container-command "jupyter" \
	    --container-arg="lab" \
	    --container-arg="--ip=0.0.0.0" \
	    --container-arg="--port=8443" \
	    --container-arg="--NotebookApp.allow_origin='*'" \
	    --container-arg="--NotebookApp.ip='*'" \
	    --container-arg="--NotebookApp.certfile='/data/jovyan/certs/cf-cert.pem'" \
	    --container-arg="--NotebookApp.keyfile='/data/jovyan/certs/cf-key.pem'" \
	    --container-arg="--NotebookApp.notebook_dir='/data/jovyan/projects'" \
	    --machine-type n1-standard-4 \
	    --boot-disk-size 200GB \
	    --disk auto-delete=no,boot=no,device-name=data,mode=rw,name=data \
	    --container-mount-disk mode=rw,mount-path=/data,name=data \
	    --tags=http-server,https-server \
	    --preemptible \
	    --accelerator count=1,type=nvidia-tesla-t4 \
	    --container-mount-host-path mount-path=/usr/local/nvidia/lib64,host-path=/var/lib/nvidia/lib64,mode=rw \
	    --container-mount-host-path mount-path=/usr/local/nvidia/bin,host-path=/var/lib/nvidia/bin,mode=rw \
	    --metadata-from-file startup-script=scripts/install-cos-gpu.sh ;\
	fi

update_gcp:
	gcloud compute instances update-container $(GCP_VM) \
	--container-command "jupyter" \
	--container-arg="lab" \
	--container-arg="--ip=0.0.0.0" \
	--container-arg="--port=8443" \
	--container-arg="--NotebookApp.allow_origin='*'" \
	--container-arg="--NotebookApp.ip='*'" \
	--container-arg="--NotebookApp.certfile='/data/jovyan/certs/cf-cert.pem'" \
	--container-arg="--NotebookApp.keyfile='/data/jovyan/certs/cf-key.pem'" \
	--container-arg="--NotebookApp.notebook_dir='/data/jovyan/projects'" \
	--container-mount-host-path mount-path=/usr/local/nvidia/lib64,host-path=/var/lib/nvidia/lib64,mode=rw \
	--container-mount-host-path mount-path=/usr/local/nvidia/bin,host-path=/var/lib/nvidia/bin,mode=rw

start_gcp:
	gcloud compute instances start $(GCP_VM)

stop_gcp:
	gcloud compute instances stop $(GCP_VM) || true

stop_previous_gcp:
	gcloud compute instances stop $(GCP_VM_PREVIOUS) || true

ssh_gcp:
	gcloud compute ssh $(GCP_VM)

ssh_container_gcp:
	gcloud compute ssh $(GCP_VM) --container $(GCP_CONTAINER)

update_container_image: start_gcp wait
	gcloud compute ssh $(USER_NAME)@$(GCP_VM) \
	--command 'docker images && docker pull $(DOCKER_URL) && docker images'

restart_container:
	gcloud compute ssh $(USER_NAME)@$(GCP_VM) \
	--command 'docker restart $(GCP_CONTAINER)'

debug_container:
	gcloud compute instances update-container $(GCP_VM) \
	--container-command "/bin/sh" \
	--clear-container-args

attach_data_disk_gcp:
	gcloud compute instances attach-disk $(GCP_VM) --disk=data --device-name=data --mode=rw

detach_data_disk_gcp:
	gcloud compute instances detach-disk $(GCP_VM_PREVIOUS) --disk=data || true

check_exist_vm:
	@if [ $(CHECK_VM) = $(GCP_VM) ]; then\
		echo "* $(GCP_VM) already exists" ;\
	else \
		echo "* $(GCP_VM) DOES NOT exist" ;\
	fi

wait_exist_vm:
	@while [ "$$VM" != "$(GCP_VM)" ]; do\
		echo "* waiting for $(GCP_VM)" ;\
		sleep 5 ;\
		VM=`gcloud compute instances list --filter="name=$(GCP_VM)" | grep -o $(GCP_VM)` ;\
	done ;\
	echo "* $(GCP_VM) is now available"

wait_running_container:
	@while [ "$$CONTAINER_IMAGE" != "$(DOCKER_URL)" ]; do \
		echo "* waiting for container" ;\
		sleep 5 ;\
		CONTAINER_IMAGE=`gcloud compute ssh $(USER_NAME)@$(GCP_VM) --command "docker ps --filter 'status=running' --filter 'ancestor=$(DOCKER_URL)' --format '{{.Image}}'"` ;\
	done ;\
	CONTAINER_ID=`gcloud compute ssh $(USER_NAME)@$(GCP_VM) --command "docker ps --filter 'status=running' --filter 'ancestor=$(DOCKER_URL)' --format '{{.ID}}'"` ;\
	echo "* container $$CONTAINER_ID for image $$CONTAINER_IMAGE is now available"

install_nvidia_container:
	gcloud compute ssh $(USER_NAME)@$(GCP_VM) \
	--command "docker exec -u 0 $(GCP_CONTAINER) sh -c '\
			export LD_LIBRARY_PATH=/usr/local/nvidia/lib64 && \
			pacman -Sy --needed --noconfirm cudnn'"

check_nvidia:
	gcloud compute ssh $(USER_NAME)@$(GCP_VM) \
	--command "docker exec -u 0 $(GCP_CONTAINER) sh -c 'LD_LIBRARY_PATH=/usr/local/nvidia/lib64 /usr/local/nvidia/bin/nvidia-smi'"

install_pyro_container:
	gcloud compute ssh $(USER_NAME)@$(GCP_VM) \
	--command "docker exec -u 0 $(GCP_CONTAINER) sh -c '\
			export LD_LIBRARY_PATH=/usr/local/nvidia/lib64 && \
			pip install torch==1.7.1+cu110 torchvision==0.8.2+cu110 torchaudio===0.7.2 -f https://download.pytorch.org/whl/torch_stable.html && \
			pip install pyro-ppl'"

get_container_id:
	gcloud compute ssh $(USER_NAME)@$(GCP_VM) \
	--command "docker ps --filter 'status=running' --filter 'ancestor=$(DOCKER_URL)' --format '{{.ID}}'"

ssl_cert_copy_to_gcp:
	gcloud compute scp --recurse etc/certs \
	$(USER_NAME)@$(GCP_VM):/mnt/disks/gce-containers-mounts/gce-persistent-disks/data/jovyan

check_cf_env_set:
	@if [ -z "$$CF_API_KEY" ] || [ -z "$$CF_ZONE" ] || [ -z "$$CF_RECORD_ID" ] || [ -z "$$CF_EMAIL" ] || [ -z "$$CF_DOMAIN" ]; then \
		echo "* one or more variables required by scripts/cloudflare-update.sh are undefined";\
		exit 1;\
	else \
		echo "* cloudflare variables required by scripts/cloudflare-update.sh all defined";\
    fi

ssl_redirect_gcp:
	gcloud compute ssh $(USER_NAME)@$(GCP_VM) \
	--command 'sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8443'

update_ip_gcp_cf: check_cf_env_set
	scripts/cloudflare-update.sh $(GCP_IP) | json_pp

cos_versions_gcp:
	gcloud compute images list --project cos-cloud --no-standard-images

set_tags_gcp:
	gcloud compute instances remove-tags $(GCP_VM) --tags=http-server
	gcloud compute instances add-tags $(GCP_VM) --tags=https-server

wait:
	sleep 30


#-----------------------#
# Make variables
#-----------------------#

DOCKER_REGISTRY=registry.hub.docker.com
DOCKER_USER=cameronraysmith

DOCKER_CONTAINER=notebooks
DOCKER_IMAGE=$(DOCKER_USER)/$(DOCKER_CONTAINER)
DOCKER_TAG=develop
DOCKER_URL=$(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG)

GIT_COMMIT = $(strip $(shell git rev-parse --short HEAD))

GCP_VM=notebooks-gpu-vm
CHECK_VM=$(shell gcloud compute instances list --filter="name=$(GCP_VM)" | grep -o $(GCP_VM))
GCP_VM_PREVIOUS=notebooks-gpu-vm
GCP_IP=$(shell gcloud compute instances describe $(GCP_VM) --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
GCP_CONTAINER=$(shell gcloud compute ssh $(USER_NAME)@$(GCP_VM) --command "docker ps | grep $(GCP_VM) | cut -d' ' -f1")
USER_NAME=jovyan

print_make_vars:
	$(info    DOCKER_REGISTRY is $(DOCKER_REGISTRY))
	$(info    DOCKER_IMAGE is $(DOCKER_IMAGE))
	$(info    DOCKER_TAG is $(DOCKER_TAG))
	$(info    GIT_COMMIT is $(GIT_COMMIT))
	$(info    USER_NAME is $(USER_NAME))
	$(info    GCP_VM is $(GCP_VM))
	$(info    CHECK_VM is $(CHECK_VM))
	$(info    GCP_IP is $(GCP_IP))
	$(info    GCP_VM_PREVIOUS is $(GCP_VM_PREVIOUS))
	$(info    GCP_CONTAINER is $(GCP_CONTAINER))

# Get the version number from the code
CODE_VERSION = $(strip $(shell cat VERSION))

ifndef CODE_VERSION
$(error You need to create a VERSION file to build a release)
endif

#------------------------
# comments
#------------------------

#		--container-arg="--NotebookApp.password=<type:salt:hashed-password>" \#
#		--container-arg="--NotebookApp.ResourceUseDisplay.mem_limit=4026531840" \#
#		--container-arg="--NotebookApp.ResourceUseDisplay.track_cpu_percent=True" \#
#		--container-arg="--NotebookApp.ResourceUseDisplay.cpu_limit=1" \#

# Find out if the working directory is clean
# GIT_NOT_CLEAN_CHECK = $(shell git status --porcelain)
# ifneq (x$(GIT_NOT_CLEAN_CHECK), x)
# DOCKER_TAG_SUFFIX = -dirty
# endif

# Add the commit sha and mark as dirty if the working directory isn't clean
# ifeq ($(TYPE),dev)
# 	DOCKER_TAG = $(CODE_VERSION)-dev
# else
# 	DOCKER_TAG = $(CODE_VERSION)-$(GIT_COMMIT)$(DOCKER_TAG_SUFFIX)
# endif

#------------------------
# local targets
#------------------------

# Build Docker image
# specify TYPE=dev to get builds based on Dockerfile.dev
build: docker_build build_output

build_and_push: docker_build build_output docker_push

srv:
	docker run -it -p 8099:8080 \
        -v $(shell pwd)/notebooks:/home/jovyan/notebooks \
        --label=notebooks \
        $(DOCKER_IMAGE):$(DOCKER_TAG)

srvlatest:
	docker run -it -p 8099:8080 \
        -v $(shell pwd)/notebooks:/home/jovyan/notebooks \
        --label=notebooks \
        $(DOCKER_IMAGE):latest

restart: kill srv;

sh:
	docker run -it \
    --label=notebooks \
    $(DOCKER_IMAGE):$(DOCKER_TAG) /bin/zsh

clean:
	docker stop `docker ps -f label="notebooks" -q` || true && \
		docker rm $(DOCKER_IMAGE):$(DOCKER_TAG) || true && \
		docker rmi $(DOCKER_IMAGE):$(DOCKER_TAG)

kill:
	docker container ls -a
	docker stop `docker ps -f label="notebooks" -q` || true
	docker container prune --force --filter label="notebooks"

docker_push:
    # Push to DockerHub
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

docker_build:
# Build Docker image
ifeq ($(TYPE),dev)
	docker build \
	-f Dockerfile.dev \
	-t $(DOCKER_IMAGE):$(DOCKER_TAG) .
else
	docker build \
  --build-arg VCS_URL=`git config --get remote.origin.url` \
  --build-arg VCS_REF=$(GIT_COMMIT) \
  --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
  --build-arg VERSION=$(CODE_VERSION) \
	-t $(DOCKER_IMAGE):$(DOCKER_TAG) .
endif

build_output:
	@echo Docker Image: $(DOCKER_IMAGE):$(DOCKER_TAG)
