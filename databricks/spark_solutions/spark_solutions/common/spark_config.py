from spark_solutions.loggers.log4j import inject_logging
from pyspark.errors.exceptions import base
from py4j.protocol import Py4JJavaError
from pyspark.sql import SparkSession
from pathlib import Path
from delta import *

import spark_solutions.common.service_account_credentials as creds
import logging
import json
import os

logger = logging.getLogger(f'py4j.{__name__}')

# ENV Variables
CLOUD_PROVIDER=os.getenv('CLOUD_PROVIDER', 'LOCAL')

class SparkConfig():
    """
    Configures a Spark session based on the specified cloud provider.

    This class configures a Spark session based on the specified cloud provider (GCP, Azure, or AWS)
    by setting appropriate Spark properties and credentials.

    Attributes:
    - APP_NAME (str): The name of the Spark application.
    - WAREHOUSE_DIR (str): The directory for Spark warehouse.
    - SPARK_MASTER (str): The Spark master URL.
    - JARS_REPOSITORY (str): The repository URL for JAR packages.
    - JAR_URLS (list): List of URLs for additional JARs.
    - MAVEN_COORDINATES (list): List of Maven coordinates for additional dependencies.

    Methods:
    - __init__(self, app_name, warehouse_dir=None): Initializes the SparkConfig object.
    - get_sparkContext(self): Retrieves the SparkContext object.
    - config_spark_session_gcp(self, GOOGLE_PROJECT_ID): Configures Spark session for GCP.
    - config_spark_session_aws(self): Configures Spark session for AWS.
    - config_spark_session_azure(self, AZURE_TENANT_ID): Configures Spark session for Azure.
    - _config_spark_session(self): Configures the Spark session.
    - _config_spark_builder_library(self, _builder): Configures libraries for Spark session.
    - _config_spark_builder_warehouse(self, _builder): Configures warehouse directory for Spark session.
    - _config_spark_builder_extra(self, _builder): Adds extra configurations to the Spark session builder.
    - _config_spark(self, _builder): Configures Spark session with Delta Lake.
    - _config_spark_logging(self, sc): Configures Spark logging.
    - _config_spark_extra(self, sc): Adds extra configurations to the Spark session.
    """

    # ENV Variables
    APP_NAME=os.getenv('APP_NAME', 'Spark-MultiCloud-Application-Example')
    WAREHOUSE_DIR=os.getenv('WAREHOUSE_DIR', None)
    SPARK_MASTER=os.getenv('SPARK_MASTER', 'local[*]')
    JARS_REPOSITORY=os.getenv('JARS_REPOSITORY', 'https://maven-central.storage-download.googleapis.com/maven2/')
    JAR_URLS=[]
    MAVEN_COORDINATES=[]

    def __init__(self, app_name, warehouse_dir=None) -> SparkSession:
        """
        Initializes the SparkConfig object.

        Parameters:
        - app_name (str): The name of the Spark application.
        - warehouse_dir (str): The directory for Spark warehouse.
        """
        self.app_name = app_name
        self.warehouse_dir=warehouse_dir

        if CLOUD_PROVIDER == 'GCP':
            self.sc = self.config_spark_session_gcp()
        elif CLOUD_PROVIDER == 'AZURE':
            self.sc = self.config_spark_session_azure()
        elif CLOUD_PROVIDER == 'AWS':
            self.sc = self.config_spark_session_aws()
    
        self.sc = self._config_spark_session()
    
    def get_sparkContext(self):
        """
        Retrieves the SparkContext object.

        Returns:
        - SparkContext: The SparkContext object.
        """
        return self.sc
    
    def config_spark_session_gcp(self, GOOGLE_PROJECT_ID=os.getenv('GOOGLE_PROJECT_ID', None)):
        """
        Configures Spark session for Google Cloud Platform (GCP).
        https://docs.gcp.databricks.com/storage/gcs.html#step-5-configure-a-databricks-cluster

        Parameters:
        - GOOGLE_PROJECT_ID (str): The Google Cloud project ID.

        Returns:
        - SparkSession: The configured SparkSession object.
        """
        assert(not GOOGLE_PROJECT_ID is None)
        self.JAR_URLS = ['https://github.com/GoogleCloudDataproc/hadoop-connectors/releases/download/v2.2.17/gcs-connector-hadoop3-2.2.17-shaded.jar']
    
        sc = self._config_spark_session()
        try:
            if sc._jsc.hadoopConfiguration().get('fs.gs.project.id') == GOOGLE_PROJECT_ID:
                return sc
        except Py4JJavaError:
            logger.info('Configuring Spark Session GCP Properties')
            sa_id, sa_secret =  creds.get_credentials(sc)
            secret_json = json.loads(sa_secret)
            sc._jsc.hadoopConfiguration().set('fs.gs.auth.type', 'USER_CREDENTIALS')
            sc._jsc.hadoopConfiguration().set('fs.gs.impl', 'com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystem')
            sc._jsc.hadoopConfiguration().set('fs.AbstractFileSystem.gs.impl', 'com.google.cloud.hadoop.fs.gcs.GoogleHadoopFS')
            sc._jsc.hadoopConfiguration().set('google.cloud.auth.service.account.enable', 'true')
            sc._jsc.hadoopConfiguration().set('google.cloud.auth.service.account.email',  secret_json['client_email'])
            sc._jsc.hadoopConfiguration().set('fs.gs.project.id', GOOGLE_PROJECT_ID)
            sc._jsc.hadoopConfiguration().set('google.cloud.auth.service.account.private.key.id', secret_json['private_key_id'])
            sc._jsc.hadoopConfiguration().set('google.cloud.auth.service.account.private.key', secret_json['private_key'])

            return sc
    
    def config_spark_session_aws(self):
        """
        Configures Spark session for Amazon Web Services (AWS).
        https://docs.gcp.databricks.com/storage/amazon-s3.html#global-configuration

        Returns:
        - SparkSession: The configured SparkSession object.
        """
        self.MAVEN_COORDINATES = [
            'org.apache.hadoop:hadoop-aws:3.3.4',
            'com.amazonaws:aws-java-sdk:1.12.552'
        ]

        sc = self._config_spark_session()
        try:
            if sc.conf.get('spark.hadoop.fs.s3a.endpoint') == 's3.amazonaws.com':
                return sc
        except Py4JJavaError:
            logger.info('Configuring Spark Session AWS Properties')
            sp_id, sp_secret = creds.get_credentials(sc)
            sc.conf.set('spark.hadoop.fs.s3a.access.key', sp_id)
            sc.conf.set('spark.hadoop.fs.s3a.secret.key', sp_secret)
            sc.conf.set('spark.hadoop.fs.s3a.aws.credentials.provider', 'org.apache.hadoop.fs.s3a.BasicAWSCredentialsProvider')
            sc.conf.set('spark.hadoop.fs.s3a.endpoint', 's3.amazonaws.com')
            sc.conf.set('spark.hadoop.fs.s3a.server-side-encryption-algorithm', 'SSE-KMS')

            return sc
    
    def config_spark_session_azure(self, AZURE_TENANT_ID=os.getenv('AZURE_TENANT_ID', None)):
        """
        Configures Spark session for Microsoft Azure.
        https://docs.gcp.databricks.com/storage/azure-storage.html#set-spark-properties-to-configure-azure-credentials-to-access-azure-storage

        Parameters:
        - AZURE_TENANT_ID (str): The Azure tenant ID.

        Returns:
        - SparkSession: The configured SparkSession object.
        """
        assert(not AZURE_TENANT_ID is None)
        self.MAVEN_COORDINATES = [
            'org.apache.hadoop:hadoop-azure-datalake:3.3.3',
            'org.apache.hadoop:hadoop-common:3.3.3',
            'org.apache.hadoop:hadoop-azure:3.3.3'
        ]

        sc = self._config_spark_session()
        try:
            if sc.conf.get('fs.azure.account.oauth2.client.endpoint') == f'https://login.microsoftonline.com/{AZURE_TENANT_ID}/oauth2/token':
                return sc
        except Py4JJavaError:
            logger.info('Configuring Spark Session Azure Properties')
            sp_id, sp_secret = creds.get_credentials()
            sc.conf.set('fs.azure.account.auth.type', 'OAuth')
            sc.conf.set('fs.azure.account.oauth.provider.type', 'org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider')
            sc.conf.set('fs.azure.account.oauth2.client.id', sp_id)
            sc.conf.set('fs.azure.account.oauth2.client.secret', sp_secret)
            sc.conf.set('fs.azure.account.oauth2.client.endpoint', f'https://login.microsoftonline.com/{AZURE_TENANT_ID}/oauth2/token')

            sc._jsc.hadoopConfiguration().set('fs.azure.createRemoteFileSystemDuringInitialization', 'false')

        return sc
    
    def _config_spark_session(self):
        """
        Configures the Spark session.

        Returns:
        - SparkSession: The configured SparkSession object.
        """
        logger.info('Configuring Spark Session')
        _builder = SparkSession \
            .builder \
            .master(self.SPARK_MASTER) \
            .appName(self.APP_NAME)
    
        _builder = self._config_spark_builder_library(_builder)
        _builder = self._config_spark_builder_warehouse(_builder)
        _builder = self._config_spark_builder_extra(_builder)
        sc = self._config_spark(_builder)
        sc = self._config_spark_extra(sc)
        self._config_spark_logging(sc)
    
        logger.info('Spark Session Configured Succesfully')
        return sc

    def _config_spark_builder_library(self, _builder):
        """
        Configures libraries for Spark session.

        Parameters:
        - _builder: The SparkSession builder object.

        Returns:
        - SparkSession.Builder: The configured SparkSession builder object.
        """
        try:
            if SparkSession.active():
                return _builder
        except base.PySparkRuntimeError:
            logger.info('Configuring Spark Cluster Repositories & JAR Packages')
            _builder = _builder \
                .config('spark.jars.repository', self.JARS_REPOSITORY) \
                .config('spark.jars.packages', ','.join(self.MAVEN_COORDINATES)) \
                .config('spark.jars', ','.join(self.JAR_URLS)) \
                .config('spark.sql.extensions', 'io.delta.sql.DeltaSparkSessionExtension') \
                .config('spark.sql.catalog.spark_catalog', 'org.apache.spark.sql.delta.catalog.DeltaCatalog')
        
        return _builder
    
    def _config_spark_builder_warehouse(self, _builder):
        """
        Configures warehouse directory for Spark session.

        Parameters:
        - _builder: The SparkSession builder object.

        Returns:
        - SparkSession.Builder: The configured SparkSession builder object.
        """
        try:
            if SparkSession.active():
                return _builder
        except base.PySparkRuntimeError:
            if self.WAREHOUSE_DIR:
                _builder = _builder \
                    .config('spark.hive.metastore.warehouse.dir', Path(self.WAREHOUSE_DIR).as_uri())
        
        return _builder
    
    def _config_spark_builder_extra(self, _builder):
        """
        Adds extra configurations to the Spark session builder.

        Parameters:
        - _builder: The SparkSession builder object.

        Returns:
        - SparkSession.Builder: The configured SparkSession builder object.
        """
        return _builder.config('spark.sql.parquet.datetimeRebaseModeInRead', 'CORRECTED')
    
    def _config_spark(self, _builder):
        """
        Configures Spark session with Delta Lake.

        Parameters:
        - _builder: The SparkSession builder object.

        Returns:
        - SparkSession: The configured SparkSession object.
        """
        return configure_spark_with_delta_pip(_builder, extra_packages=self.MAVEN_COORDINATES) \
            .getOrCreate()
    
    def _config_spark_logging(self, sc):
        """
        Configures Spark logging.

        Parameters:
        - sc: The SparkContext object.
        """
        sc.sparkContext.setLogLevel('INFO')
        inject_logging(sc)
    
    def _config_spark_extra(self, sc):
        """
        Adds extra configurations to the Spark session.

        Parameters:
        - sc: The SparkContext object.

        Returns:
        - SparkContext: The configured SparkContext object.
        """
        sc.conf.set('spark.sql.sources.patitionOverwriteMethod', 'dynamic')
        sc._jsc.hadoopConfiguration().set('mapreduce.input.fileinputformat.input.dir.recursive', 'true')

        return sc
