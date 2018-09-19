SHELL=/bin/bash
IMAGE=10.254.0.50:5000/hbase:1.2.6.1

build:
	@docker build -t ${IMAGE} .
