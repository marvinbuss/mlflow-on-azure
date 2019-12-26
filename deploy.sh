#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace # For debugging

#####################
# PARAMETERS

# Resource group parameters
RG_NAME=mlflow-rg
RG_LOCATION=westeurope

# Container registry parameters
ACR_NAME=mlflowcontainerregistry

# Docker image parameters
DOCKER_IMAGE_NAME=mlflowimage
DOCKER_IMAGE_TAG=latest

# App service plan parameters
ASP_NAME=mlflowappserviceplan

# Web app parameters
WEB_APP_NAME=mlflow

# MLFlow settings
MLFLOW_HOST=0.0.0.0
MLFLOW_PORT=5000
MLFLOW_WORKERS=1
MLFLOW_FILESTORE=/mlruns/mlruns

# Storage parameters
STORAGE_ACCOUNT_NAME=storage$RANDOM
STORAGE_CONTAINER_NAME=mlflow
STORAGE_MOUNT_POINT=/mlruns
STORAGE_FILE_SHARE_NAME=mlflow
STORAGE_FILE_SHARE_SIZE=2

#####################
# DEPLOYMENT

echo "Creating resource group: $RG_NAME"
az group create \
    --name $RG_NAME \
    --location $RG_LOCATION

echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
az storage account create \
    --resource-group $RG_NAME \
    --location $RG_LOCATION \
    --name $STORAGE_ACCOUNT_NAME \
    --sku Standard_LRS

echo "Creating storage container for MLflow artifacts: $STORAGE_CONTAINER_NAME"
az storage container create \
    --name $STORAGE_CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT_NAME

echo "Creating file share for mounting to MLflow container: $STORAGE_CONTAINER_NAME"
az storage share create \
    --name $STORAGE_FILE_SHARE_NAME \
    --account-name $STORAGE_ACCOUNT_NAME \
    --quota $STORAGE_FILE_SHARE_SIZE

echo "Exporting storage keys: $STORAGE_ACCOUNT_NAME"
export STORAGE_ACCESS_KEY=$(az storage account keys list --resource-group $RG_NAME --account-name $STORAGE_ACCOUNT_NAME --query "[0].value" --output tsv)
export STORAGE_CONNECTION_STRING=`az storage account show-connection-string --resource-group $RG_NAME --name $STORAGE_ACCOUNT_NAME --output tsv`

echo "Creating Azure container registry: $ACR_NAME"
az acr create \
    --name $ACR_NAME \
    --resource-group $RG_NAME \
    --sku Basic \
    --admin-enabled true

echo "Getting Azure container registry credentials: $ACR_NAME"
export ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query "username" --output tsv)
export ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)

echo "Logging into Azure container registry"
docker login $ACR_NAME.azurecr.io \
    --username "$ACR_USERNAME" \
    --password "$ACR_PASSWORD"

echo "Building Docker image from file: $DOCKER_IMAGE_NAME"
cd docker
docker build \
    --tag $DOCKER_IMAGE_NAME \
    --file Dockerfile . \
    --no-cache
cd ..

echo "Pushing image to Azure container registry: $ACR_NAME"
docker tag $DOCKER_IMAGE_NAME $ACR_NAME.azurecr.io/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
docker push $ACR_NAME.azurecr.io/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG

echo "Showing pushed images"
az acr repository list \
    --name $ACR_NAME

echo "Creating app service plan: $ASP_NAME"
az appservice plan create \
    --name $ASP_NAME \
    --resource-group $RG_NAME \
    --sku S1 \
    --is-linux

echo "Creating web app: $WEB_APP_NAME"
az webapp create \
    --resource-group $RG_NAME \
    --plan $ASP_NAME \
    --name $WEB_APP_NAME \
    --deployment-container-image-name $ACR_NAME.azurecr.io/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG

echo "Configuring registry credentials in web app"
az webapp config container set \
    --name $WEB_APP_NAME \
    --resource-group $RG_NAME \
    --docker-custom-image-name $ACR_NAME.azurecr.io/$DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG \
    --docker-registry-server-url https://$ACR_NAME.azurecr.io \
    --docker-registry-server-user $ACR_USERNAME \
    --docker-registry-server-password $ACR_PASSWORD \
    --enable-app-service-storage true

