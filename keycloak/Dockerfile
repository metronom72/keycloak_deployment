FROM registry.access.redhat.com/ubi9:latest as driver

RUN dnf -y update --allowerasing && \
    dnf -y install --allowerasing curl && \
    dnf clean all

# Now install what you need, e.g.:
RUN curl -L -o /tmp/postgresql.jar \
    https://jdbc.postgresql.org/download/postgresql-42.6.0.jar

FROM quay.io/keycloak/keycloak:24.0.1 AS builder

ARG KC_DB
ARG KC_DB_URL
ARG KC_DB_USERNAME
ARG KC_DB_PASSWORD
ARG KC_FEATURES
ARG KC_HEALTH_ENABLED
ARG KC_METRICS_ENABLED
ARG KC_CACHE_CONFIG_FILE

ENV KC_DB=$KC_DB
ENV KC_DB_URL=$KC_DB_URL
ENV KC_DB_USERNAME=$KC_DB_USERNAME
ENV KC_DB_PASSWORD=$KC_DB_PASSWORD
ENV KC_FEATURES=$KC_FEATURES
ENV KC_HEALTH_ENABLED=$KC_HEALTH_ENABLED
ENV KC_METRICS_ENABLED=$KC_METRICS_ENABLED
ENV KC_CACHE_CONFIG_FILE=$KC_CACHE_CONFIG_FILE

USER root

# Copy the Postgres driver from the 'driver' stage into /opt/keycloak/providers
COPY --from=driver /tmp/postgresql.jar /opt/keycloak/providers/

# Copy your custom Infinispan cache config & custom themes
COPY cache-ispn-jdbc-ping.xml /opt/keycloak/conf/cache-ispn-jdbc-ping.xml
COPY themes/ /opt/keycloak/themes

# Switch back to keycloak user before building
USER keycloak

# Build an optimized Quarkus distribution that includes the driver & configs
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:24.0.1

USER root

# Copy the fully built Keycloak from the builder stage
COPY --from=builder /opt/keycloak /opt/keycloak

# If you have a custom entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Generate a self-signed keystore for HTTPS (optional)
RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 \
    -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" \
    -keystore /opt/keycloak/conf/server.keystore

# Runtime environment variables
ENV KC_SPI_CONNECTIONS_JDBC_DRIVER_POSTGRESQL=org.postgresql.Driver
ENV FORMAT_MESSAGES_PATTERN_DISABLE_LOOKUPS=true

# Switch back to keycloak user for running the server
USER keycloak

# Default port for JDBC_PING

ENTRYPOINT ["/docker-entrypoint.sh"]
