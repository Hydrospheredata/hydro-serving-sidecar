#!/bin/sh

[ -z "$MANAGER_HOST" ] && MANAGER_HOST="manager"
[ -z "$MANAGER_PORT" ] && MANAGER_PORT="8080"


[ -z "$TRACING_ENABLED" ] && TRACING_ENABLED="true"
[ -z "$TRACING_HOST" ] && TRACING_HOST="zipkin"
[ -z "$TRACING_PORT" ] && TRACING_PORT="9411"
[ -z "$TRACING_ENDPOINT" ] && TRACING_ENDPOINT="/api/v1/spans"

[ -z "$CURRENT_ENVIRONMENT" ] && CURRENT_ENVIRONMENT="local"

[ -z "$CONTAINER_ID" ] && CONTAINER_ID=$(cat /proc/self/cgroup | grep docker | grep -o -E '[0-9a-f]{64}' | head -n 1)



CONFIG_FILE="/hydro-serving/envoy.json"

cat <<EOF >> $CONFIG_FILE
{
  "admin": {
    "access_log_path": "/dev/stdout",
    "address": {
        "socket_address":{
            "address":"0.0.0.0",
            "port_value":8081
        }
    }
  },
  "dynamic_resources":{
    "lds_config":{"ads": {}},
    "cds_config":{"ads": {}},
    "ads_config":{
      "api_type":"GRPC",
      "cluster_name":["manager_xds_cluster"]
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


if [ "$CURRENT_ENVIRONMENT" == "ecs" ]; then
  echo "ECS !!!"
else
# for docker
cat <<EOF >> $CONFIG_FILE
  "stats_config":{
    "stats_tags":[
    ],
    "use_all_default_tags":true
  },
  "node":{
    "id":"$CONTAINER_ID",
    "cluster":"LOCAL",
    "metadata":{
        "containerId":"$CONTAINER_ID"
    },
    "locality":{
        "region":"region",
        "zone":"zone",
        "sub_zone":"sub_zone"
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

exec envoy -c $CONFIG_FILE --v2-config-only --max-obj-name-len 160