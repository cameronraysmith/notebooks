.PHONY=build srv restart sh clean kill docker_push docker_build build_output create_gcp update_gcp start_gcp stop_gcp ssh_gcp ssh_container_gcp ssl_to_gcp ssl_redirect_gcp

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

create_gcp:
	gcloud compute instances create-with-container $(GCP_VM) \
    --container-image registry.hub.docker.com/$(DOCKER_IMAGE):latest \
    --container-restart-policy on-failure \
    --container-privileged \
    --container-stdin \
    --container-tty \
    --container-mount-host-path mount-path=/home/jupyter,host-path=/tmp,mode=rw \
	--container-command "jupyter" \
	--container-arg="lab" \
	--container-arg="--ip=0.0.0.0" \
	--container-arg="--port=8443" \
	--container-arg="--NotebookApp.ResourceUseDisplay.mem_limit=4026531840" \
	--container-arg="--NotebookApp.ResourceUseDisplay.track_cpu_percent=True" \
	--container-arg="--NotebookApp.ResourceUseDisplay.cpu_limit=1" \
	--container-arg="--NotebookApp.allow_origin='*'" \
	--container-arg="--NotebookApp.ip='*'" \
    --container-arg="--NotebookApp.password=<type:salt:hashed-password>" \
    --machine-type n1-standard-1 \
    --boot-disk-size 50GB \
	--disk name=data,mode=rw \
    --preemptible

update_gcp:
	gcloud compute instances update-container $(GCP_VM) \
	--container-mount-disk name=data,mount-path=/data \
	--container-command "jupyter" \
	--container-arg="lab" \
	--container-arg="--ip=0.0.0.0" \
	--container-arg="--port=8443" \
	--container-arg="--NotebookApp.allow_origin='*'" \
	--container-arg="--NotebookApp.ip='*'" \
    --container-arg="--NotebookApp.password=<type:salt:hashed-password>" \
	--container-arg="--NotebookApp.certfile='/data/jovyan/certs/cf-cert.pem'" \
	--container-arg="--NotebookApp.keyfile='/data/jovyan/certs/cf-key.pem'" \
	--container-arg="--NotebookApp.notebook_dir='/data/jovyan/projects'"

start_gcp:
	gcloud compute instances start $(GCP_VM)

stop_gcp:
	gcloud compute instances stop $(GCP_VM)

ssh_gcp:
	gcloud compute ssh $(GCP_VM)

ssh_container_gcp:
	gcloud compute ssh $(GCP_VM) --container $(GCP_CONTAINER)

ssl_to_gcp:
	gcloud compute scp --recurse etc/certs \
           jovyan@$(GCP_VM):/mnt/disks/gce-containers-mounts/gce-persistent-disks/data/jovyan

ssl_redirect_gcp:
	gcloud compute ssh jovyan@$(GCP_VM) \
		   --command 'sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8443'

#-----------------------#

# Image can be overidden with an env var.
DOCKER_IMAGE ?= cameronraysmith/notebooks

# Get the latest commit.
GIT_COMMIT = $(strip $(shell git rev-parse --short HEAD))

# Get the version number from the code
CODE_VERSION = $(strip $(shell cat VERSION))

ifndef CODE_VERSION
$(error You need to create a VERSION file to build a release)
endif

# Find out if the working directory is clean
GIT_NOT_CLEAN_CHECK = $(shell git status --porcelain)
ifneq (x$(GIT_NOT_CLEAN_CHECK), x)
DOCKER_TAG_SUFFIX = -dirty
endif

# Add the commit sha and mark as dirty if the working directory isn't clean
ifeq ($(TYPE),dev)
	DOCKER_TAG = $(CODE_VERSION)-dev
else
	DOCKER_TAG = $(CODE_VERSION)-$(GIT_COMMIT)$(DOCKER_TAG_SUFFIX)
endif

GCP_VM = notebooks-vm
GCP_CONTAINER = klt-notebooks-vm-cjme
