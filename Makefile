# Usage
# make help 			# returns the list of targets
# make unit-tests		# runs unit-tests, does nothing here as they do not exist, but it should create a coverage file and send it to code-scanners
# make build			# builds the image and tags it with the commit sha if no tag was pushed, if a tag was pushed, tag it as latest and the tag too
# make push				# push all tags of the image relevant to this repository

help:
	@grep '^[^#[:space:]].+:' Makefile

unit-tests:
	@echo "Test target has been called, but as there are no tests, nothing was done"

build:
	@echo "Building image"
	@docker build . -t ${DOCKER_REGISTRY}/${IMAGE_NAME}:${COMMIT_SHA}
	@echo "Built image"
ifdef GIT_TAG
	@docker tag ${DOCKER_REGISTRY}/${IMAGE_NAME}:${COMMIT_SHA} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
	@docker tag ${DOCKER_REGISTRY}/${IMAGE_NAME}:${COMMIT_SHA} ${DOCKER_REGISTRY}/${IMAGE_NAME}:${GIT_TAG}
	@echo "tagged image as ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
	@echo "tagged image as ${DOCKER_REGISTRY}/${IMAGE_NAME}:${GIT_TAG}"
endif

push:
	@echo "Pushing image"
	@docker push ${DOCKER_REGISTRY}/${IMAGE_NAME} -a
	@echo "Pushed image"