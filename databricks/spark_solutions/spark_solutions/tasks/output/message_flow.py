""" Output ETL Pipeline | Message Flow

Output asset to model the flow/ throughput and latency
of the Super Hero Data Sim application's logged messages.

Logs originate from the `lib_server_game`/`lib_server_lobby`
and `log_meta` transports/actions which are queued in the
Pub/Sub or Message Queue service `buffer_meta` in anticipation
to be batched processed by the Cloud Data Flow service
`etl_meta` where the source data is finally landed in the
Data Lake's RAW Landing Zone.

Models below describe the transport from application to Data Lake

"""

from spark_solutions.common.spark_config import SparkConfig
from spark_solutions.common.spark_misc import extract_partitioned_tables

import logging
import os

logger = logging.getLogger(f'py4j.{__name__}')

# ENV Variables
CLOUD_PROVIDER=os.getenv('CLOUD_PROVIDER', 'LOCAL')
INPUT_DIR = os.getenv('STAGE_DIR')
OUTPUT_DIR = os.getenv('OUTPUT_DIR')

assert(not INPUT_DIR is None and INPUT_DIR != '')
assert(not OUTPUT_DIR is None and OUTPUT_DIR != '')

def _extract(sc, blob_prefix='stage' if CLOUD_PROVIDER!='AZURE' else ''):
    """
    Extracts partitioned tables from the specified input directories based on the cloud provider.

    This function performs the extraction stage of the ETL pipeline by extracting partitioned tables
    from the specified input directories. The extraction process varies based on the cloud provider.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    - blob_prefix (str): The prefix to be appended to input directory paths (default: 'stage' if CLOUD_PROVIDER is not 'AZURE', else '').
    """
    logger.info(f'ETL Pipeline | Extract | Extracting Partitioned Tables from {CLOUD_PROVIDER}')
    extract_partitioned_tables(sc, os.path.join(INPUT_DIR, blob_prefix, 'buffer_meta'))
    extract_partitioned_tables(sc, os.path.join(INPUT_DIR, blob_prefix, 'etl_meta'))
    extract_partitioned_tables(sc, os.path.join(INPUT_DIR, blob_prefix, 'log_meta'))
    extract_partitioned_tables(sc, os.path.join(INPUT_DIR, blob_prefix, 'lib_server_game'))
    extract_partitioned_tables(sc, os.path.join(INPUT_DIR, blob_prefix, 'lib_server_lobby'))

def _transform(sc):
    """
    Transforms data to create a message flow table.

    This function performs the transformation stage of the ETL pipeline by creating a message flow table
    based on data extracted from the input tables. The transformation involves joining data from multiple
    input tables to derive relevant information about message flow.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    """
    logger.info(f'ETL Pipeline | Transform | Creating Message Flow Table')
    rs = sc.sql("""
        SELECT log_meta.etl_id, log_meta.msg_id,
               log_meta.timestamp log_timestamp,
               buffer_meta.timestamp buffer_timestamp,
               etl_meta.timestamp_start etl_timestamp_start,
               etl_meta.timestamp_end etl_timestamp_end,
               buffer_meta.serialized_value_size buffer_content_size,
               etl_meta.service etl_service,
               etl_meta.mode etl_mode,
               YEAR(log_meta.timestamp) year,
               MONTH(log_meta.timestamp) month,
               DAYOFMONTH(log_meta.timestamp) day
        FROM log_meta
        LEFT JOIN buffer_meta ON
            log_meta.msg_id = buffer_meta.msg_id
        LEFT JOIN etl_meta ON
            log_meta.etl_id = etl_meta.etl_id
    """)

    rs.createOrReplaceTempView('output__message_flow')

def _load(sc, blob_prefix='output' if CLOUD_PROVIDER!='AZURE' else ''):
    """
    Loads message flows to Delta tables in the specified output directory based on the cloud provider.

    This function performs the load stage of the ETL pipeline by loading message flow data into Delta tables
    located in the specified output directory. The loading process varies based on the cloud provider.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    - blob_prefix (str): The prefix to be appended to the output directory paths (default: 'output' if CLOUD_PROVIDER is not 'AZURE', else '').
    """
    logger.info(f'ETL Pipeline | Load | Loading Message Flows to Delta Tables in {CLOUD_PROVIDER}')
    df = sc.table('output__message_flow')
    df.write \
        .format('delta') \
        .partitionBy('year', 'month', 'day') \
        .mode('overwrite') \
        .save(os.path.join(OUTPUT_DIR, blob_prefix, 'message_flow'))

def entrypoint():
    """
    Entry point for the ETL pipeline.

    This function serves as the entry point for the ETL (Extract, Transform, Load) pipeline.
    It initializes a SparkContext using the configured SparkConfig, performs extraction,
    transformation, and loading stages of the pipeline for message flows, and manages the overall execution flow.
    """
    sc = SparkConfig(app_name='output_message_flow') \
        .get_sparkContext()
    
    _extract(sc)
    _transform(sc)
    _load(sc)

if __name__ == '__main__':
    entrypoint()