# echogrpc

You will find in this repository a grpc client and server.


# Docker image

## Registries

- https://hub.docker.com/r/nvogel/echogrpc/tags
- https://quay.io/repository/nvgl/echogrpc?tab=tags

# Travis

```
docker run --rm -ti -v "$PWD":/usr/src/myapp ruby:2.5 /bin/bash
# Install travis
gem install travis
cd /usr/src/myapp
# DockerHub
travis encrypt DOCKER_HUB_PASSWORD='CHANGEME' --add
# Quay
travis encrypt DOCKER_PASSWORD='CHANGEME' --add
```
