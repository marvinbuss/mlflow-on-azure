FROM python:3.8

LABEL maintainer="Marvin Buss (GitHub @marvinbuss)"

# Install dependencies
RUN apt-get update \
        && apt-get install -y --no-install-recommends openssh-server \
        && pip install --upgrade pip \
        && pip install -r code/requirements.txt

# Setup SSH
RUN rm -f /etc/ssh/sshd_config
RUN mkdir -p /home/LogFiles \
        && echo "root:Docker!" | chpasswd \
        && echo "cd /home" >> /etc/bash.bashrc
COPY /code/sshd_config /etc/ssh/
RUN mkdir -p /opt/startup

# Define default server environment variables
ENV MLFLOW_SERVER_HOST 0.0.0.0
ENV MLFLOW_SERVER_PORT 5000
ENV MLFLOW_SERVER_WORKERS 1
ENV SSH_PORT 2222

# Define application settings at deployment in Web App via application settings 
#ENV MLFLOW_SERVER_FILE_STORE <local/storage/location>
#ENV MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT wasbs://<container>@<storage-account>.blob.core.windows.net/mlartefacts
#ENV AZURE_STORAGE_ACCESS_KEY <access-key>
#ENV AZURE_STORAGE_CONNECTION_STRING <connection-string>

# Expose ports
EXPOSE 5000

# Copy and configure startup
COPY /code/startup.sh /code/startup.sh
RUN chmod -R 777 /code

# Start MLFlow tracking server
ENTRYPOINT ["sh", "/code/startup.sh"]