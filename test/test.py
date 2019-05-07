import os
import mlflow

# setup of environment
os.environ["AZURE_STORAGE_CONNECTION_STRING"] = "<storage-connection-string>"
mlflow.set_tracking_uri("http://<your-ip>:<your-port>")

# create experiment
#experiment_id = mlflow.create_experiment("test")

# create run and save 
with mlflow.start_run(run_name="run"): #, experiment_id=experiment_id):
    mlflow.log_param("a", 1)
    mlflow.log_param("b", 2)
    
    # Log an artifact (output file)
    with open("output.txt", "w") as f:
        f.write("Hello world!")
    mlflow.log_artifact("output.txt")