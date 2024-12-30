FROM quay.io/keycloak/keycloak:26.0.6 as builder

WORKDIR /opt/keycloak

RUN /opt/keycloak/bin/kc.sh build \
     --health-enabled true \
     --metrics-enabled true \
     --db postgres \
     --features preview \
     --metrics-enabled=true

FROM quay.io/keycloak/keycloak:26.0.6

USER root

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

USER keycloak

COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/docker-entrypoint.sh"]
