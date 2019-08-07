#!/bin/bash
set -e

echo "Starting SSH ..."
service ssh start

echo "Starting MLflow Tracking Server ..."
mlflow server \
    --backend-store-uri "$MLFLOW_SERVER_FILE_STORE" \
    --default-artifact-root "$MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT" \
    --host "$MLFLOW_SERVER_HOST" \
    --port "$MLFLOW_SERVER_PORT" \
    --workers "$MLFLOW_SERVER_WORKERS"