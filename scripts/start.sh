#!/bin/sh

[ -z "$SIDECAR_LOG_LEVEL" ] && SIDECAR_LOG_LEVEL="info"

[ -z "$MANAGER_HOST" ] && MANAGER_HOST="manager"
[ -z "$MANAGER_PORT" ] && MANAGER_PORT="8080"

[ -z "$TRACING_ENABLED" ] && TRACING_ENABLED="false"
[ -z "$TRACING_HOST" ] && TRACING_HOST="zipkin"
[ -z "$TRACING_PORT" ] && TRACING_PORT="9411"
[ -z "$TRACING_ENDPOINT" ] && TRACING_ENDPOINT="/api/v1/spans"

[ -z "$CURRENT_ENVIRONMENT" ] && CURRENT_ENVIRONMENT="local"

[ -z "$ENVIRONMENT_NAME" ] && ENVIRONMENT_NAME="_"
[ -z "$MODEL" ] && MODEL="_"
[ -z "$MODEL_VERSION" ] && MODEL_VERSION="_"
[ -z "$RUNTIME" ] && RUNTIME="_"
[ -z "$RUNTIME_VERSION" ] && RUNTIME_VERSION="_"
[ -z "$SERVICE_ID" ] && SERVICE_ID="0"
[ -z "$SERVICE_NAME" ] && SERVICE_NAME="_"
[ -z "$SERVICE_PROVIDER_ID" ] && SERVICE_PROVIDER_ID="_"

[ -z "$CLUSTER_NAME" ] && CLUSTER_NAME="_"

[ -z "$CONTAINER_ID" ] && CONTAINER_ID=$(cat /proc/self/cgroup | grep docker | grep -o -E '[0-9a-f]{64}' | head -n 1)

if [ "$CURRENT_ENVIRONMENT" == "ecs" ]; then
  HOST_INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
  HOST_PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
  LOCALITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
  LOCALITY_REGION=$(echo $LOCALITY_ZONE | sed 's/[a-z]$//')
  LOCALITY_SUB_ZONE=$(echo $LOCALITY_ZONE | sed "s/$LOCALITY_REGION//")
fi

[ -z "$LOCALITY_SUB_ZONE" ] && LOCALITY_SUB_ZONE="_"
[ -z "$LOCALITY_ZONE" ] && LOCALITY_ZONE="_"
[ -z "$HOST_INSTANCE_ID" ] && HOST_INSTANCE_ID="_"
[ -z "$HOST_PRIVATE_IP" ] && HOST_PRIVATE_IP="_"
[ -z "$LOCALITY_REGION" ] && LOCALITY_REGION="_"


CONFIG_FILE="/hydro-serving/envoy.json"

cat <<EOF > $CONFIG_FILE
{
  "admin": {
    "access_log_path": "/dev/stdout",
    "address": {
        "socket_address":{
            "address":"0.0.0.0",
            "port_value":8082
        }
    }
  },
  "dynamic_resources": {
    "lds_config": {
        "ads": {}
    },
    "cds_config": {
        "ads": {}
    },
    "ads_config": {
        "api_type": "GRPC",
        "cluster_names": [
            "manager_xds_cluster"
        ]
    }
  },
  "stats_config":{
    "stats_tags":[
    ],
    "use_all_default_tags":true
  },
  "node":{
    "id":"$SERVICE_NAME",
    "cluster":"$CLUSTER_NAME",
    "metadata":{
        "containerId":"$CONTAINER_ID",
        "model":"$MODEL",
        "modelVersion":"$MODEL_VERSION",
        "runtime":"$RUNTIME",
        "runtimeVersion":"$RUNTIME_VERSION",
        "environment":"$ENVIRONMENT_NAME",
        "serviceId":"$SERVICE_ID",
        "serviceProviderId":"$SERVICE_PROVIDER_ID",
        "hostInstanceId":"$HOST_INSTANCE_ID",
        "hostPrivateIp":"$HOST_PRIVATE_IP"
    },
    "locality":{
        "region":"$LOCALITY_REGION",
        "zone":"$LOCALITY_ZONE",
        "sub_zone":"$LOCALITY_SUB_ZONE"
    }
  },
EOF

if [ "$TRACING_ENABLED" == "true" ]; then
cat <<EOF >> $CONFIG_FILE
  "tracing": {
    "http": {
      "name":"envoy.zipkin",
      "config": {
        "collector_cluster": "manager_tracing",
        "collector_endpoint": "$TRACING_ENDPOINT"
      }
    }
  },
EOF
fi

cat <<EOF >> $CONFIG_FILE
  "static_resources":{
    "clusters":[
    {
        "name":"manager_xds_cluster",
        "connect_timeout":"0.5s",
        "type":"STRICT_DNS",
        "http2_protocol_options": {},
        "hosts": [{ "socket_address": {
            "address": "$MANAGER_HOST",
            "port_value": $MANAGER_PORT
        }}]
    }
EOF

if [ "$TRACING_ENABLED" == "true" ]; then
cat <<EOF >> $CONFIG_FILE
    ,{
        "name":"manager_tracing",
        "connect_timeout":"0.5s",
        "type":"STRICT_DNS",
        "hosts": [{ "socket_address": {
            "address": "$TRACING_HOST",
            "port_value": $TRACING_PORT
        }}]
    }
EOF
fi

cat <<EOF >> $CONFIG_FILE
    ]
  }
}
EOF

echo "Configuration file generated"
cat $CONFIG_FILE

exec envoy -c $CONFIG_FILE --v2-config-only --max-obj-name-len 160 -l $SIDECAR_LOG_LEVEL