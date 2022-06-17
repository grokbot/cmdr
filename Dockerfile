FROM docker:19.03.11 as static-docker-source

FROM debian:buster-slim

LABEL maintainer="David Ramsington"

ARG user_id
ARG pypi_host=pypi.org
ARG pypi_registry=https://pypi.org
ARG APP_ROOT=/opt/app
ARG KUBECTL_VERSION=1.24.0
ARG YQ_VERSION="v4.25.2"
ARG HELM_VERSION="v3.9.0"
ARG DOCTL_VERSION=1.75.0
ARG CLOUD_SDK_VERSION=390.0.0
ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION
ARG INSTALL_GCLOUD_COMPONENTS
ENV TERRAFORM_VERSION=1.2.2
ENV PYPI_HOST=$pypi_host
ENV PYPI_REGISTRY=$pypi_registry
ENV DEBIAN_FRONTEND noninteractive

# Python / runtime vars
ENV APP_ROOT=$APP_ROOT \
    HOME=$APP_ROOT/src \
    PATH=$APP_ROOT/src/.local/bin/:$APP_ROOT/src/bin:$APP_ROOT/bin:/opt/google-cloud-sdk/bin/:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    PIP_NO_CACHE_DIR=off \
    STANDARD_CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/pip" \
    WHEELHOUSE="${STANDARD_CACHE_DIR}/wheelhouse" \
    PIP_FIND_LINKS="file://${WHEELHOUSE}" \
    PIP_WHEEL_DIR="${WHEELHOUSE}" \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    PYPI_HOST=$PYPI_HOST \
    PYPI_REGISTRY=https://$PYPI_HOST \
    PIP_CONFIG_FILE=$APP_ROOT/etc/pip.conf \
    container=docker

# - Enable the virtual python environment and default interactive and non-interactive 
#   shell environment upon container startup
ENV BASH_ENV=$APP_ROOT/etc/py_enable \
    ENV=$APP_ROOT/etc/py_enable \
    PROMPT_COMMAND=". $APP_ROOT/etc/py_enable"

USER 0

COPY ./root /
COPY --from=static-docker-source /usr/local/bin/docker /usr/local/bin/docker
ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
ADD https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 /usr/local/bin/yq


# Install dependencies.
RUN apt-get update -qqy && apt-get install -qqy --no-install-recommends \
        curl \
        gcc \
        vim \
        redis-tools \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        python3-venv \
        apt-transport-https \
        lsb-release \
        openssh-client \
        libffi-dev \
        libssl-dev \
        build-essential \
        wget \
        git \
        sudo \
        systemd \
        systemd-sysv \
        gnupg \
        unzip \
    && rm -rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
# re-add for gcloud
    && mkdir -p /usr/share/man/man1 \ 
    && apt-get clean \
    && wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && wget -q https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz -O - |  tar -xzO doctl > /usr/local/bin/doctl \
    && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/* \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
# setup user
    && useradd -u $user_id -d $HOME -s /sbin/nologin \
       -c "Default Application User" default \
    && chown -R $user_id:$user_id $APP_ROOT \
    && sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers && \
# Get GCLOUD CLI
    pip3 install -U crcmod && \
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && apt-get install -y google-cloud-sdk=${CLOUD_SDK_VERSION}-0 $INSTALL_GCLOUD_COMPONENTS && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version && \
    gcloud components install gke-gcloud-auth-plugin && \
    git config --system credential.'https://source.developers.google.com'.helper gcloud.sh

USER $user_id

COPY ./requirements.txt $APP_ROOT/etc/requirements.txt

# Install Ansible, AWS CLI via Pip.
RUN python3 -m venv $APP_ROOT \
 && generate-pip-config && pip3 install --upgrade pip \
 && pip3 install -r $APP_ROOT/etc/requirements.txt \
 && chmod +x $APP_ROOT/src/.vault_pass \
# install common ansible collections
 && ansible-galaxy collection install -c community.kubernetes community.general amazon.aws community.aws google.cloud community.digitalocean community.mysql community.docker \
 && git config --global credential.helper "/bin/bash $APP_ROOT/bin/credential-helper"

WORKDIR $HOME

ENTRYPOINT [ "/usr/bin/container-entrypoint" ]