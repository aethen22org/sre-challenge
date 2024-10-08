# Usage
# make help 			# returns the list of targets
# make unit-tests		# runs unit-tests, does nothing here as they do not exist, but it should create a coverage file and send it to code-scanners
# make build			# builds the image and tags it with the commit sha if no tag was pushed, if a tag was pushed, tag it the tag
# make push				# push all tags of the image relevant to this repository
# make build-chart		# runs build target, push target and packages the helm chart and pushes it

help:
	@grep '^[^#[:space:]].+:' Makefile

unit-tests:
	@echo "Test target has been called, but as there are no tests, nothing was done"

build:
	@echo "Pulling original image"
	@docker pull ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
	@echo "Pulled image"
	@echo "Building image"
	@docker build . --build-arg BUILDKIT_INLINE_CACHE=1 --cache-from ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest -t ${DOCKER_REGISTRY}/${IMAGE_NAME}:${COMMIT_SHA}
	@echo "Built image"
ifdef GIT_TAG
	@docker tag ${DOCKER_REGISTRY}/${IMAGE_NAME}:${COMMIT_SHA} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
	@docker tag ${DOCKER_REGISTRY}/${IMAGE_NAME}:${COMMIT_SHA} ${DOCKER_REGISTRY}/${IMAGE_NAME}:${GIT_TAG}
	@echo "tagged image as ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
	@echo "tagged image as ${DOCKER_REGISTRY}/${IMAGE_NAME}:${GIT_TAG}"
	${MAKE} push
endif

push:
	@echo "Pushing image"
	@docker push ${DOCKER_REGISTRY}/${IMAGE_NAME} -a
	@echo "Pushed image"

build-chart:
	$(MAKE) build
	@echo "Creating and pushing helm chart ${IMAGE_NAME}-${GIT_TAG}"
	cd ops/charts/sre-challenge && helm dependency update && helm package . --version ${GIT_TAG} && curl --data-binary "@${IMAGE_NAME}-${GIT_TAG}.tgz" http://helm-registry.helm-registry.svc.cluster.local:8080/api/charts
	@echo "Pushed helm chart ${IMAGE_NAME}-${GIT_TAG}"