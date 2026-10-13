# The "server" Kamal deploys to — a stand-in for the EC2 instance.
#
# Kamal needs exactly two things from a host: SSH, and a working `docker`
# command. On real AWS that's an aws_instance in the public subnet of
# ../terraform. On the laptop it's this container: sshd plus the Docker CLI,
# driving the laptop's own Docker daemon through the mounted socket.
#
# Why not the Floci EC2 instance that stack 3's Terraform creates? Docker does run
# inside it, but only after starting dockerd by hand with the vfs storage driver
# (docs/FINDINGS.md). Until that path is tested end to end, Kamal deploys here.

FROM docker:29-cli

RUN apk add --no-cache openssh-server \
 && mkdir -p /root/.ssh /etc/ssh/keys \
 && chmod 700 /root/.ssh

COPY sshd_config /etc/ssh/sshd_config
COPY entrypoint.sh /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
