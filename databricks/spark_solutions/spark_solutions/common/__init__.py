from pyspark.sql import SparkSession

def get_dbutils(spark: SparkSession):
    try:
        from pyspark.dbutils import DBUtils

        if 'dbutils' not in locals():
            utils = DBUtils(spark)
            return utils
        else:
            return locals().get('dbutils')
    except ImportError:
        return None