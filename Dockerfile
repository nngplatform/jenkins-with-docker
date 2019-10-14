FROM jenkins/jenkins:lts

# The parent image already contains the Jenkins version in JENKINS_VERSION env variable, which is part of the Docker image.
# But image env variables cannot be queried by name, so it's better to store the version as a label too.
LABEL jenkins_version="$JENKINS_VERSION"
LABEL description="This image extends the official jenkins/jenkins:lts image by adding the docker-ce package so Jenkins can launch Docker containers. \
You have to bind mount the Docker socket, when you run the Jenkins container. \
Eg. \"-v /var/run/docker.sock:/var/run/docker.sock\" \
Furthermore you can/should specify the group ID (via the DOCKER_GID environment variable) that has write permission on the Docker socket on the host. \
Eg. \"-e DOCKER_GID=$(getent group docker | cut -d: -f3)\" \
This can be different from the group ID of the \"docker\" group that is created during the build of the image (by the docker-ce package)."

USER root

RUN true \
  # install prerequisites for Docker
  && apt-get update \
  && apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
  && OS_CODENAME="$(sed -r 's/^ID=(.*)/\1/;t;d' /etc/os-release)" \
  && VERSION_CODENAME="$(sed -r 's/^VERSION_CODENAME=(.*)/\1/;t;d' /etc/os-release)" \
  # Add Docker repository
  && curl -fsSL "https://download.docker.com/linux/$OS_CODENAME/gpg" | apt-key add - \
  && echo "deb [arch=amd64] https://download.docker.com/linux/$OS_CODENAME $VERSION_CODENAME stable" > /etc/apt/sources.list.d/download_docker_com.list \
  && apt-get update \
  # Install Docker and stuff
  && apt-get -y install \
    docker-ce \
    setpriv \
  # We keep what we installed for getting Docker into the image, because they are useful.
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY jenkins-setpriv-wrapper.sh /usr/local/bin/jenkins-setpriv-wrapper.sh

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins-setpriv-wrapper.sh"]
