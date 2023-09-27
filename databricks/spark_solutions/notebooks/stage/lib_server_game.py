# Lib Server Game DLT Pipeline
#
# Pipe Lib Server Game Data to Delta Lake Table

from spark_solutions.common import spark_config

import datetime
import dlt
import os

# ENV Variables
INPUT_DIR = os.getenv('INPUT_DIR')

# COMMAND ----------

@dlt.create_table(
    comment='Datasim Lib Server Game Data',
    table_properties={
        'myCompanyPipeline.quality': 'bronze',
        'pipelines.autoOptimize.managed': 'true'
    },
    partition_cols=['year', 'month', 'day']
)
def stage__lib_server_game(d0=datetime.datetime.today(), d1=datetime.datetime.today() - datetime.timedelta(1)):
    sc = spark_config()
    delta_paths = [
        f'{INPUT_DIR}/stage/lib_server_game/year={d0.year}/month={d0.month:02d}/day={d0.day:02d}',
        f'{INPUT_DIR}/stage/lib_server_game/year={d1.year}/month={d1.month:02d}/day={d1.day:02d}'
    ]
    return (
        sc.read.parquet(*delta_paths)
    )