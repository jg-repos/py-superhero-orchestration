from pyspark.errors.exceptions import captured

import spark_solutions.common.service_account_credentials as creds
import datetime
import logging
import os

logger = logging.getLogger(f'py4j.{__name__}')

def _read_table(sc, path, format):
    """
    Reads a table from the specified path.

    This function attempts to read a table from the specified path using the given format.
    If the path exists and the table is successfully read, it returns the DataFrame.
    Otherwise, it logs a warning and returns None.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    - path (str): The path from which to read the table.
    - format (str): The format of the table.

    Returns:
    - DataFrame or None: The DataFrame containing the table, or None if the table cannot be read.
    """
    try:
        logger.info(f'Verifying Path Exists: {path}')
        return sc.read.format(format).load(path)
    except captured.AnalysisException as exc:
        logger.warning(f'Reading Table Excpetion {exc}')
        return None

def _extract_tables(sc, path, hot_paths, format):
    """
    Extracts tables from the specified paths and registers them as Spark tables.

    This function iterates over the hot paths, reads tables from each path using the specified format,
    and merges them into a single DataFrame. It then registers this DataFrame as a temporary Spark table.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    - path (str): The base path containing the tables.
    - hot_paths (list): List of paths to extract tables from.
    - format (str): The format of the tables.

    """
    df = None
    for p in hot_paths:
        subset_df = _read_table(sc, p, format)
        if not df and subset_df:
            df = subset_df
        elif subset_df:
            df.union(subset_df)

    if df:
        logger.info(f'Registering Spark Table {os.path.split(path)[-1]}')
        df.createOrReplaceTempView(os.path.split(path)[-1])

def extract_tables(sc, path, d0=datetime.date.today(), d1=datetime.date.today() - datetime.timedelta(1), format='parquet'):
    """
    Extracts non-partitioned tables from the specified path.

    This function extracts non-partitioned tables from the specified path with the given date range.
    It constructs the paths for each day within the date range based on the directory structure.
    The tables are extracted using the _extract_tables function.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    - path (str): The base path containing the non-partitioned tables.
    - d0 (datetime.date): The end date of the date range (default: today's date).
    - d1 (datetime.date): The start date of the date range (default: yesterday's date).
    - format (str): The format of the tables (default: 'parquet').
    """
    logger.info(f'Extracting Non-Partioned Tables from {path}')
    date_range = [d0 + datetime.timedelta(days=x) for x in range(0, (d0-d1).days+1)]
    hot_paths = [f'{path}/{d.year}/{d.month:02d}/{d.day:02d}' for d in date_range]

    _extract_tables(sc, path, hot_paths, format)

def extract_partitioned_tables(sc, path, d0=datetime.date.today(), d1=datetime.date.today() - datetime.timedelta(1), format='delta'):
    """
    Extracts partitioned tables from the specified path.

    This function extracts partitioned tables from the specified path with the given date range.
    It constructs the paths for each day within the date range based on the partitioning scheme.
    The tables are extracted using the _extract_tables function.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    - path (str): The base path containing the partitioned tables.
    - d0 (datetime.date): The end date of the date range (default: today's date).
    - d1 (datetime.date): The start date of the date range (default: yesterday's date).
    - format (str): The format of the tables (default: 'delta').

    """
    logger.info(f'Extracting Partioned Tables from {path}')
    date_range = [d0 + datetime.timedelta(days=x) for x in range(0, (d0-d1).days+1)]
    hot_paths = [f'{path}/year={d.year}/month={d.month:02d}/day={d.day:02d}' for d in date_range]

    _extract_tables(sc, path, hot_paths, format)