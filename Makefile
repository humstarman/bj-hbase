SHELL=/bin/bash
IMAGE_NAME=hbase:1.2.7
IMAGE=10.254.0.50:5000/hbase:1.2.7
MANIFEST=./manifest

all: deploy

build:
	@docker build -t ${IMAGE} .

retag: HOST_IP=192.168.100.167
retag: SRC_IMAGE=${HOST_IP}:5000/${IMAGE_NAME} 
retag:
	@docker pull ${SRC_IMAGE}
	@docker tag ${SRC_IMAGE} ${IMAGE}

push:
	@docker push ${IMAGE}

deploy: OP=create
deploy:
	@kubectl ${OP} ${MANIFEST}/.
