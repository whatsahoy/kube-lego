#!/bin/sh

DOCKER_IMAGE=$1
if [ -z "${DOCKER_IMAGE}" ]; then
	echo "Usage: $0 docker-name[:build-tag] version-tag [version-tag...]" >&2
	exit 1
fi

shift

if [ $# -eq 0 ]; then
	echo "Usage: $0 docker-name[:build-tag] version-tag [version-tag...]" >&2
	exit 1
fi

DOCKER_NAME=`echo ${DOCKER_IMAGE} | cut -f 1 -d :`
for v in $*; do
	echo "Tagging ${DOCKER_IMAGE} as ${DOCKER_NAME}:$v"
	docker tag ${DOCKER_IMAGE} ${DOCKER_NAME}:$v

	echo "Pushing: ${DOCKER_NAME}:$v"
	docker push ${DOCKER_NAME}:$v
	if [ $? -ne 0 ]; then
		echo "Cannot push image ${DOCKER_NAME}:$v, aborting"
		exit 1
	fi

	_safeDockerName=`echo ${DOCKER_NAME} | sed 's,/,%2f,g'`
	_branches=`curl -sfX PUT -H "authorization: Bearer ${DEPLOYER_TOKEN}" https://deployer.internal.collaborne.com/api/repositories/${_safeDockerName}/images/$v`
	if [ $? -ne 0 ]; then
		echo "Cannot register image ${DOCKER_NAME}:$v with the deployer, image will not be automatically deployed"
	else
		echo "Triggered build for branches: `echo ${_branches} | jq -r '.branches[]' | xargs echo`"
	fi
done
