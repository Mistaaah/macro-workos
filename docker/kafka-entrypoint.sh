#!/bin/bash
set -eu

# Railway mounts new volumes as root-owned directories. Give Kafka's image user
# access to its persistent log directory before dropping privileges.
data_dir=/var/lib/kafka/data
kafka_data_dir="$data_dir/kafka"
mkdir -p "$kafka_data_dir"

# ext4 volumes contain a reserved lost+found directory at their mount root,
# which Kafka rejects if the volume root itself is used as a log directory.
# Relocate existing broker files into a child directory without deleting data.
shopt -s dotglob nullglob
for path in "$data_dir"/*; do
  case "$path" in
    "$data_dir/lost+found"|"$kafka_data_dir") continue ;;
  esac
  mv -n -- "$path" "$kafka_data_dir/"
done

chown -R appuser:root "$data_dir"

exec su-exec appuser:appuser "$@"
