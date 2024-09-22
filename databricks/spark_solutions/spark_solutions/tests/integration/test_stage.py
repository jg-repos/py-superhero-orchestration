import logging
import pytest
import os

logger = logging.getLogger(f'py4j.{__name__}')

#ENV Variables
CLOUD_PROVIDER=os.getenv('CLOUD_PROVIDER', 'LOCAL')
INPUT_DIR = os.getenv('STANDARD_DIR')

@pytest.mark.stage
@pytest.mark.usefixtures('spark')
def test_stage_buffer_meta(spark):
    """
    Test case for verifying the staging of buffer metadata.

    This test case extracts and transforms the buffer metadata using the `extract_tables` and `_transform` functions
    from the `buffer_meta` module. It then checks if the resulting DataFrame contains at least one row.

    Raises:
    - AssertionError: If the DataFrame count is not greater than 0.
    """
    from spark_solutions.tasks.stage import buffer_meta

    # ENV Variables
    INPUT_DIR = os.getenv('STANDARD_DIR')
    assert(not INPUT_DIR is None)

    if CLOUD_PROVIDER != 'AZURE':
        buffer_meta.extract_tables(spark, os.path.join(INPUT_DIR, 'standard/buffer_meta'))
    else:
        buffer_meta.extract_tables(spark, os.path.join(INPUT_DIR, 'buffer_meta'))

    buffer_meta._transform(spark)

    df = spark.table('stage__buffer_meta')
    assert df.count() > 0

@pytest.mark.stage
@pytest.mark.usefixtures('spark')
def test_stage_etl_meta(spark):
    """
    Test case for verifying the staging of ETL metadata.

    This test case extracts and transforms the ETL metadata using the `extract_tables` and `_transform` functions
    from the `etl_meta` module. It then checks if the resulting DataFrame contains at least one row.

    Raises:
    - AssertionError: If the DataFrame count is not greater than 0.
    """
    from spark_solutions.tasks.stage import etl_meta

    # ENV Variables
    INPUT_DIR = os.getenv('STANDARD_DIR')
    assert(not INPUT_DIR is None)

    if CLOUD_PROVIDER != 'AZURE':
        etl_meta.extract_tables(spark, os.path.join(INPUT_DIR, 'standard/etl_meta'))
    else:
        etl_meta.extract_tables(spark, os.path.join(INPUT_DIR, 'etl_meta'))

    etl_meta._transform(spark)

    df = spark.table('stage__etl_meta')
    assert df.count() > 0

@pytest.mark.stage
@pytest.mark.usefixtures('spark')
def test_stage_log_meta(spark):
    """
    Test case for verifying the staging of log metadata.

    This test case extracts and transforms the log metadata using the `extract_tables` and `_transform` functions
    from the `log_meta` module. It then checks if the resulting DataFrame contains at least one row.

    Raises:
    - AssertionError: If the DataFrame count is not greater than 0.
    """
    from spark_solutions.tasks.stage import log_meta

    # ENV Variables
    INPUT_DIR = os.getenv('STANDARD_DIR')
    assert(not INPUT_DIR is None)

    if CLOUD_PROVIDER != 'AZURE':
        log_meta.extract_tables(spark, os.path.join(INPUT_DIR, 'standard/log_meta'))
    else:
        log_meta.extract_tables(spark, os.path.join(INPUT_DIR, 'log_meta'))

    log_meta._transform(spark)

    df = spark.table('stage__log_meta')
    assert df.count() > 0

@pytest.mark.stage
@pytest.mark.usefixtures('spark')
def test_stage_lib_server_game(spark):
    """
    Test case for verifying the staging of server game data.

    This test case extracts and transforms the server game data using the `extract_tables` and `_transform` functions
    from the `lib_server_game` module. It then checks if the resulting DataFrame contains at least one row.

    Raises:
    - AssertionError: If the DataFrame count is not greater than 0.
    """
    from spark_solutions.tasks.stage import lib_server_game

    # ENV Variables
    INPUT_DIR = os.getenv('STANDARD_DIR')
    assert(not INPUT_DIR is None)

    if CLOUD_PROVIDER != 'AZURE':
        lib_server_game.extract_tables(spark, os.path.join(INPUT_DIR, 'standard/lib_server_game'))
    else:
        lib_server_game.extract_tables(spark, os.path.join(INPUT_DIR, 'lib_server_game'))

    lib_server_game._transform(spark)

    df = spark.table('stage__lib_server_game')
    assert df.count() > 0

@pytest.mark.stage
@pytest.mark.usefixtures('spark')
def test_stage_lib_server_lobby(spark):
    """
    Test case for verifying the staging of server lobby data.

    This test case extracts and transforms the server lobby data using the `extract_tables` and `_transform` functions
    from the `lib_server_lobby` module. It then checks if the resulting DataFrame contains at least one row.

    Raises:
    - AssertionError: If the DataFrame count is not greater than 0.
    """
    from spark_solutions.tasks.stage import lib_server_lobby

    # ENV Variables
    INPUT_DIR = os.getenv('STANDARD_DIR')
    assert(not INPUT_DIR is None)

    if CLOUD_PROVIDER != 'AZURE':
        lib_server_lobby.extract_tables(spark, os.path.join(INPUT_DIR, 'standard/lib_server_lobby'))
    else:
        lib_server_lobby.extract_tables(spark, os.path.join(INPUT_DIR, 'lib_server_lobby'))

    lib_server_lobby._transform(spark)

    df = spark.table('stage__lib_server_lobby')
    assert df.count() > 0
