import mlflow
from sklearn.linear_model import LinearRegression
import os
import numpy as np


os.environ["MLFLOW_TRACKING_URI"] = "https://quantmetry-mlflow.azurewebsites.net/"
os.environ["AZURE_STORAGE_CONNECTION_STRING"] = "<THE AZURE CONN STRING>"


mlflow.set_experiment("test")
mlflow.start_run()
mlflow.log_param(key="linear_regression_param", value="linear_regression_param_value")
mlflow.log_param(key="linear_regression_param_bis", value="linear_regression_param_value_bis")
mlflow.log_param(key="linear_regression_param_int", value=0)
X = np.array([[1, 1], [1, 2], [2, 2], [2, 3]])
y = np.dot(X, np.array([1, 2])) + 3
model = LinearRegression()
fitted = model.fit(X, y)
mlflow.sklearn.log_model(fitted, "linear_regression")
mlflow.end_run()


