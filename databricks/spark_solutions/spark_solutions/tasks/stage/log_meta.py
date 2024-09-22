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
    Transform function for staging Log Meta table.

    This function transforms the Log Meta table data by partitioning it based on year, month, and day, and then aggregating 
    it based on the ETL ID, message ID, log level, timestamp, logger name, and log message.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    """
    logger.info(f'ETL Pipeline | Transform | Staging Log Meta Table')
    rs = sc.sql("""
        WITH unnamed_partitions AS (
            SELECT date_array[0] year, date_array[1] month, date_array[2] day, *
            FROM (
                SELECT SLICE(SPLIT(INPUT_FILE_NAME(), '/'), -4, 3) date_array, *
                FROM log_meta
            ) tbl
        )
        SELECT etl_id, msg_id, level, timestamp, name, log_message,
               COUNT(*) distinct_count,
               MIN(year) year,
               MIN(month) month,
               MIN(day) day
        FROM unnamed_partitions
        GROUP BY etl_id, msg_id, level, timestamp, name, log_message
    """)

    rs.createOrReplaceTempView('stage__log_meta')

def _load(sc, blob_prefix='standard' if CLOUD_PROVIDER!='AZURE' else ''):
    """
    Load function for loading Log Meta data into Delta Tables.

    This function loads the transformed Log Meta data into Delta Tables partitioned by year, month, and day.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    - blob_prefix (str): The prefix for the output blob directory. Defaults to 'standard' if CLOUD_PROVIDER is not 'AZURE'.
    """
    logger.info(f'ETL Pipeline | Load | Loading Log Meta to Delta Tables in {CLOUD_PROVIDER}')
    df = sc.table('stage__log_meta')
    df.write \
        .format('delta') \
        .partitionBy('year', 'month', 'day') \
        .mode('overwrite') \
        .save(os.path.join(OUTPUT_DIR, blob_prefix, 'log_meta'))

def entrypoint(blob_prefix='standard' if CLOUD_PROVIDER!='AZURE' else ''):
    """
    Entry point function for the ETL pipeline to process Log Meta data.

    This function initializes the Spark context, extracts Log Meta data from the specified input directory with the given blob prefix,
    transforms the data, and loads it into Delta Tables.

    Parameters:
    - blob_prefix (str): The prefix for the input blob directory. Defaults to 'standard' if CLOUD_PROVIDER is not 'AZURE'.
    """
    sc = SparkConfig(app_name='stage_log.meta') \
        .get_sparkContext()
    
    extract_tables(sc, os.path.join(INPUT_DIR, blob_prefix, 'log_meta'))
    _transform(sc)
    _load(sc)

if __name__ == '__main__':
    entrypoint()