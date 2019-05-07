FROM python:3.7.0-stretch

# define default server env variables
ENV MLFLOW_SERVER_HOST 0.0.0.0
ENV MLFLOW_SERVER_PORT 5000
ENV MLFLOW_SERVER_WORKERS 4

# define application settings at deployment
#ENV MLFLOW_SERVER_FILE_STORE <local/storage/location>
#ENV MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT wasbs://<container>@<storage-account>.blob.core.windows.net/mlartefacts
#ENV AZURE_STORAGE_ACCESS_KEY <access-key>
#ENV AZURE_STORAGE_CONNECTION_STRING <connection-string>

# Set the working directory to /
WORKDIR /

# Copy the directory contents into the container at /
COPY . /

# update and install required packages
RUN apt-get update
RUN pip install -r requirements.txt

ENTRYPOINT ["./startup.sh"]