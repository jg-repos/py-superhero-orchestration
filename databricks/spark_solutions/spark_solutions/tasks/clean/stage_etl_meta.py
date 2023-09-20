from spark_solutions.common.spark_config import config_spark_session

import datetime
import os

# ENV Variables
INPUT_DIR = os.getenv('INPUT_DIR', 's3://datasim-superhero-dataflow-standard/standard/etl_meta')
OUTPUT_DIR = os.getenv('OUTPUT_DIR', 's3://datasim-superhero-dataflow-stage/stage/etl_meta')

def _extract_tables(sc, d0=datetime.date.today(), d1=datetime.date.today() - datetime.timedelta(1)):
    delta_paths = [
        f'{INPUT_DIR}/{d0.year}/{d0.month}/{d0.day}',
        f'{INPUT_DIR}/{d1.year}/{d1.month}/{d1.day}',
    ]
    data = sc.read.parquet(*delta_paths)
    data.createOrReplaceTempView('etl_meta')

def _transform_load(sc, d=datetime.date.today()):
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
    rs.write \
        .format('parquet') \
        .partitionBy('year', 'month', 'day') \
        .mode('overwrite') \
        .save(OUTPUT_DIR)

def entrypoint():
    sc = config_spark_session('stage_etl.meta')
    _extract_tables(sc)
    _transform_load(sc)