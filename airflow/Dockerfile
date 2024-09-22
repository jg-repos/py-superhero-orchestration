FROM apache/airflow:2.4.3

COPY --chown=airflow:root ./requirements.txt /opt/airflow/config/requirements.txt

RUN pip install -r /opt/airflow/config/requirements.txt
