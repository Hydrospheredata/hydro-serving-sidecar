FROM envoyproxy/envoy-alpine:v1.5.0

LABEL DEPLOYMENT_TYPE=SIDECAR
ADD scripts/ /hydro-serving
RUN apk add --no-cache curl
CMD ["/hydro-serving/start.sh"]