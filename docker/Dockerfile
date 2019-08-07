FROM python:3.7.3-stretch

# setup the folder structure
RUN mkdir /code
WORKDIR /code
ADD requirements.txt /code/
RUN apt-get update
RUN pip install -r requirements.txt
ADD . /code/

# define default server env variables
ENV MLFLOW_SERVER_HOST 0.0.0.0
ENV MLFLOW_SERVER_PORT 5000
ENV MLFLOW_SERVER_WORKERS 1

# define application settings at deployment
#ENV MLFLOW_SERVER_FILE_STORE <local/storage/location>
#ENV MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT wasbs://<container>@<storage-account>.blob.core.windows.net/mlartefacts
#ENV AZURE_STORAGE_ACCESS_KEY <access-key>
#ENV AZURE_STORAGE_CONNECTION_STRING <connection-string>

# Enable and install SSH
ENV SSH_PASSWD "root:Docker!"
RUN apt-get update \
        && apt-get install -y --no-install-recommends dialog \
        && apt-get update \
	&& apt-get install -y --no-install-recommends openssh-server \
	&& echo "$SSH_PASSWD" | chpasswd 

COPY sshd_config /etc/ssh/
COPY startup.sh /usr/local/bin/

RUN ["chmod", "u+x", "/usr/local/bin/startup.sh"]
EXPOSE 5000 2222
ENTRYPOINT ["sh", "./startup.sh"]