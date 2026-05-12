FROM quay.io/jupyter/base-notebook:python-3.11

USER root

COPY requirements.txt /tmp/requirements.txt

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        git \
        vim \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /tmp/requirements.txt \
    && mkdir -p /srv/jupyterhub/runtime \
    && mkdir -p /home/jovyan/work \
    && chown -R jovyan:users /home/jovyan /srv/jupyterhub \
    && chmod -R 775 /srv/jupyterhub \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/requirements.txt

USER root