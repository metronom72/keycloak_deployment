#!/bin/sh
set -e

exec /opt/keycloak/bin/kc.sh start \
  --optimized \
  --proxy-headers=xforwarded \
 # --cache-metrics-histograms-enabled=true \
 # --http-metrics-histograms-enabled=true \
  --http-metrics-slos=true \
  "$@"
