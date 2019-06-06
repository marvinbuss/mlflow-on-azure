import os
import mlflow

# parameters
AZURE_STORAGE_CONNECTION_STRING = "<connection-string>"
TRACKING_URI = "<tracking-uri>" # e.g. http://localhost:5000
EXPERIMENT_NAME = "myexperiment"

# setup of environment
os.environ["AZURE_STORAGE_CONNECTION_STRING"] = AZURE_STORAGE_CONNECTION_STRING
mlflow.set_tracking_uri(TRACKING_URI)

# create experiment
#experiment_id = mlflow.create_experiment(EXPERIMENT_NAME, artifact_location="/")
experiment_id = mlflow.set_experiment(EXPERIMENT_NAME)

# create run and save 
with mlflow.start_run(run_name="run", experiment_id=experiment_id):
    mlflow.log_param("a", 1)
    mlflow.log_param("b", 2)
    
    # Log an artifact (output file)
    with open("output.txt", "w") as f:
        f.write("Hello world!")
    mlflow.log_artifact("output.txt")