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
    Transform stage of the ETL pipeline for staging the Server Lobby table.

    This function performs the transformation stage of the ETL pipeline specifically for staging the Server Lobby table.
    It extracts relevant data from the input Server Lobby logs, applies necessary transformations, and creates a temporary view
    for further processing.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    """
    logger.info(f'ETL Pipeline | Transform | Staging Server Lobby Table')
    rs = sc.sql("""
        WITH unnamed_partitions AS (
            SELECT date_array[0] year, date_array[1] month, date_array[2] day, *
            FROM (
                SELECT SLICE(SPLIT(INPUT_FILE_NAME(), '/'), -4, 3) date_array, *
                FROM lib_server_lobby
            ) tbl
        )
        SELECT etl_id, msg_id, game_token, user_token, timestamp,
               superhero_id, superhero_attack, superhero_health,
               COUNT(*) distinct_count,
               MIN(year) year,
               MIN(month) month,
               MIN(day) day
        FROM unnamed_partitions
        GROUP BY etl_id, msg_id, game_token, user_token, timestamp,
                 superhero_id, superhero_attack, superhero_health
    """)

    rs.createOrReplaceTempView('stage__lib_server_lobby')

def _load(sc, blob_prefix='standard' if CLOUD_PROVIDER!='AZURE' else ''):
    """
    Load stage of the ETL pipeline for loading Server Lobby logs to Delta tables.

    This function performs the load stage of the ETL pipeline specifically for loading Server Lobby logs to Delta tables.
    It reads the transformed data from the staging table, writes it to Delta format partitioned by year, month, and day,
    and saves it to the specified output directory.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    - blob_prefix (str): The prefix to be appended to the output directory path (default: 'standard' if CLOUD_PROVIDER is not 'AZURE', else '').
    """
    logger.info(f'ETL Pipeline | Load | Loading Server lobby Logs to Delta Tables in {CLOUD_PROVIDER}')
    df = sc.table('stage__lib_server_lobby')
    df.write \
        .format('delta') \
        .partitionBy('year', 'month', 'day') \
        .mode('overwrite') \
        .save(os.path.join(OUTPUT_DIR, blob_prefix, 'lib_server_lobby'))

def entrypoint(blob_prefix='standard' if CLOUD_PROVIDER!='AZURE' else ''):
    """
    Entry point for the ETL pipeline to load Server Lobby logs.

    This function serves as the entry point for the ETL (Extract, Transform, Load) pipeline specifically designed to handle 
    Server Lobby logs. It initializes the SparkContext, extracts data from the input directory, transforms it, and loads 
    it into Delta tables.

    Parameters:
    - blob_prefix (str): The prefix to be appended to the input directory path (default: 'standard' if CLOUD_PROVIDER is not 'AZURE', else '').
    """
    sc = SparkConfig(app_name='stage_lib.servery.lobby') \
        .get_sparkContext()
    
    extract_tables(sc, os.path.join(INPUT_DIR, blob_prefix, 'lib_server_lobby'))
    _transform(sc)
    _load(sc)

if __name__ == '__main__':
    entrypoint()