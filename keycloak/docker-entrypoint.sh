#!/bin/sh
set -e

echo "----------$(date '+%Y-%m-%d %H:%M:%S')----------"
echo ls -al /opt/keycloak
ls -al /opt/keycloak
echo "========================================"
echo "----------$(date '+%Y-%m-%d %H:%M:%S')----------"
echo ls -al /opt/keycloak/conf
ls -al /opt/keycloak/conf
echo "========================================"
echo "----------$(date '+%Y-%m-%d %H:%M:%S')----------"
echo cat /opt/keycloak/conf/keycloak.conf
cat /opt/keycloak/conf/keycloak.conf
echo "========================================"
echo "----------$(date '+%Y-%m-%d %H:%M:%S')----------"
echo ls -al /opt/keycloak/conf/cache-ispn-jdbc-ping.xml
ls -al /opt/keycloak/conf/cache-ispn-jdbc-ping.xml
echo "========================================"
echo "----------$(date '+%Y-%m-%d %H:%M:%S')----------"
echo cat /opt/keycloak/conf/cache-ispn-jdbc-ping.xml
cat /opt/keycloak/conf/cache-ispn-jdbc-ping.xml
echo "========================================"

exec /opt/keycloak/bin/kc.sh start \
  --optimized \
  --verbose \
  --proxy-headers=xforwarded \
  --hostname=$KEYCLOAK_HOSTNAME \
#  --cache-metrics-histograms-enabled=true \
#  --http-metrics-histograms-enabled=true \
  --http-metrics-slos=true \
  "$@"
