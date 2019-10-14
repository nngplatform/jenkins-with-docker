This image adds two features to the official Jenkins LTS (jenkins/jenkins:lts) release:

* contains the "docker-ce" package so Jenkins jobs can start Docker containers
* has a wrapper shell script (wraps the one in the official Jenkins image) to manage the group permissions of the "jenkins" user of the container so it can write to the docker socket (that you bind mount from the host to the container)

See the "description" label of the image for details on how to use this image.
