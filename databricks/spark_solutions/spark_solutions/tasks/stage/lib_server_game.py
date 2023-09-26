from spark_solutions.common.spark_config import config_spark_session

import datetime
import os

# ENV Variables
CLOUD_PROVIDER = os.getenv('CLOUD_PROVIDER', 'LOCAL')
INPUT_DIR = os.getenv('INPUT_DIR', 's3://datasim-superhero-dataflow-standard/standard/lib.server.game')
OUTPUT_DIR = os.getenv('OUTPUT_DIR', 's3://datasim-superhero-dataflow-stage/stage/lib.server.game')

def _extract_tables(sc, d0=datetime.date.today(), d1=datetime.date.today() - datetime.timedelta(1)):
    delta_paths = [
        f'{INPUT_DIR}/standard/lib_server_game/{d0.year}/{d0.month:02d}/{d0.day:02d}',
        f'{INPUT_DIR}/standard/lib_server_game/{d1.year}/{d1.month:02d}/{d1.day:02d}',
    ]

    if CLOUD_PROVIDER != 'LOCAL':
        data = sc.read.parquet(*delta_paths)
    else:
        data = sc.read.parquet(*[d for d in delta_paths if os.path.isdir(d)])
    
    data.createOrReplaceTempView('lib_server_game')

def _transform(sc):
    rs = sc.sql("""
        WITH unnamed_partitions AS (
            SELECT date_array[0] year, date_array[1] month, date_array[2] day, *
            FROM (
                SELECT SLICE(SPLIT(INPUT_FILE_NAME(), '/'), -4, 3) date_array, *
                FROM lib_server_game
            ) tbl
        )
        SELECT etl_id, msg_id, timestamp, game_token, user_token,
               action, enemy_token, enemy_damage, enemy_health_prior,
               enemy_health_post,
               COUNT(*) distinct_count,
               MIN(year) year,
               MIN(month) month,
               MIN(day) day
        FROM unnamed_partitions
        GROUP BY etl_id, msg_id, timestamp, game_token, user_token,
               action, enemy_token, enemy_damage, enemy_health_prior,
               enemy_health_post
    """)

    rs.createOrReplaceTempView('stage__lib_server_game')

def _load(sc):
    df = sc.table('stage__lib_server_game')
    df.write \
        .format('parquet') \
        .partitionBy('year', 'month', 'day') \
        .mode('overwrite') \
        .save(f'{OUTPUT_DIR}/stage/lib_server_game')

def entrypoint():
    sc = config_spark_session('stage_lib.servery.game')
    _extract_tables(sc)
    _transform(sc)
    _load(sc)

if __name__ == '__main__':
    entrypoint()