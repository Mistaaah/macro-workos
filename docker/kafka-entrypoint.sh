#!/bin/bash
set -eu

# Railway mounts new volumes as root-owned directories. Give Kafka's image user
# access to its persistent log directory before dropping privileges.
mkdir -p /var/lib/kafka/data
chown -R appuser:root /var/lib/kafka/data

exec su-exec appuser:appuser "$@"
