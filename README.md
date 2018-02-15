# hydro-serving-sidecar

## Build sidecar

```docker build -t hydrosphere/serving-sidecar .```

## Run sidecar

```docker run -e MANAGER_HOST=manager hydrosphere/serving-sidecar:latest```

### Environment variables
| Variable | Description | Default Value |
| :--- | :--- | :---: |
| `SIDECAR_LOG_LEVEL` | Content | `info` |
| `MANAGER_HOST` | Content  | `manager` |
| `MANAGER_PORT` | Content  | `8080` |
| `TRACING_ENABLED` | Content  | `false` |
| `TRACING_HOST` | Content  | `zipkin` |
| `TRACING_PORT` | Content  | `9411` |
| `TRACING_ENDPOINT` | Content  | `/api/v1/spans` |
| `CURRENT_ENVIRONMENT` | Content  | `local` |
| `ENVIRONMENT_NAME` | Content  | `_` |
| `MODEL` | Content  | `_` |
| `MODEL_VERSION` | Content  | `_` |
| `RUNTIME` | Content  | `_` |
| `RUNTIME_VERSION` | Content  | `_` |
| `SERVICE_ID` | Content  | `0` |
| `SERVICE_NAME` | Content  | `_` |
| `SERVICE_PROVIDER_ID` | Content  | `_` |
| `CLUSTER_NAME` | Content  | `_` |
| `LOCALITY_ZONE` | Content  | `_` |
| `LOCALITY_SUB_ZONE` | Content  | `_` |
| `LOCALITY_REGION` | Content  | `_` |