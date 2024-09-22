""" Output ETL Pipeline | Game Metrics

Output asset to model the engagement metrics by user within the
Super Hero Data Sim application.

Time of use is described as the time users are in game, alive, and
not waiting in lobby. Users waiting in lobby aren't tracked.

Damage Dealt/ Damage Received

Game Turns

Wins/Losses

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
    extract_partitioned_tables(sc, os.path.join(INPUT_DIR, blob_prefix, 'log_meta'))
    extract_partitioned_tables(sc, os.path.join(INPUT_DIR, blob_prefix, 'lib_server_lobby'))
    extract_partitioned_tables(sc, os.path.join(INPUT_DIR, blob_prefix, 'lib_server_game'))

def _transform(sc):
    """
    Transforms data to create a game metrics table.

    This function performs the transformation stage of the ETL pipeline by creating a game metrics table
    based on the data extracted from the input tables. The transformation involves aggregating and
    joining data from multiple input tables to derive relevant metrics.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    """
    logger.info(f'ETL Pipeline | Transform | Creating Game Metrics Table')
    rs = sc.sql("""
        WITH lobby_time AS (
            SELECT game_token, MIN(timestamp) start_time
            FROM lib_server_lobby
            GROUP BY game_token
        ),
        game_time AS (
            SELECT game_time.game_token, lobby_time.start_time, game_time.end_time,
                   UNIX_TIMESTAMP(game_time.end_time) - UNIX_TIMESTAMP(lobby_time.start_time) time_of_use_seconds,
                   YEAR(lobby_time.start_time) year,
                   MONTH(lobby_time.start_time) month,
                   DAYOFMONTH(lobby_time.start_time) day
            FROM (
                SELECT game_token, MAX(timestamp) end_time
                FROM lib_server_game
                GROUP BY game_token
            ) game_time
            LEFT JOIN lobby_time ON
                game_time.game_token = lobby_time.game_token
        ),
        game_damage_dealt AS (
            SELECT game_token, user_token, 
                   COUNT(*) turns, 
                   SUM(enemy_damage) damage_dealt
            FROM lib_server_game
            GROUP BY game_token, user_token
        ),
        game_damage_received AS (
            SELECT game_token, enemy_token user_token, 
                   SUM(enemy_damage) damage_received,
                   CASE WHEN MIN(enemy_health_post) > 0 THEN 1 ELSE 0 END AS win,
                   CASE WHEN MIN(enemy_health_post) = 0 THEN 1 ELSE 0 END AS loss
            FROM lib_server_game
            GROUP BY game_token, enemy_token
        )
        SELECT game_time.year, game_time.month, game_time.day,
               lib_server_lobby.user_token,
               lib_server_lobby.superhero_id,
               lib_server_lobby.game_token,
               game_time.start_time,
               game_time.end_time,
               game_time.time_of_use_seconds,
               IFNULL(game_damage_dealt.turns, 0) turns, 
               IFNULL(game_damage_dealt.damage_dealt, 0) damage_dealt,
               IFNULL(game_damage_received.damage_received, 0) damage_received, 
               IFNULL(game_damage_received.win, 0) win, 
               IFNULL(game_damage_received.loss, 0) loss
        FROM lib_server_lobby
        LEFT JOIN game_time ON
            lib_server_lobby.game_token = game_time.game_token
        LEFT JOIN game_damage_dealt ON
            lib_server_lobby.game_token = game_damage_dealt.game_token AND
            lib_server_lobby.user_token = game_damage_dealt.user_token
        LEFT JOIN game_damage_received ON
            lib_server_lobby.game_token = game_damage_received.game_token AND
            lib_server_lobby.user_token = game_damage_received.user_token
        WHERE NOT game_time.time_of_use_seconds IS NULL
    """)

    rs.createOrReplaceTempView('output__game_metrics')

def _load(sc, blob_prefix='output' if CLOUD_PROVIDER!='AZURE' else ''):
    """
    Loads game metrics to Delta tables in the specified output directory based on the cloud provider.

    This function performs the load stage of the ETL pipeline by loading game metrics data into Delta tables
    located in the specified output directory. The loading process varies based on the cloud provider.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    - blob_prefix (str): The prefix to be appended to the output directory paths (default: 'output' if CLOUD_PROVIDER is not 'AZURE', else '').
    """
    logger.info(f'ETL Pipeline | Load | Loading Game Metrics to Delta Tables in {CLOUD_PROVIDER}')
    df = sc.table('output__game_metrics')
    df.write \
        .format('delta') \
        .partitionBy('year', 'month', 'day') \
        .mode('overwrite') \
        .save(os.path.join(OUTPUT_DIR, blob_prefix, 'game_metrics'))

def entrypoint():
    """
    Entry point for the ETL pipeline.

    This function serves as the entry point for the ETL (Extract, Transform, Load) pipeline.
    It initializes a SparkContext using the configured SparkConfig, performs extraction,
    transformation, and loading stages of the pipeline, and manages the overall execution flow.
    """
    sc = SparkConfig(app_name='output_game_metrics') \
        .get_sparkContext()
    
    _extract(sc)
    _transform(sc)
    _load(sc)

if __name__ == '__main__':
    entrypoint()