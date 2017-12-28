FROM envoyproxy/envoy-alpine:v1.5.0
ADD scripts/ /hydro-serving
CMD ["/hydro-serving/start.sh"]