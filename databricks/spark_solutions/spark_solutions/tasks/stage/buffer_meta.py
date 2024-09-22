from spark_solutions.common.spark_config import SparkConfig
from spark_solutions.common.spark_misc import extract_tables
from spark_solutions.loggers.log4j import inject_logging

import logging
import os

logger = logging.getLogger(f'py4j.{__name__}')

# ENV Variables
CLOUD_PROVIDER=os.getenv('CLOUD_PROVIDER', 'LOCAL')
INPUT_DIR = os.getenv('STANDARD_DIR')
OUTPUT_DIR = os.getenv('STAGE_DIR')

assert(not INPUT_DIR is None and INPUT_DIR != '')
assert(not OUTPUT_DIR is None and OUTPUT_DIR != '')

def _transform(sc):
    """
    Transforms data to stage the Buffer Meta table.

    This function performs the transformation stage of the ETL pipeline by staging the Buffer Meta table.
    It calculates aggregates and extracts partition information from the input data.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    """
    logger.info(f'ETL Pipeline | Transform | Staging Buffer Meta Table')
    rs = sc.sql("""
        WITH unnamed_partitions AS (
            SELECT date_array[0] year, date_array[1] month, date_array[2] day, *
            FROM (
                SELECT SLICE(SPLIT(INPUT_FILE_NAME(), '/'), -4, 3) date_array, *
                FROM buffer_meta
            ) tbl
        )
        SELECT etl_id, msg_id, checksum, headers, key, offset, partition,
               serialized_key_size, serialized_value_size, timestamp,
               timestamp_type, topic, _is_protocol,
               COUNT(*) distinct_count,
               MIN(year) year,
               MIN(month) month,
               MIN(day) day
        FROM unnamed_partitions
        GROUP BY etl_id, msg_id, checksum, headers, key, offset, partition,
               serialized_key_size, serialized_value_size, timestamp,
               timestamp_type, topic, _is_protocol
    """)

    rs.createOrReplaceTempView('stage__buffer_meta')

def _load(sc, blob_prefix='standard' if CLOUD_PROVIDER!='AZURE' else ''):
    """
    Loads Buffer Meta logs to Delta tables in the specified output directory based on the cloud provider.

    This function performs the load stage of the ETL pipeline by loading Buffer Meta logs into Delta tables
    located in the specified output directory. The loading process varies based on the cloud provider.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    - blob_prefix (str): The prefix to be appended to the output directory paths (default: 'standard' if CLOUD_PROVIDER is not 'AZURE', else '').
    """
    logger.info(f'ETL Pipeline | Load | Loading Buffer Meta Logs to Delta Tables in {CLOUD_PROVIDER}')
    df = sc.table('stage__buffer_meta')
    df.write \
        .format('delta') \
        .partitionBy('year', 'month', 'day') \
        .mode('overwrite') \
        .save(os.path.join(OUTPUT_DIR, blob_prefix, 'buffer_meta'))

def entrypoint(blob_prefix='standard' if CLOUD_PROVIDER!='AZURE' else ''):
    """
    Entry point for the ETL pipeline to process Buffer Meta logs.

    This function serves as the entry point for the ETL (Extract, Transform, Load) pipeline
    to process Buffer Meta logs. It initializes a SparkContext using the configured SparkConfig,
    injects logging for Py4J communication, performs extraction, transformation, and loading stages,
    and manages the overall execution flow.

    Parameters:
    - blob_prefix (str): The prefix to be appended to the input directory paths (default: 'standard' if CLOUD_PROVIDER is not 'AZURE', else '').
    """
    sc = SparkConfig(app_name='stage_buffer.meta') \
        .get_sparkContext()
    
    inject_logging(sc)
    
    extract_tables(sc, os.path.join(INPUT_DIR, blob_prefix, 'buffer_meta'))
    _transform(sc)
    _load(sc)

if __name__ == '__main__':
    entrypoint()