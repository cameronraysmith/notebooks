.PHONY: list

# https://stackoverflow.com/a/26339924/
# How do you get the list of targets in a makefile?
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'


#-------------------------------------------#
# user-specific variables (should be reviewed/edited)
#-------------------------------------------#

# unique identifier within the project
# for the VM and your DATA_DISK
GCP_VM_IDENTIFIER=cameron

# the SHA1-hashed password for the jupyter server
# e.g.
# %HfuQRa@X%9&8MxM
# becomes
# JUPYTER_PASSWORD=sha1:0af606f6f6ce:11fe6ae47992d2d7a9015d322cf75e5a77c57149
JUPYTER_PASSWORD=sha1:95a03035ad41:45b8758ed94c7373d82b2516375cde9118f0422f


# cpu vs gpu
PROCESSOR_MODE=cpu

# true vs false
HTTPS=true

# gcloud compute zone
GCP_PROJECT=quarere
GCP_REGION=us-central1
GCP_ZONE=$(GCP_REGION)-f

#----------------------------------------#
# default variables (may require editing)
#----------------------------------------#

DOCKER_REGISTRY=docker.io
DOCKER_USER=cameronraysmith
DOCKER_CONTAINER=notebooks
DOCKER_TAG=latest
USER_NAME=jovyan
NOTEBOOKS_DIR=projects

GCP_MACHINE_TYPE=n1-highmem-32 # n1-standard-4 # n1-highmem-8 # n1-highmem-4
GCP_ACCELERATOR_TYPE=nvidia-tesla-t4
# GCP_MACHINE_TYPE=a2-highgpu-1g
# GCP_ACCELERATOR_TYPE=nvidia-tesla-a100
# GCP_MACHINE_TYPE=a2-ultragpu-1g
# GCP_ACCELERATOR_TYPE=nvidia-a100-80gb
GCP_ACCELERATOR_COUNT=1

COS_FAMILY=cos-101-lts

DATA_DISK_SIZE=200GB
BOOT_DISK_SIZE=200GB
DISK_SNAPSHOT_ID=09032022-01

JUPYTER_PORT=8443

#-------------------#
# derived variables
#-------------------#
ifeq ($(HTTPS),true)
  EXTERNAL_PORT=443
else
  EXTERNAL_PORT=80
endif

# DATA_DISK=data
DATA_DISK=data-$(GCP_VM_IDENTIFIER)

GCP_VM_PREVIOUS=$(GCP_VM)

