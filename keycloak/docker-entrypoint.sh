#!/bin/sh
set -e

exec /opt/keycloak/bin/kc.sh start \
  --optimized \
  --verbose \
  --proxy-headers=xforwarded \
  --hostname=$KEYCLOAK_HOSTNAME \
#  --cache-metrics-histograms-enabled=true \
#  --http-metrics-histograms-enabled=true \
  --http-metrics-slos=true \
  "$@"
