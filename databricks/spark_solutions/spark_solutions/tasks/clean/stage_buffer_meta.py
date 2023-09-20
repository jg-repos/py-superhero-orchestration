from spark_solutions.common.spark_config import config_spark_session

import datetime
import os

# ENV Variables
INPUT_DIR = os.getenv('INPUT_DIR', 's3://datasim-superhero-dataflow-standard/standard/buffer_meta')
OUTPUT_DIR = os.getenv('OUTPUT_DIR', 's3://datasim-superhero-dataflow-stage/stage/buffer_meta')

def _extract_tables(sc, d0=datetime.date.today(), d1=datetime.date.today() - datetime.timedelta(1)):
    delta_paths = [
        f'{INPUT_DIR}/{d0.year}/{d0.month}/{d0.day}',
        f'{INPUT_DIR}/{d1.year}/{d1.month}/{d1.day}',
    ]
    data = sc.read.parquet(*delta_paths)
    data.createOrReplaceTempView('buffer_meta')

def _transform_load(sc, d=datetime.date.today()):
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
    rs.write \
        .format('parquet') \
        .partitionBy('year', 'month', 'day') \
        .mode('overwrite') \
        .save(OUTPUT_DIR)

def entrypoint():
    sc = config_spark_session('stage_buffer.meta')
    _extract_tables(sc)
    _transform_load(sc)