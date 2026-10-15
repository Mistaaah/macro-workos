#!/usr/bin/env bash
set -euo pipefail

mkdir -p /usr/share/opensearch/data
chown -R 1000:1000 /usr/share/opensearch/data

exec runuser -u opensearch -- /usr/share/opensearch/opensearch-docker-entrypoint.sh "$@"
