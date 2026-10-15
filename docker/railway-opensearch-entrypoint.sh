#!/usr/bin/env bash
set -euo pipefail

mkdir -p /usr/share/opensearch/data
chown -R 1000:1000 /usr/share/opensearch/data

opensearch_args=("$@")

if [[ -n "${OPENSEARCH_HTTP_CERT_B64:-}" || -n "${OPENSEARCH_HTTP_KEY_B64:-}" ]]; then
  if [[ -z "${OPENSEARCH_HTTP_CERT_B64:-}" || -z "${OPENSEARCH_HTTP_KEY_B64:-}" ]]; then
    echo "Both OPENSEARCH_HTTP_CERT_B64 and OPENSEARCH_HTTP_KEY_B64 must be set" >&2
    exit 1
  fi

  cert_dir=/usr/share/opensearch/config/railway-http-certs
  mkdir -p "$cert_dir"
  printf '%s' "$OPENSEARCH_HTTP_CERT_B64" | base64 --decode > "$cert_dir/server.pem"
  printf '%s' "$OPENSEARCH_HTTP_KEY_B64" | base64 --decode > "$cert_dir/server-key.pem"
  chown -R 1000:1000 "$cert_dir"
  chmod 644 "$cert_dir/server.pem"
  chmod 600 "$cert_dir/server-key.pem"

  opensearch_args+=(
    -Eplugins.security.ssl.http.pemcert_filepath=railway-http-certs/server.pem
    -Eplugins.security.ssl.http.pemkey_filepath=railway-http-certs/server-key.pem
  )
fi

exec runuser -u opensearch -- /usr/share/opensearch/opensearch-docker-entrypoint.sh "${opensearch_args[@]}"
