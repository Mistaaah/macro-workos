#!/bin/sh
set -eu

# LocalStack runs this from inside its own container after the AWS APIs are
# ready, so the existing xtask provisions the same resources as a local stack.
exec /usr/local/bin/xtask_local localstack-provision