# Should be fixed according to: https://github.com/Azure/azure-cli/issues/7261
echo "Enable continuous deployment for web app"
az webapp deployment container config \
    --name $WEB_APP_NAME \
    --resource-group $RG_NAME \
    --enable-cd true

echo "Setting Azure container registry credentials"
az webapp config appsettings set \
    --resource-group $RG_NAME \
    --name $WEB_APP_NAME \
    --settings WEBSITES_PORT=$MLFLOW_PORT

echo "Enabling access to logs generated from inside the container"
az webapp log config \
    --name $WEB_APP_NAME \
    --resource-group $RG_NAME \
    --docker-container-logging filesystem

echo "Setting environment variables"
az webapp config appsettings set \
    --resource-group $RG_NAME \
    --name $WEB_APP_NAME \
    --settings AZURE_STORAGE_CONNECTION_STRING=$STORAGE_CONNECTION_STRING
az webapp config appsettings set \
    --resource-group $RG_NAME \
    --name $WEB_APP_NAME \
    --settings MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT=wasbs://$STORAGE_CONTAINER_NAME@$STORAGE_ACCOUNT_NAME.blob.core.windows.net/mlartefacts
az webapp config appsettings set \
    --resource-group $RG_NAME \
    --name $WEB_APP_NAME \
    --settings MLFLOW_SERVER_WORKERS=$MLFLOW_WORKERS
az webapp config appsettings set \
    --resource-group $RG_NAME \
    --name $WEB_APP_NAME \
    --settings MLFLOW_SERVER_PORT=$MLFLOW_PORT
az webapp config appsettings set \
    --resource-group $RG_NAME \
    --name $WEB_APP_NAME \
    --settings MLFLOW_SERVER_HOST=$MLFLOW_HOST
az webapp config appsettings set \
    --resource-group $RG_NAME \
    --name $WEB_APP_NAME \
    --settings MLFLOW_SERVER_FILE_STORE=$MLFLOW_FILESTORE

echo "Linking storage account to web app"
az webapp config storage-account add \
    --resource-group $RG_NAME \
    --name $WEB_APP_NAME \
    --custom-id $STORAGE_ACCOUNT_NAME \
    --storage-type AzureFiles \
    --share-name $STORAGE_CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT_NAME \
    --access-key $STORAGE_ACCESS_KEY \
    --mount-path $STORAGE_MOUNT_POINT

echo "Verify linked storage account: $STORAGE_ACCOUNT_NAME"
az webapp config storage-account list \
    --resource-group $RG_NAME \
    --name $WEB_APP_NAME

#####################
# AZURE AD AUTHENTICATION AUTOMATION
# ATTENTION: NOT WORKING YET !!! --> Please do this manually

# Azure Active Directory and Service Principal parameters
#AAD_ISSUER_URL=<your-aad-issuer-url> # e.g. https://login.microsoftonline.com/AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE/
#SP_NAME=mlflowserviceprincipal

#echo "Creating Azure Active Directory Service Principal"
#export SP_CLIENT_SECRET=$(az ad sp create-for-rbac --name $SP_NAME --query "password" --output tsv)
#export SP_CLIENT_ID=$(az ad sp list --show-mine --query "[?appDisplayName=='$SP_NAME'].appId" -o tsv)

#echo "Enable Azure Active Directory Authentication"
#az webapp auth update \
#    --resource-group $RG_NAME \
#    --name $WEB_APP_NAME \
#    --enabled true \
#    --action LoginWithAzureActiveDirectory \
#    --aad-allowed-token-audiences https://$WEB_APP_NAME.azurewebsites.net/.auth/login/aad/callback \
#    --aad-client-id $SP_CLIENT_ID \
#    --aad-client-secret $SP_CLIENT_SECRET \
#    --aad-token-issuer-url $AAD_ISSUER_URL
