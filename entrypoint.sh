#!/bin/sh
set -e

chown kat:kat /home/kat
chmod 750 /home/kat

mkdir -p /home/kat/.ssh
chmod 700 /home/kat/.ssh

if [ -n "$SSH_PUBKEY" ]; then
    printf '%s\n' "$SSH_PUBKEY" > /home/kat/.ssh/authorized_keys
    chmod 600 /home/kat/.ssh/authorized_keys
fi

chown -R kat:kat /home/kat/.ssh

exec /usr/sbin/sshd -D -e
