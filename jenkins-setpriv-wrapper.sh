#!/bin/bash -e

[ ! -d "$JENKINS_HOME" ] && echo "The JENKINS_HOME environment variable does not point to an existing directory. Aborting." >&2 && exit 1

# We build on the fact that the parent image chowns this directory to the user Jenkins will run with.
# There's no other way to determine the Jenkins OS user (since it can be changed during image build time).
JENKINS_UID="$(stat -c "%u" "$JENKINS_HOME")"

# The ID of the group (on the host!) that Docker Engine gave permission to for the socket file.
DOCKER_GID="${DOCKER_GID:-$(getent group docker 2> /dev/null | cut -d: -f3)}"

if ! echo "$DOCKER_GID" | egrep -qs "^[0-9]+\$" > /dev/null 2>&1; then
  echo "DOCKER_GID is not a number ($DOCKER_GID)." >&2
  exit 2
fi

# Create a group for the specified GID if none exists yet.
if ! getent group "$DOCKER_GID" > /dev/null 2>&1; then
  addgroup --gid "$DOCKER_GID" docker_on_host
fi

# Add Jenkins to this new Docker group.
usermod -aG "$DOCKER_GID" jenkins

# Setting the HOME since setpriv doesn't care for environment variables.
export HOME="$JENKINS_HOME"

# Set UID + primary GID + supplementary GIDs and exec the wrapper shellscript from the parent image.
exec setpriv --reuid=$JENKINS_UID --regid=$(id -g "$JENKINS_UID") --groups=$(id -G "$JENKINS_UID" | sed -r "s/([0-9])[[:space:]]+([0-9])/\\1,\\2/g") --inh-caps=-all --no-new-privs /usr/local/bin/jenkins.sh "$@"
