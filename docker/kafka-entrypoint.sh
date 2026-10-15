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

# Start Kafka before provisioning the declared Macro event topics. The topic
# list is generated from macro_event_topics, the same source used by MSK.
bootstrap_server="${RAILWAY_PRIVATE_DOMAIN:-localhost}:29092"
su-exec appuser:appuser "$@" &
broker_pid=$!

cleanup() {
  kill "$broker_pid" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

ready=false
for attempt in {1..60}; do
  if ! kill -0 "$broker_pid" 2>/dev/null; then
    wait "$broker_pid"
    exit 1
  fi
  if su-exec appuser:appuser /opt/kafka/bin/kafka-topics.sh \
    --bootstrap-server "$bootstrap_server" --list >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 2
done

if [ "$ready" != true ]; then
  echo "Kafka did not become ready for topic provisioning" >&2
  exit 1
fi

while IFS= read -r topic; do
  [ -n "$topic" ] || continue
  su-exec appuser:appuser /opt/kafka/bin/kafka-topics.sh \
    --bootstrap-server "$bootstrap_server" \
    --create --if-not-exists \
    --topic "$topic" --partitions 6 --replication-factor 1
done < <(grep -oE '"[^"]+"' /usr/local/share/macro-kafka-topics.json | tr -d '"')

wait "$broker_pid"
