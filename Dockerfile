FROM envoyproxy/envoy-alpine:v1.5.0

LABEL DEPLOYMENT_TYPE=SIDECAR
ADD scripts/ /hydro-serving
CMD ["/hydro-serving/start.sh"]