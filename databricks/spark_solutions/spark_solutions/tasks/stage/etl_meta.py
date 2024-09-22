from spark_solutions.common.spark_config import SparkConfig
from spark_solutions.common.spark_misc import extract_tables

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
    Transforms data to stage the ETL Meta table.

    This function performs the transformation stage of the ETL pipeline by staging the ETL Meta table.
    It calculates aggregates and extracts partition information from the input data.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    """
    logger.info(f'ETL Pipeline | Transform | Staging ETL Meta Table')
    rs = sc.sql("""
        WITH unnamed_partitions AS (
            SELECT date_array[0] year, date_array[1] month, date_array[2] day, *
            FROM (
                SELECT SLICE(SPLIT(INPUT_FILE_NAME(), '/'), -4, 3) date_array, *
                FROM etl_meta
            ) tbl
        )
        SELECT etl_id, service, mode, timestamp_start, timestamp_end,
               COUNT(*) distinct_count,
               MIN(year) year,
               MIN(month) month,
               MIN(day) day
        FROM unnamed_partitions
        GROUP BY etl_id, service, mode, timestamp_start, timestamp_end
    """)

    rs.createOrReplaceTempView('stage__etl_meta')

def _load(sc, blob_prefix='standard' if CLOUD_PROVIDER!='AZURE' else ''):
    """
    Loads ETL Meta logs to Delta tables in the specified output directory based on the cloud provider.

    This function performs the load stage of the ETL pipeline by loading ETL Meta logs into Delta tables
    located in the specified output directory. The loading process varies based on the cloud provider.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    - blob_prefix (str): The prefix to be appended to the output directory paths (default: 'standard' if CLOUD_PROVIDER is not 'AZURE', else '').
    """
    logger.info(f'ETL Pipeline | Load | Loading ETL Meta Logs to Delta Tables in {CLOUD_PROVIDER}')
    df = sc.table('stage__etl_meta')
    df.write \
        .format('delta') \
        .partitionBy('year', 'month', 'day') \
        .mode('overwrite') \
        .save(os.path.join(OUTPUT_DIR, blob_prefix, 'etl_meta'))

def entrypoint(blob_prefix='standard' if CLOUD_PROVIDER!='AZURE' else ''):
    """
    Entry point for the ETL pipeline to process ETL Meta logs.

    This function serves as the entry point for the ETL (Extract, Transform, Load) pipeline
    to process ETL Meta logs. It initializes a SparkContext using the configured SparkConfig,
    performs extraction, transformation, and loading stages, and manages the overall execution flow.

    Parameters:
    - blob_prefix (str): The prefix to be appended to the input directory paths (default: 'standard' if CLOUD_PROVIDER is not 'AZURE', else '').
    """
    sc = SparkConfig(app_name='stage_etl.meta') \
        .get_sparkContext()

    extract_tables(sc, os.path.join(INPUT_DIR, blob_prefix, 'etl_meta'))
    _transform(sc)
    _load(sc)

if __name__ == '__main__':
    entrypoint()