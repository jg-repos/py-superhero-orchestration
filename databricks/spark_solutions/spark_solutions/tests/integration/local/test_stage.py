from spark_solutions.tasks.stage import lib_server_lobby
from spark_solutions.tasks.stage import lib_server_game
from spark_solutions.tasks.stage import buffer_meta
from spark_solutions.tasks.stage import etl_meta
from spark_solutions.tasks.stage import log_meta

import pytest

@pytest.mark.stage
@pytest.mark.local
@pytest.mark.table_buffer_meta
@pytest.mark.userFixtures('spark')
def test_stage_buffer_meta(spark):
    buffer_meta._extract_tables(spark)
    buffer_meta._transform(spark)

    df = spark.table('stage__buffer_meta')
    assert df.count() > 0

@pytest.mark.stage
@pytest.mark.local
@pytest.mark.table_etl_meta
@pytest.mark.userFixtures('spark')
def test_stage_etl_meta(spark):
    etl_meta._extract_tables(spark)
    etl_meta._transform(spark)

    df = spark.table('stage__etl_meta')
    assert df.count() > 0

@pytest.mark.stage
@pytest.mark.local
@pytest.mark.table_log_meta
@pytest.mark.userFixtures('spark')
def test_stage_log_meta(spark):
    log_meta._extract_tables(spark)
    log_meta._transform(spark)

    df = spark.table('stage__log_meta')
    assert df.count() > 0

@pytest.mark.stage
@pytest.mark.local
@pytest.mark.table_lib_server_game
@pytest.mark.userFixtures('spark')
def test_stage_lib_server_game(spark):
    lib_server_game._extract_tables(spark)
    lib_server_game._transform(spark)

    df = spark.table('stage__lib_server_game')
    assert df.count() > 0

@pytest.mark.stage
@pytest.mark.local
@pytest.mark.table_lib_server_lobby
@pytest.mark.userFixtures('spark')
def test_stage_lib_server_lobby(spark):
    lib_server_lobby._extract_tables(spark)
    lib_server_lobby._transform(spark)

    df = spark.table('stage__lib_server_lobby')
    assert df.count() > 0