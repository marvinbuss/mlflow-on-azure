from __future__ import print_function
from sklearn.linear_model import LogisticRegression
import os
import numpy as np
import random
import mlflow
import mlflow.sklearn

# parameters
AZURE_STORAGE_CONNECTION_STRING = "<connection-string>"
TRACKING_URI = "<tracking-uri>" # e.g. http://localhost:5000
EXPERIMENT_NAME = "myexperiment"
MODEL_NAME = "mymodel"

# setup of environment
os.environ["AZURE_STORAGE_CONNECTION_STRING"] = AZURE_STORAGE_CONNECTION_STRING
mlflow.set_tracking_uri(TRACKING_URI)

if __name__ == "__main__":
    # set experiment
    experiment_id = mlflow.set_experiment(EXPERIMENT_NAME)
    
    # create data
    X = np.array([-2, -1, 0, 1, 2, 1]).reshape(-1, 1)
    y = np.array([0, 0, 1, 1, 1, 0])

    # create model instance
    lr = LogisticRegression()

    # start run
    with mlflow.start_run(run_name="run", experiment_id=experiment_id):
        mlflow.log_param("random_value", random.randint(0, 100))
        mlflow.set_tag("mytagkey", "mytagvalue")
        
        lr.fit(X, y)
        score = lr.score(X, y)
        print("Score: %s" % score)
        mlflow.log_metric("score", score)
        mlflow.sklearn.log_model(lr, MODEL_NAME)
        print("Model saved in run %s" % mlflow.active_run().info.run_uuid)