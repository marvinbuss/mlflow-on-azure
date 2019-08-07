from __future__ import print_function
from sklearn.linear_model import LogisticRegression
from msrestazure.azure_cloud import AZURE_PUBLIC_CLOUD
import os, adal, random, mlflow, mlflow.sklearn
import numpy as np

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
MODEL_NAME="mymodel"

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

# create data
X = np.array([-2, -1, 0, 1, 2, 1]).reshape(-1, 1)
y = np.array([0, 0, 1, 1, 1, 0])

# Create model instance
lr = LogisticRegression()

# Start MLflow run and log values and artifacts
with mlflow.start_run(run_name="run", experiment_id=experiment_id):
    mlflow.log_param("random_value", random.randint(0, 100))
    mlflow.set_tag("mytagkey", "mytagvalue")
    
    lr.fit(X, y)
    score = lr.score(X, y)
    print("Score: %s" % score)
    mlflow.log_metric("score", score)
    mlflow.sklearn.log_model(lr, MODEL_NAME)
    print("Model saved in run %s" % mlflow.active_run().info.run_uuid)