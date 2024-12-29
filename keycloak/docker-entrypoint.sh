#!/bin/sh
set -e

# ECS 1.3
if [ -n "${ECS_CONTAINER_METADATA_URI}" ]; then
  EXTERNAL_ADDR=$(curl -fs "${ECS_CONTAINER_METADATA_URI}" | jq -r '.Networks[0].IPv4Addresses[0]')
fi

# ECS 1.4
if [ -n "${ECS_CONTAINER_METADATA_URI_V4}" ]; then
  EXTERNAL_ADDR=$(curl -fs "${ECS_CONTAINER_METADATA_URI_V4}" | jq -r '.Networks[0].IPv4Addresses[0]')
fi

if [ -z "${EXTERNAL_ADDR}" ]; then
  EXTERNAL_ADDR=127.0.0.1
fi
export EXTERNAL_ADDR

##############################################
# Default hostname + disable strict resolution
##############################################
# If KC_HOSTNAME is not set, default to localhost
: "${KC_HOSTNAME:=localhost}"
export KC_HOSTNAME

# Disable strict host checking if not explicitly set
: "${KC_HOSTNAME_STRICT:=false}"
export KC_HOSTNAME_STRICT

: "${KC_HOSTNAME_STRICT_HTTPS:=false}"
export KC_HOSTNAME_STRICT_HTTPS

# Start Keycloak in production mode with these settings
exec /opt/keycloak/bin/kc.sh start \
  --optimized \
  --hostname="${KC_HOSTNAME}" \
  --hostname-strict="${KC_HOSTNAME_STRICT}" \
  --hostname-strict-https="${KC_HOSTNAME_STRICT_HTTPS}" \
  --proxy-headers=xforwarded \
  "$@"

exit $?
