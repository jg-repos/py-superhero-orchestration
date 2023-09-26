from pyspark.sql import SparkSession
from pathlib import Path
from delta import *

import spark_solutions.common.service_account_credentials as creds
import os

# ENV Variables
SPARK_MASTER=os.getenv('SPARK_MASTER', 'local[*]')
JARS_REPOSITORY=os.getenv('JARS_REPOSITORY', 'https://maven-central.storage-download.googleapis.com/maven2/')
CLOUD_PROVIDER=os.getenv('CLOUD_PROVIDER', 'LOCAL')

def _config_spark_session(app_name, warehouse_dir, jars):
    _builder = SparkSession \
        .builder \
        .master(SPARK_MASTER) \
        .appName(app_name) \
        .config('spark.sql.parquet.datetimeRebaseModeInRead', 'CORRECTED') \
        .config('spark.jars.repository', JARS_REPOSITORY)
    
    if warehouse_dir:
        jars.append('io.delta:delta-core_2.13:2.3.0')
        _builder = _builder \
            .config('spark.hive.metastore.warehouse.dir', Path(warehouse_dir).as_uri()) \
            .config('spark.sql.extensions', 'io.delta.sql.DeltaSparkSessionExtension') \
            .config('spark.sql.catalog.spark_catalog', 'org.apache.spark.sql.delta.catalog.DeltaCatalog') \
            .config('spark.jars.packages', ','.join(jars))
        
        sc = configure_spark_with_delta_pip(_builder).getOrCreate()
    else:
        sc = _builder \
            .config('spark.jars.packages', ','.join(jars)) \
            .getOrCreate()
    
    sc.conf.set('spark.sql.sources.patitionOverwriteMethod', 'dynamic')
    sc._jsc.hadoopConfiguration().set('mapreduce.input.fileinputformat.input.dir.recursive', 'true')
    return sc

def config_spark_session_aws(app_name, warehouse_dir):
    # https://docs.gcp.databricks.com/storage/amazon-s3.html#global-configuration
    JARS = [
        'org.apache.hadoop:hadoop-aws:3.3.4',
        'com.amazonaws:aws-java-sdk:1.12.552'
    ]

    sc = _config_spark_session(app_name, warehouse_dir, JARS)
    sp_id, sp_secret = creds.get_credentials(sc)
    sc.conf.set('spark.hadoop.fs.s3a.access.key', sp_id)
    sc.conf.set('spark.hadoop.fs.s3a.secret.key', sp_secret)
    sc.conf.set('spark.hadoop.fs.s3a.aws.credentials.provider', 'org.apache.hadoop.fs.s3a.BasicAWSCredentialsProvider')
    sc.conf.set('spark.hadoop.fs.s3a.endpoint', 's3.amazonaws.com')
    sc.conf.set('spark.hadoop.fs.s3a.server-side-encryption-algorithm', 'SSE-KMS')

    return sc

def config_spark_session_azure(app_name, warehouse_dir):
    # https://docs.gcp.databricks.com/storage/azure-storage.html#set-spark-properties-to-configure-azure-credentials-to-access-azure-storage
    # Config
    AZURE_TENANT_ID = os.getenv('AZURE_TENANT_ID')
    JARS = [
        'org.apache.hadoop:hadoop-azure-datalake:3.3.3',
        'org.apache.hadoop:hadoop-common:3.3.3',
        'org.apache.hadoop:hadoop-azure:3.3.3'
    ]

    assert(not AZURE_TENANT_ID is None)
    sc = _config_spark_session(app_name, warehouse_dir, JARS)
    sp_id, sp_secret = creds.get_credentials(sc)
    sc.conf.set('fs.azure.account.auth.type', 'OAuth')
    sc.conf.set('fs.azure.account.oauth.provider.type', 'org.apache.hadoop.fs.azurebfs.oauth2.ClientCredesTokenProvider')
    sc.conf.set('fs.azure.account.oauth2.client.id', sp_id)
    sc.conf.set('fs.azure.account.oauth2.client.secret', sp_secret)
    sc.conf.set('fs.azure.account.oauth2.client.endpoint', f'https://login.microsoftonline.com/{AZURE_TENANT_ID}/ouath2/token')
    sc._jsc.hadoopConfiguration().set('fs.azure.createRemoteFileSystemDuringInitialization', 'false')

    return sc

def config_spark_session_gcp(app_name, warehouse_dir):
    # https://docs.gcp.databricks.com/storage/gcs.html#step-5-configure-a-databricks-cluster
    # Config
    SERVICE_ACCOUNT_EMAIL = os.getenv('SERVICE_ACCOUNT_EMAIL', None)
    GOOGLE_PROJECT_ID = os.getenv('GOOGLE_PROJECT_ID', None)
    JARS = ['com.google.cloud.bigdataoss:gcs-connector:hadoop3-2.2.17']

    assert(not GOOGLE_PROJECT_ID is None)
    assert(not SERVICE_ACCOUNT_EMAIL is None)
    sc = _config_spark_session(app_name, warehouse_dir, JARS)
    
    sa_id, sa_secret =  creds.get_credentials(sc)
    sc.config.set('spark.hadoop.google.cloud.auth.service.account.enable', 'true')
    sc.config.set('spark.hadoop.fs.gs.auth.service.account.email',  SERVICE_ACCOUNT_EMAIL)
    sc.config.set('spark.hadoop.fs.gs.project.id', GOOGLE_PROJECT_ID)
    sc.config.set('spark.hadoop.fs.gs.auth.service.account.private.key', sa_id)
    sc.config.set('spark.hadoop.fs.gs.auth.service.account.private.key.id', sa_secret)

def config_spark_session(app_name, warehouse_dir=None):
    if CLOUD_PROVIDER == 'GCP':
        return config_spark_session_gcp(app_name, warehouse_dir)
    elif CLOUD_PROVIDER == 'AZURE':
        return config_spark_session_azure(app_name, warehouse_dir)
    elif CLOUD_PROVIDER == 'AWS':
        return config_spark_session_aws(app_name, warehouse_dir)
    
    return _config_spark_session(app_name, warehouse_dir, jars=[])