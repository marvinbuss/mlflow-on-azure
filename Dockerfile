FROM python:3.8

LABEL maintainer "Marvin Buss (GitHub @marvinbuss)"

# Copy code folder
COPY /code /code

# Install and enable SSH
ENV SSH_PASSWD "root:Docker!"
RUN apt-get update \
        && apt-get install -y \
        && apt-get install -y --no-install-recommends dialog \
        && apt-get update \
	&& apt-get install -y --no-install-recommends openssh-server \
	&& echo "$SSH_PASSWD" | chpasswd 
COPY /code/sshd_config /etc/ssh/
EXPOSE 2222

# Install dependencies
RUN pip install -r /code/requirements.txt

# Define default server env variables
ENV MLFLOW_SERVER_HOST 0.0.0.0
ENV MLFLOW_SERVER_PORT 5000
ENV MLFLOW_SERVER_WORKERS 1

# Define application settings at deployment in Web App via application settings 
#ENV MLFLOW_SERVER_FILE_STORE <local/storage/location>
#ENV MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT wasbs://<container>@<storage-account>.blob.core.windows.net/mlartefacts
#ENV AZURE_STORAGE_ACCESS_KEY <access-key>
#ENV AZURE_STORAGE_CONNECTION_STRING <connection-string>

# Start MLFlow tracking server
RUN ["chmod", "u+x", "/code/startup.sh"]
EXPOSE 5000
ENTRYPOINT ["sh", "/code/startup.sh"]