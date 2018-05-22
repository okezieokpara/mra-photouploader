FROM node:9

RUN useradd --create-home -s /bin/bash uploader

ARG USE_NGINX_PLUS_ARG
ARG USE_VAULT_ARG

# CONTAINER_ENGINE specifies the container engine to which the
# containers will be deployed. Valid values are:
# - kubernetes (default)
# - mesos
# - local
ENV USE_NGINX_PLUS=${USE_NGINX_PLUS_ARG:-true} \
    USE_VAULT=${USE_VAULT_ARG:-false}

COPY nginx/ssl /etc/ssl/nginx/

#Install Required packages
RUN apt-get update && apt-get install -y \
	jq \
	libffi-dev \
	libssl-dev \
	make \
	wget \
	vim \
	curl \
	apt-transport-https \
	ca-certificates \
	curl \
	librecode0 \
	libsqlite3-0 \
	libxml2 \
	lsb-release \
	unzip \
	--no-install-recommends && rm -r /var/lib/apt/lists/*

# Install nginx and forward request and error logs to docker log collector
ADD install-nginx.sh /usr/local/bin/
COPY ./nginx/ /etc/nginx/
RUN /usr/local/bin/install-nginx.sh && \
    ln -sf /dev/stdout /var/log/nginx/access_log && \
	ln -sf /dev/stderr /var/log/nginx/error_log


COPY ./app/status.html /usr/share/nginx/html/status.html

WORKDIR /usr/src/app
COPY ./app /usr/src/app/
COPY ./test /usr/src/test/
RUN yarn install && \
    yarn global add pm2 && \
    cd ../test && \
    yarn install

EXPOSE 443 80 3000

CMD ["./start.sh"]
