from spark_solutions.common.spark_config import config_spark_session
from pyspark.sql import SparkSession
from dataclasses import dataclass
from unittest.mock import patch
from typing import Iterator
from pathlib import Path

import tempfile
import logging
import shutil
import pytest
import sys
import os

def is_debugging():
    return 'debugpy' in sys.modules
    
# enable stop_on_exception is the debugger is running during a test
if is_debugging():
    @pytest.hookimpl(tryfirst=True)
    def pytest_exception_interact(call):
        raise call.excinfo.value
    
    @pytest.hookimpl(tryfirst=True)
    def pytest_internalerror(excinfo):
        raise excinfo.value
    
@dataclass
class FileInfoFixure:
    """
    This class mocks the DBUtils FileInfo object
    """

    path: str
    name: str
    size: int
    modificationTime: int


class DBUtilsFixture:
    """
    This class is used for mocking the behaviour of DBUtils inside tests.
    """

    def __init__(self):
        self.fs = self
    
    def cp(self, src: str, dest: str, recurse: bool=False):
        copy_func = shutil.copytree if recurse else shutil.copy
        copy_func(src, dest)

    def ls(self, path: str):
        _paths = Path(path).glob('*')
        _objects = [
            FileInfoFixure(str(p.absolute()), p.name, p.stat().st_size, int(p.stat().st_mtime)) for p in _paths
        ]

        return _objects
    
    def mkdirs(self, path:str):
        Path(path).mkdir(parents=True, exists_ok=True)

    def mv(self, path: str, content: str, overwrite: bool=False):
        _f = Path(path)
        if _f.exists() and not overwrite:
            raise FileExistsError('File already exists', path)
        
        _f.write_text(content, encoding='utf-8')
    
    def rm(self, path: str, recurse: bool=False):
        delete_func = shutil.rmtree if recurse else os.remove
        delete_func(path)

@pytest.fixture(scope='session')
def spark() -> SparkSession:
    """
    This fixture provides a preconfigured SparkSession with Cloud Provider Support
    
    :return: SparkSession
    """
    logging.info('Configuring Spark Session for Testing Environment')
    spark = config_spark_session('spark-solution-unit-test')
    
    logging.info('Spark Session Configured')
    yield spark

    logging.info('Shutting Down Spark Session')
    spark.stop()

@pytest.fixture(scope='session')
def spark_delta() -> SparkSession:
    """
    This fixture provides a preconfigured SparkSession with Hive and Delta support.
    After the test session, temporary warehouse directory is deleted

    :return: SparkSession
    """
    logging.info('Configuring Spark Session for Testing Environment')
    warehouse_dir = tempfile.TemporaryDirectory().name
    spark = config_spark_session('spark-solution-unit-test', warehouse_dir)

    logging.info('Spark Session Configured')
    yield spark

    logging.info('Shutting Down Spark Session')
    spark.stop()

    if Path(warehouse_dir).exists():
        shutil.rmtree(warehouse_dir)

@pytest.fixture(scope='session', autouse=True)
def dbutils_fixture() -> Iterator[None]:
    """
    This fixture patches the `get_dbutils` function.
    Please note that patch is applied on a string name of the function.
    If you change the name or location of it, patching won't work.

    :return:
    """
    logging.info('Patching the DBUtils object')
    with patch('spark_solutions.common.get_dbutils', lambda _: DBUtilsFixture()):
        yield
    
    logging.info('Test Session Finished - Patching Completed')