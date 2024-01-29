FROM --platform=linux/amd64 osgeo/gdal:latest

RUN apt-get -y update \
        && apt install -y python3-pip \
        && apt-get install -y --no-install-recommends gcc libc6-dev libcurl4-openssl-dev libssl-dev \
        && apt-get autoremove -yqq --purge \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

ARG UNAME=airflow

ARG UID=50000

ARG GID=0

ARG AIRFLOW_HOME=/opt/airflow

RUN groupadd -g $GID -o $UNAME

RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME

WORKDIR /opt/airflow

RUN chown $UNAME:$GID /opt/airflow


RUN apt-get update
RUN apt-get install -y --no-install-recommends gcc libc6-dev libcurl4-openssl-dev libssl-dev \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
USER airflow

ENV PATH $PATH:/home/airflow/.local/bin

COPY --chown=airflow:airflow requirements.txt "${AIRFLOW_HOME}/requirements.txt"

RUN pip install --upgrade pip \
    && pip install "apache-airflow[celery,amazon]==2.7.0" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.7.0/constraints-3.10.txt" \
    && pip install --no-cache-dir -r requirements.txt -c "https://raw.githubusercontent.com/apache/airflow/constraints-2.7.0/constraints-3.10.txt"


COPY --chown=airflow:airflow dags "${AIRFLOW_HOME}/dags"
COPY --chown=airflow:airflow plugins "${AIRFLOW_HOME}/plugins"
COPY --chown=airflow:airflow configuration "${AIRFLOW_HOME}/configuration"
COPY --chown=airflow:airflow build/airflow.cfg "${AIRFLOW_HOME}/airflow.cfg"
COPY --chown=airflow:airflow scripts "${AIRFLOW_HOME}/scripts"

# ENV
ENV AIRFLOW_HOME ${AIRFLOW_HOME}
ENV TZ UTC
ENV PYTHONPATH /opt/airflow
CMD /bin/bash