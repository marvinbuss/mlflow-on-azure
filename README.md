![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/mrnivram/mlflow.svg?style=flat-square)

# MLFlow Docker Container and Deployment on an Azure Kubernetes Service (AKS)
This project can be used to deploy the MLFlow Tracking Server (version 1.0.0) in a Docker container locally or on Azure. More precisely, it can be used to deploy the Docker image on an Azure Kubernetes Service (AKS), where you will probably also host other services or your ML or DL models.

I updated the MLFlow version to 1.0.0, optimized the storage behaviour of logs and used existing projects, that you can find here:
* https://github.com/devlace/mlflow-tracking-azure
* https://github.com/Ycallaer/mlflowdocker

## Local deployment
If you want to test the Docker container locally, then please follow these steps:

1. Install [Docker](https://docs.docker.com/) on your machine.
2. Clone the project to your local machine and unpack the zip file.
3. Open your terminal or command line and navigate to the unpacked folder (navigate to the `docker` folder of this project).
3. Build the Docker image with the following command: `docker build -t <your-docker-container-name> -f Dockerfile . --no-cache`
4. Deploy a storage account in your Azure subscription and create a container in the blob storage.
5. Write down the storage account name (`<storage-account>`), the storage connection string (`<connection-string>`) and the name of the blob container (`<blob-container>`).
6. Once the build was successful and the storage account has been created you can run the Docker image with the following command: `docker run -p 5000:5000 --env MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT=wasbs://<blob-container>@<storage-account>.blob.core.windows.net/mlartefacts --env AZURE_STORAGE_CONNECTION_STRING==<connection-string> -it <your-docker-container-name>:latest`
7. Open the MLFlow hub by visiting: https://localhost:5000 (On Windows, do not open https://0.0.0.0:5000 as shown in the command line)

## Deployment on Azure Kubernetes Service
![AKS Deployment of MLFlow tracking server](pictures/architecture.png?raw=true "AKS Deployment of MLFlow tracking server")

If you want to deploy the MLFlow tracking server on an Azure Kubernetes Service (AKS), where you will later also deploy your machine learning or deep learning models once they go into production, then please follow these steps:

0. NOTE: On Windows you can also use the Linux subsystem for the deployment.
1. Clone the project to your local machine and unpack the zip file.
2. Open your terminal and navigate to the unpacked folder (navigate to the `aks_deployment` folder of this project).
3. Open `deploy.sh` and adjust some settings, if required.
    - RG_NAME = name of the resource group to which the resources will be deployed
    - RG_LOCATION = location that is used for deployment of the resources
    - AKS_NAME = name that is used for the AKS cluster
    - AKS_STORAGE_ACCOUNT_NAME = name of the storage account that will be created
    - AKS_STORAGE_CONTAINER_NAME = name of the container that will be created in the blob storage
4. Open `mlflowtracking.yaml` and adjust some settings, if required.
    - image = insert the name of your own image if you have made changes to it and uploaded it to Dockerhub
    - replicas = change the number of replicas of the container
    - containerPort = change the port of the container that is exposed by the service
    - change other env variables, such as `AZURE_STORAGE_CONNECTION_STRING`, `MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT`, `MLFLOW_SERVER_FILE_STORE`, `MLFLOW_SERVER_HOST` and `MLFLOW_SERVER_PORT`, if required.
5. Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) and install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
6. Open your terminal and login into azure CLI:
    - Run `az login` to login to Azure.
    - Run `az account set -s <subscription-id>` to set the target azure subscription.
7. Run `./deploy.sh` and wait for the deployment to finish.
8. Once the execution of the script finishes you can check the deployment and retrieve the IP and port that is exposed by the service by executing `kubectl get services` (please wait, if the external IP of the `mlflow-tracking-front` service is set to `<pending>`).
9. Open the page `<your-ip>:<your-port>` (default port is 5000).

## Test the deployment
If you want to test your local deployment or the deployment on AKS, then please follow these steps:

1. Navigate to the `test` folder once you unpacked the zip folder.
2. Write down the connection string of your Azure storage account and the IP and port of the MLFlow Tracking Server (https://localhost:5000 in case of local deployemnt).
3. Choose one of the provided examples `test.py` or `test_with_model.py`.
3. Insert the values in the selected example:
    - Insert your connection string into the placeholder `<connection-string>`.
    - Insert the IP address and port into the placeholder `<tracking-uri>` (default port is 5000).
4. Run the python file.
5. Open the page `<your-ip>:<your-port>` (default port is 5000) and view the logged run, values and artifacts.

**INFO:** The artifacts will be stored in the blob storage of the deployed Azure storage account. Other log data will be stored in the file store of another storage account that is located in the resource group of your AKS (the second one that gets automatically created when deploying an AKS cluster).

## MLFLow documentation
Find more details about the use of MLFlow on the following website: https://mlflow.org/docs/latest/index.html