# e.g. cameronraysmith/notebooks
DOCKER_IMAGE=$(DOCKER_USER)/$(DOCKER_CONTAINER)
# e.g. registry.hub.docker.com/cameronraysmith/notebooks:latest
# e.g. docker.io/cameronraysmith/notebooks:latest
DOCKER_URL=$(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG)
# e.g. notebooks-gpu-latest
GCP_VM=$(DOCKER_CONTAINER)-$(DOCKER_TAG)-$(PROCESSOR_MODE)-$(EXTERNAL_PORT)-$(DATA_DISK)
CHECK_VM=$(shell gcloud compute instances list --filter="name=$(GCP_VM)" | grep -o $(GCP_VM))
CHECK_DATA_DISK=$(shell gcloud compute disks list --filter="name=$(DATA_DISK) AND zone:($(GCP_ZONE))" | grep -o $(DATA_DISK))
GCP_IP=$(shell gcloud compute instances describe $(GCP_VM) --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
GCP_CONTAINER=$(shell gcloud compute ssh $(GCP_VM) --command "docker ps --filter 'status=running' --filter 'ancestor=$(DOCKER_IMAGE):$(DOCKER_TAG)' --format '{{.ID}}'")

GIT_COMMIT = $(strip $(shell git rev-parse --short HEAD))
CODE_VERSION = $(strip $(shell cat VERSION))

#------------------------
# gcp targets
#------------------------

ifeq ($(HTTPS),true)
initialize_gcp: \
  check_cf_env_set \
  update_gcp_zone \
  create_data_disk \
  wait \
  create_gcp \
  wait_exist_vm \
  wait_1 \
  wait_running_container \
  create_notebooks_dir_gcp \
  ssl_cert_copy_to_gcp \
  restart_container_1 \
  wait_2 \
  check_nvidia \
  install_libraries_container \
  external_port_redirect_gcp \
  update_ip_gcp_cf \
  restart_container_2
else
initialize_gcp: \
  update_gcp_zone \
  create_data_disk \
  create_gcp \
  wait_exist_vm \
  wait_1 \
  wait_running_container \
  create_notebooks_dir_gcp \
  update_gcp_insecure \
  wait_2 \
  wait_running_container_2 \
  check_nvidia \
  install_libraries_container \
  external_port_redirect_gcp \
  restart_container_1
endif

ifeq ($(HTTPS),true)
startup_gcp: \
  check_cf_env_set \
  update_gcp_zone \
  create_gcp \
  wait_exist_vm \
  wait_1 \
  update_container_image \
  wait_2 \
  restart_container_1 \
  wait_running_container \
  check_nvidia \
  install_libraries_container \
  external_port_redirect_gcp \
  update_ip_gcp_cf \
  restart_container_2
else
startup_gcp: \
  update_gcp_zone \
  create_gcp \
  wait_exist_vm \
  wait_1 \
  update_container_image \
  wait_2 \
  restart_container_1 \
  wait_running_container \
  check_nvidia \
  install_libraries_container \
  external_port_redirect_gcp \
  restart_container_2
endif

# check_cf_env_set \
# update_ip_gcp_cf \

quick_startup_gcp: \
  check_cf_env_set \
  update_gcp_zone \
  create_gcp \
  wait_exist_vm \
  wait_running_container \
  external_port_redirect_gcp \
  update_ip_gcp_cf

STORAGE_BUCKET_IMAGES = $(GCP_PROJECT)-nixos-images
IMAGE_NAME = nixos-image-2205pre351617942b0817e89-x8664-linux
IMAGE_FILENAME = nixos-image-22.05pre351617.942b0817e89-x86_64-linux.raw.tar.gz
IMAGE_INSTANCE_NAME = nixos-instance-01

create_image:
	gcloud compute images create $(IMAGE_NAME) \
  --project=$(GCP_PROJECT) \
  --source-uri=https://storage.googleapis.com/$(STORAGE_BUCKET_IMAGES)/$(IMAGE_FILENAME) \
  --storage-location=$(GCP_REGION)

create_image_instance:
	gcloud compute instances create $(IMAGE_INSTANCE_NAME) \
  --project=$(GCP_PROJECT) \
  --zone=$(GCP_ZONE) \
  --machine-type=$(GCP_MACHINE_TYPE) \
  --metadata=enable-oslogin=TRUE \
  --create-disk=auto-delete=yes,boot=yes,device-name=nixos-instance-01,image=projects/$(GCP_PROJECT)/global/images/$(IMAGE_NAME),mode=rw,size=200,type=projects/$(GCP_PROJECT)/zones/$(GCP_ZONE)/diskTypes/pd-balanced \
  --reservation-affinity=any \
  --preemptible
  # --no-address \ #
  # --network-interface=network-tier=PREMIUM,subnet=default \ #
  # --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \ #
  # --maintenance-policy=MIGRATE \ #
  # --service-account=513975745977-compute@developer.gserviceaccount.com \ #

update_gcp_machine_type:
	gcloud compute instances set-machine-type $(GCP_VM) --machine-type $(GCP_MACHINE_TYPE)

update_gcp_zone:
	gcloud config set compute/zone $(GCP_ZONE)

list_disk_snapshots:
    gcloud compute snapshots list --sort-by=~creationTimestamp

create_data_disk_snapshot:
	gcloud compute snapshots create $(DATA_DISK)-$(DISK_SNAPSHOT_ID) \
	--project=$(GCP_PROJECT) \
	--source-disk=$(DATA_DISK) \
	--source-disk-zone=$(GCP_ZONE) \
	--storage-location=$(GCP_REGION)

# e.g.
# make restore_data_disk_from_snapshot DATA_DISK=test-restore DATA_DISK_SNAPSHOT=data-user-us-east1-d-20210426075809-k126gh50
#  --source-snapshot=$(DATA_DISK_SNAPSHOT) \#
restore_data_disk_from_snapshot:
	gcloud compute disks create $(DATA_DISK) \
  --type=pd-standard \
  --source-snapshot=$(DATA_DISK)-$(DISK_SNAPSHOT_ID) \
  --resource-policies=projects/$(GCP_PROJECT)/regions/$(GCP_REGION)/resourcePolicies/schedule-data-disk \
  --size=$(DATA_DISK_SIZE) \
  --zone=$(GCP_ZONE)

create_boot_disk_snapshot:
  gcloud compute snapshots create $(GCP_VM_PREVIOUS)-$(DISK_SNAPSHOT_ID) \
  --project=$(GCP_PROJECT) \
  --source-disk=$(GCP_VM_PREVIOUS) \
  --source-disk-zone=$(GCP_ZONE) \
  --storage-location=$(GCP_REGION)
# 	--labels=notebooks=$(DOCKER_TAG) \#

restore_boot_disk_from_snapshot:
	gcloud compute disks create $(GCP_VM_PREVIOUS) \
	--project=$(GCP_PROJECT) \
	--type=pd-standard \
	--size=$(BOOT_DISK_SIZE) \
	--resource-policies=projects/$(GCP_PROJECT)/regions/$(GCP_REGION)/resourcePolicies/schedule-data-disk \
	--zone=$(GCP_ZONE) \
	--source-snapshot=$(GCP_VM_PREVIOUS)-$(DISK_SNAPSHOT_ID) || true

# make restore_gcp DISK_SNAPSHOT_ID=10062022-02
restore_gcp: restore_boot_disk_from_snapshot restore_data_disk_from_snapshot startup_gcp
	@echo "* restore VM $(GCP_VM)"

# make delete_gcp DISK_SNAPSHOT_ID=10062022-02
delete_gcp: print_make_vars stop_previous_gcp create_boot_disk_snapshot create_data_disk_snapshot detach_data_disk_gcp
	@echo "* delete VM $(GCP_VM_PREVIOUS)"
	gcloud compute instances delete --quiet $(GCP_VM_PREVIOUS)
	@echo "* remove GCP known hosts file"
	rm ~/.ssh/google_compute_known_hosts || true

create_data_disk:
	@if [ "$(CHECK_DATA_DISK)" = "$(DATA_DISK)" ]; then\
		echo "* a disk named \"$(DATA_DISK)\" already exists" ;\
	else \
		gcloud compute disks create $(DATA_DISK) --size=$(DATA_DISK_SIZE) --zone=$(GCP_ZONE);\
	fi

switch_gcp: stop_previous_gcp detach_data_disk_gcp attach_data_disk_gcp start_gcp wait_1 external_port_redirect_gcp update_ip_gcp_cf

create_gcp:
	@if [ "$(CHECK_VM)" = "$(GCP_VM)" ]; then \
		echo "* $(GCP_VM) already exists; proceeding to start" ;\
		gcloud compute instances start $(GCP_VM) ;\
	elif [ "$(PROCESSOR_MODE)" = "cpu" ]; then \
		echo "* $(GCP_VM) DOES NOT exist; proceeding with creation" ;\
	    gcloud compute instances create-with-container $(GCP_VM) \
	    --image-project=cos-cloud \
	    --image-family=$(COS_FAMILY) \
	    --container-image $(DOCKER_URL) \
	    --container-restart-policy on-failure \
	    --container-privileged \
	    --container-stdin \
	    --container-tty \
	    --container-mount-host-path mount-path=/home/jupyter,host-path=/home/jupyter,mode=rw \
	    --container-command "jupyter" \
	    --container-arg="lab" \
	    --container-arg="--ServerApp.port=$(JUPYTER_PORT)" \
	    --container-arg="--ServerApp.allow_origin=*" \
	    --container-arg="--ServerApp.ip=*" \
	    --container-arg="--ServerApp.certfile=/$(DATA_DISK)/$(USER_NAME)/certs/cert.pem" \
	    --container-arg="--ServerApp.keyfile=/$(DATA_DISK)/$(USER_NAME)/certs/key.pem" \
	    --container-arg="--ServerApp.root_dir=/$(DATA_DISK)/$(USER_NAME)/$(NOTEBOOKS_DIR)" \
	    --container-arg="--ServerApp.password=$(JUPYTER_PASSWORD)" \
	    --machine-type $(GCP_MACHINE_TYPE) \
	    --boot-disk-size $(BOOT_DISK_SIZE) \
	    --disk auto-delete=no,boot=no,device-name=$(DATA_DISK),mode=rw,name=$(DATA_DISK) \
	    --container-mount-disk mode=rw,mount-path=/$(DATA_DISK),name=$(DATA_DISK) \
	    --tags=http-server,https-server \
	    --preemptible ;\
	elif [ "$(PROCESSOR_MODE)" = "gpu" ]; then \
		echo "* $(GCP_VM) DOES NOT exist; proceeding with creation" ;\
	    gcloud compute instances create-with-container $(GCP_VM) \
	    --image-project=cos-cloud \
	    --image-family=$(COS_FAMILY) \
	    --container-image $(DOCKER_URL) \
	    --container-restart-policy on-failure \
	    --container-privileged \
	    --container-stdin \
	    --container-tty \
	    --container-mount-host-path mount-path=/home/jupyter,host-path=/home/jupyter,mode=rw \
	    --container-command "jupyter" \
	    --container-arg="lab" \
	    --container-arg="--ServerApp.port=$(JUPYTER_PORT)" \
	    --container-arg="--ServerApp.allow_origin=*" \
	    --container-arg="--ServerApp.ip=*" \
	    --container-arg="--ServerApp.certfile=/$(DATA_DISK)/$(USER_NAME)/certs/cert.pem" \
	    --container-arg="--ServerApp.keyfile=/$(DATA_DISK)/$(USER_NAME)/certs/key.pem" \
	    --container-arg="--ServerApp.root_dir=/$(DATA_DISK)/$(USER_NAME)/$(NOTEBOOKS_DIR)" \
	    --container-arg="--ServerApp.password=$(JUPYTER_PASSWORD)" \
	    --machine-type $(GCP_MACHINE_TYPE) \
	    --boot-disk-size $(BOOT_DISK_SIZE) \
	    --disk auto-delete=no,boot=no,device-name=$(DATA_DISK),mode=rw,name=$(DATA_DISK) \
	    --container-mount-disk mode=rw,mount-path=/$(DATA_DISK),name=$(DATA_DISK) \
	    --tags=http-server,https-server \
	    --preemptible \
	    --accelerator count=$(GCP_ACCELERATOR_COUNT),type=$(GCP_ACCELERATOR_TYPE) \
	    --container-mount-host-path mount-path=/usr/local/nvidia/lib64,host-path=/var/lib/nvidia/lib64,mode=rw \
	    --container-mount-host-path mount-path=/usr/local/nvidia/bin,host-path=/var/lib/nvidia/bin,mode=rw \
	    --metadata-from-file startup-script=scripts/install-cos-gpu.sh ;\
	else \
		echo "* check that you have specified a support PROCESSOR_MODE (gpu or cpu)" ;\
		echo "* PROCESSOR_MODE currently set to $(PROCESSOR_MODE)" ;\
	fi


update_gcp:
	gcloud compute instances update-container $(GCP_VM) \
	--container-command "jupyter" \
	--container-arg="lab" \
	--container-arg="--ServerApp.port=$(JUPYTER_PORT)" \
	--container-arg="--ServerApp.allow_origin=*" \
	--container-arg="--ServerApp.ip=*" \
	--container-arg="--ServerApp.certfile=/$(DATA_DISK)/$(USER_NAME)/certs/cert.pem" \
	--container-arg="--ServerApp.keyfile=/$(DATA_DISK)/$(USER_NAME)/certs/key.pem" \
	--container-arg="--ServerApp.root_dir=/$(DATA_DISK)/$(USER_NAME)/$(NOTEBOOKS_DIR)" \
	--container-arg="--ServerApp.password=$(JUPYTER_PASSWORD)" \
	--container-mount-host-path mount-path=/usr/local/nvidia/lib64,host-path=/var/lib/nvidia/lib64,mode=rw \
	--container-mount-host-path mount-path=/usr/local/nvidia/bin,host-path=/var/lib/nvidia/bin,mode=rw

update_gcp_insecure:
	gcloud compute instances update-container $(GCP_VM) \
	--container-command "jupyter" \
	--container-arg="lab" \
	--container-arg="--ServerApp.port=$(JUPYTER_PORT)" \
	--container-arg="--ServerApp.allow_origin=*" \
	--container-arg="--ServerApp.ip=*" \
	--container-arg="--ServerApp.root_dir=/$(DATA_DISK)/$(USER_NAME)/$(NOTEBOOKS_DIR)" \
	--container-arg="--ServerApp.password=$(JUPYTER_PASSWORD)" \
	--container-mount-host-path mount-path=/usr/local/nvidia/lib64,host-path=/var/lib/nvidia/lib64,mode=rw \
	--container-mount-host-path mount-path=/usr/local/nvidia/bin,host-path=/var/lib/nvidia/bin,mode=rw
	@echo "* GCP insecure container update complete"

start_gcp:
	gcloud compute instances start $(GCP_VM)

stop_gcp:
	@echo "* remove GCP known hosts file"
	rm ~/.ssh/google_compute_known_hosts || true
	@echo "* stop VM $(GCP_VM)"
	gcloud compute instances stop $(GCP_VM) || true

stop_previous_gcp:
	gcloud compute instances stop $(GCP_VM_PREVIOUS) || true

ssh_gcp:
	gcloud compute ssh $(GCP_VM)

ssh_container_gcp:
	gcloud compute ssh $(GCP_VM) --container $(GCP_CONTAINER)

ssh_jupyter_iap_tunnel:
	gcloud compute ssh $(GCP_VM) -- -L $(JUPYTER_PORT):localhost:$(JUPYTER_PORT)

# update_container_image: start_gcp wait
# 	gcloud compute ssh $(GCP_VM) \
# 	--command 'docker images && docker pull $(DOCKER_URL) && docker images'

update_container_image:
	gcloud compute ssh $(GCP_VM) \
	--command "docker pull $(DOCKER_URL)"

restart_container_1 restart_container_2:
	gcloud compute ssh $(GCP_VM) \
	--command 'docker restart $(GCP_CONTAINER)'

debug_container:
	gcloud compute instances update-container $(GCP_VM) \
	--container-command "/bin/sh" \
	--clear-container-args

attach_data_disk_gcp:
	gcloud compute instances attach-disk $(GCP_VM) --disk=$(DATA_DISK) --device-name=$(DATA_DISK) --mode=rw

detach_data_disk_gcp:
	gcloud compute instances detach-disk $(GCP_VM_PREVIOUS) --disk=$(DATA_DISK) || true

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

wait_running_container wait_running_container_2:
	@while [ "$$CONTAINER_IMAGE" != "$(DOCKER_IMAGE):$(DOCKER_TAG)" ]; do \
		echo "* waiting for container" ;\
		sleep 5 ;\
		CONTAINER_IMAGE=`gcloud compute ssh $(GCP_VM) --command "docker ps --filter 'status=running' --filter 'ancestor=$(DOCKER_IMAGE):$(DOCKER_TAG)' --format '{{.Image}}'"` ;\
	done ;\
	CONTAINER_ID=`gcloud compute ssh $(GCP_VM) --command "docker ps --filter 'status=running' --filter 'ancestor=$(DOCKER_IMAGE):$(DOCKER_TAG)' --format '{{.ID}}'"` ;\
	echo "* container $$CONTAINER_ID for image $$CONTAINER_IMAGE is now available"

install_nvidia_container:
	@if [ "$(PROCESSOR_MODE)" = "cpu" ]; then \
		echo "* skipping installation of NVIDIA drivers for cpu" ;\
	elif [ "$(PROCESSOR_MODE)" = "gpu" ]; then \
		echo "* installing CUDA for gpu to container: $(GCP_CONTAINER)" ;\
	    gcloud compute ssh $(GCP_VM) \
	    --command "docker exec -u 0 $(GCP_CONTAINER) sh -c '\
			    export LD_LIBRARY_PATH=/usr/local/nvidia/lib64 && \
			    pacman -Syu --needed --noconfirm cudnn'";\
		echo "* completed installation of CUDA for gpu to container: $(GCP_CONTAINER)" ;\
	else \
		echo "* check that you have specified a support PROCESSOR_MODE (gpu or cpu)";\
		echo "* PROCESSOR_MODE currently set to $(PROCESSOR_MODE)" ;\
	fi

check_nvidia:
	@if [ "$(PROCESSOR_MODE)" = "cpu" ]; then \
		echo "* skipping NVIDIA driver check for cpu" ;\
	elif [ "$(PROCESSOR_MODE)" = "gpu" ]; then \
		echo "* checking nvidia drivers" ;\
	    gcloud compute ssh $(GCP_VM) \
	    --command "docker exec -u 0 $(GCP_CONTAINER) sh -c 'LD_LIBRARY_PATH=/usr/local/nvidia/lib64 /usr/local/nvidia/bin/nvidia-smi'" ;\
	else \
		echo "* check that you have specified a support PROCESSOR_MODE (gpu or cpu)";\
		echo "* PROCESSOR_MODE currently set to $(PROCESSOR_MODE)" ;\
	fi

install_libraries_container:
	@if [ "$(PROCESSOR_MODE)" = "cpu" ]; then \
		echo "* installing/listing packages for cpu setup" ;\
	    gcloud compute ssh $(GCP_VM) \
	    --command "docker exec -u 0 $(GCP_CONTAINER) sh -c '\
				pip freeze'";\
	elif [ "$(PROCESSOR_MODE)" = "gpu" ]; then \
		echo "* installing/listing packages for gpu setup" ;\
	    gcloud compute ssh $(GCP_VM) \
	    --command "docker exec -u 0 $(GCP_CONTAINER) sh -c '\
				pip freeze'";\
	else \
		echo "* check that you have specified a support PROCESSOR_MODE (gpu or cpu)";\
		echo "* PROCESSOR_MODE currently set to $(PROCESSOR_MODE)" ;\
	fi

get_container_id:
	gcloud compute ssh $(GCP_VM) \
	--command "docker ps --filter 'status=running' --filter 'ancestor=$(DOCKER_IMAGE):$(DOCKER_TAG)' --format '{{.ID}}'"

container_logs_gcp:
	gcloud compute ssh $(GCP_VM) \
	--command "docker logs $(GCP_CONTAINER)"

get_vm_hostname:
	gcloud compute ssh $(GCP_VM) \
	--command "curl 'http://metadata.google.internal/computeMetadata/v1/instance/hostname' -H 'Metadata-Flavor: Google'"

ssl_cert_copy_to_gcp:
	gcloud compute scp --recurse etc/certs \
	$(USER_NAME)@$(GCP_VM):/tmp
	gcloud compute ssh $(GCP_VM) \
	--command "sudo cp -r /tmp/certs /mnt/disks/gce-containers-mounts/gce-persistent-disks/$(DATA_DISK)/$(USER_NAME) && \
               sudo rm -r /tmp/certs"
	@echo "* completed copying /etc/certs directory to $(DATA_DISK)/$(USER_NAME)/"

create_notebooks_dir_gcp:
	gcloud compute ssh $(GCP_VM) \
	--command "sudo install -d -m 0755 -o 1000 -g 100 /mnt/disks/gce-containers-mounts/gce-persistent-disks/$(DATA_DISK)/$(USER_NAME)/$(NOTEBOOKS_DIR)"
	@echo "* completed creation of NOTEBOOKS_DIR: $(DATA_DISK)/$(USER_NAME)/$(NOTEBOOKS_DIR)"

check_cf_env_set:
	@if [ -z "$$CF_API_KEY" ] || [ -z "$$CF_ZONE" ] || [ -z "$$CF_RECORD_ID" ] || [ -z "$$CF_EMAIL" ] || [ -z "$$CF_DOMAIN" ]; then \
		echo "* one or more variables required by scripts/cloudflare-update.sh are undefined";\
		exit 1;\
	else \
		echo "* cloudflare variables required by scripts/cloudflare-update.sh all defined";\
    fi

external_port_redirect_gcp:
	gcloud compute ssh $(GCP_VM) \
	--command 'sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport $(EXTERNAL_PORT) -j REDIRECT --to-port $(JUPYTER_PORT)'

update_ip_gcp_cf: check_cf_env_set
	scripts/cloudflare-update.sh $(GCP_IP) | json_pp

cos_versions_gcp:
	gcloud compute images list --project cos-cloud --no-standard-images

set_tags_gcp:
	gcloud compute instances remove-tags $(GCP_VM) --tags=http-server
	gcloud compute instances add-tags $(GCP_VM) --tags=https-server

wait wait_1 wait_2 wait_3:
	@echo "* pausing for 30 seconds"
	@sleep 30

#-----------------------#
# deprecated GCP
#-----------------------#

ssl_redirect_gcp:
	gcloud compute ssh $(GCP_VM) \
	--command 'sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8443'

setup_cpu_gcp: \
check_cf_env_set \
create_data_disk \
create_cpu_gcp \
wait_1 \
external_port_redirect_gcp update_ip_gcp_cf

setup_gpu_gcp: \
check_cf_env_set \
create_data_disk \
create_gpu_gcp \
wait_exist_vm wait_1 wait_running_container \
install_nvidia_container check_nvidia \
install_libraries_container \
external_port_redirect_gcp update_ip_gcp_cf \
restart_container_1

create_cpu_gcp:
	@if [ "$(CHECK_VM)" = "$(GCP_VM)" ]; then\
		echo "* $(GCP_VM) already exists; proceeding to start" ;\
		gcloud compute instances start $(GCP_VM) ;\
	else \
		echo "* $(GCP_VM) DOES NOT exist; proceeding with creation" ;\
	    gcloud compute instances create-with-container $(GCP_VM) \
		  --image-project=gce-uefi-images \
		  --image-family=$(COS_FAMILY) \
	    --container-image $(DOCKER_URL) \
	    --container-restart-policy on-failure \
	    --container-privileged \
	    --container-stdin \
	    --container-tty \
	    --container-mount-host-path mount-path=/home/jupyter,host-path=/home/jupyter,mode=rw \
	    --container-command "jupyter" \
	    --container-arg="lab" \
	    --container-arg="--ServerApp.port=$(JUPYTER_PORT)" \
	    --container-arg="--ServerApp.allow_origin=*" \
	    --container-arg="--ServerApp.ip=*" \
	    --container-arg="--ServerApp.certfile=/$(DATA_DISK)/$(USER_NAME)/certs/cert.pem" \
	    --container-arg="--ServerApp.keyfile=/$(DATA_DISK)/$(USER_NAME)/certs/key.pem" \
	    --container-arg="--ServerApp.root_dir=/$(DATA_DISK)/$(USER_NAME)/$(NOTEBOOKS_DIR)" \
		  --container-arg="--ServerApp.password=$(JUPYTER_PASSWORD)" \
	    --machine-type $(GCP_MACHINE_TYPE) \
	    --boot-disk-size $(BOOT_DISK_SIZE) \
	    --disk auto-delete=no,boot=no,device-name=$(DATA_DISK),mode=rw,name=$(DATA_DISK) \
	    --container-mount-disk mode=rw,mount-path=/$(DATA_DISK),name=$(DATA_DISK) \
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
		  --image-family=$(COS_FAMILY) \
	    --container-image $(DOCKER_URL) \
	    --container-restart-policy on-failure \
	    --container-privileged \
	    --container-stdin \
	    --container-tty \
	    --container-mount-host-path mount-path=/home/jupyter,host-path=/home/jupyter,mode=rw \
	    --container-command "jupyter" \
	    --container-arg="lab" \
	    --container-arg="--ServerApp.port=$(JUPYTER_PORT)" \
	    --container-arg="--ServerApp.allow_origin=*" \
	    --container-arg="--ServerApp.ip=*" \
	    --container-arg="--ServerApp.certfile=/$(DATA_DISK)/$(USER_NAME)/certs/cert.pem" \
	    --container-arg="--ServerApp.keyfile=/$(DATA_DISK)/$(USER_NAME)/certs/key.pem" \
	    --container-arg="--ServerApp.root_dir=/$(DATA_DISK)/$(USER_NAME)/$(NOTEBOOKS_DIR)" \
		  --container-arg="--ServerApp.password=$(JUPYTER_PASSWORD)" \
	    --machine-type $(GCP_MACHINE_TYPE) \
	    --boot-disk-size $(BOOT_DISK_SIZE) \
	    --disk auto-delete=no,boot=no,device-name=$(DATA_DISK),mode=rw,name=$(DATA_DISK) \
	    --container-mount-disk mode=rw,mount-path=/$(DATA_DISK),name=$(DATA_DISK) \
	    --tags=http-server,https-server \
	    --preemptible \
	    --accelerator count=$(GCP_ACCELERATOR_COUNT),type=$(GCP_ACCELERATOR_TYPE) \
	    --container-mount-host-path mount-path=/usr/local/nvidia/lib64,host-path=/var/lib/nvidia/lib64,mode=rw \
	    --container-mount-host-path mount-path=/usr/local/nvidia/bin,host-path=/var/lib/nvidia/bin,mode=rw \
	    --metadata-from-file startup-script=scripts/install-cos-gpu.sh ;\
	fi

#-----------------------#
# Make variable check
#-----------------------#
print_container:
	$(info    GCP_CONTAINER is $(GCP_CONTAINER))

print_make_vars:
	$(info    DOCKER_REGISTRY is $(DOCKER_REGISTRY))
	$(info    DOCKER_IMAGE is $(DOCKER_IMAGE))
	$(info    DOCKER_TAG is $(DOCKER_TAG))
	$(info    GIT_COMMIT is $(GIT_COMMIT))
	$(info    USER_NAME is $(USER_NAME))
	$(info    GCP_PROJECT is $(GCP_PROJECT))
	$(info    GCP_REGION is $(GCP_REGION))
	$(info    GCP_ZONE is $(GCP_ZONE))
	$(info    GCP_VM is $(GCP_VM))
	$(info    GCP_MACHINE_TYPE is $(GCP_MACHINE_TYPE))
	$(info    GCP_ACCELERATOR_TYPE is $(GCP_ACCELERATOR_TYPE))
	$(info    DATA_DISK is $(DATA_DISK))
	$(info    CHECK_DATA_DISK is $(CHECK_DATA_DISK))
	$(info    JUPYTER_PORT is $(JUPYTER_PORT))
	$(info    EXTERNAL_PORT is $(EXTERNAL_PORT))
	$(info    CHECK_VM is $(CHECK_VM))
	$(info    GCP_IP is $(GCP_IP))
	$(info    GCP_VM_PREVIOUS is $(GCP_VM_PREVIOUS))
	$(info    GCP_CONTAINER is $(GCP_CONTAINER))


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

# 		--container-arg="--ResourceUseDisplay.track_cpu_percent=True" \#
# 		--container-arg="--ResourceUseDisplay.mem_limit=$$(( $(MEM_LIMIT) *1024*1024*1024 ))" \#
# 		--container-arg="--ResourceUseDisplay.cpu_limit=$$(( $(CPU_LIMIT) ))" \#

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
