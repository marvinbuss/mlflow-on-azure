import os, adal, mlflow
from msrestazure.azure_cloud import AZURE_PUBLIC_CLOUD

###############
# PARAMETERS

# Azure AD Service Principal parameters
TENANT_ID = "<tenant-id>"  # Tenant ID for your Azure Subscription
CLIENT = "<client-id>"     # Service Principal App ID
KEY = "<secret>"           # Service Principal Password

# MLflow parameters
AZURE_STORAGE_CONNECTION_STRING = "<connection-string>"
TRACKING_URI = "<tracking-uri>" # e.g. http://localhost:5000 or https://<service-name>.azurewebsites.net
EXPERIMENT_NAME = "myexperiment"

###############
# CODE

# Azure AD Token Access
LOGIN_ENDPOINT = AZURE_PUBLIC_CLOUD.endpoints.active_directory
context = adal.AuthenticationContext(LOGIN_ENDPOINT + '/' + TENANT_ID)
aad_res = context.acquire_token_with_client_credentials(CLIENT, CLIENT, KEY)

# Setup of MLflow environment
os.environ["MLFLOW_TRACKING_TOKEN"] = aad_res["accessToken"]
os.environ["AZURE_STORAGE_CONNECTION_STRING"] = AZURE_STORAGE_CONNECTION_STRING
mlflow.set_tracking_uri(TRACKING_URI)

# Create MLflow experiment
experiment_id = mlflow.set_experiment(EXPERIMENT_NAME)

# Start MLflow run and log values and artifacts
with mlflow.start_run(run_name="run", experiment_id=experiment_id):
    mlflow.log_param("a", 1)
    mlflow.log_param("b", 2)
    
    # Log an artifact (output file)
    with open("output.txt", "w") as f:
        f.write("Hello world!")
    mlflow.log_artifact("output.txt")
