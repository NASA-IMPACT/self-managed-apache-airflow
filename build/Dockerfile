FROM apache/airflow:slim-2.7.0-python3.10

USER root
# `apt-get autoremove` is used to remove packages that were automatically installed to satisfy
# dependencies for other packages and are now no longer needed.
# `apt-get clean` clears out the local repository of retrieved package files

RUN apt-get update \
  && apt-get install -y --no-install-recommends gcc libc6-dev libcurl4-openssl-dev libssl-dev \ 
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --chown=airflow:airflow requirements.txt "${AIRFLOW_HOME}/requirements.txt"

USER airflow

RUN pip install --upgrade pip \
  && pip install --no-cache-dir -r requirements.txt -c "https://raw.githubusercontent.com/apache/airflow/constraints-2.7.0/constraints-3.10.txt"

COPY --chown=airflow:airflow dags "${AIRFLOW_HOME}/dags"
COPY --chown=airflow:airflow plugins "${AIRFLOW_HOME}/plugins"
COPY --chown=airflow:airflow configuration "${AIRFLOW_HOME}/configuration"
COPY --chown=airflow:airflow build/airflow.cfg "${AIRFLOW_HOME}/airflow.cfg"
COPY --chown=airflow:airflow scripts "${AIRFLOW_HOME}/scripts"

#ENV
ENV PYTHONPATH /opt/airflow
