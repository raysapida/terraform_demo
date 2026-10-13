#!/bin/sh
set -eu

# Generate the host key once; the volume keeps it across container rebuilds.
[ -f /etc/ssh/keys/ssh_host_ed25519_key ] || ssh-keygen -q -t ed25519 -N "" -f /etc/ssh/keys/ssh_host_ed25519_key

# authorized_keys is mounted read-only from the host; sshd wants strict modes.
install -m 600 /tmp/authorized_keys /root/.ssh/authorized_keys

exec /usr/sbin/sshd -D -e
