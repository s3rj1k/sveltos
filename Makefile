TAG ?= v0.21.0 

generate-manifest:
	scripts/generate_manifest.sh ${TAG}

upload-docker-images:
	scripts/upload_docker_images.sh ${TAG} ${DOCKER_CONFIG}
