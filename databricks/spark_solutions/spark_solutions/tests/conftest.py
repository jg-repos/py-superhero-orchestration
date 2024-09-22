from spark_solutions.common.spark_config import SparkConfig
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
    This class provides a mock implementation for some functionalities of DBUtils commonly used in tests.
    """

    def __init__(self):
        """
        Initializes a new instance of the DBUtilsFixture class.
        """
        self.fs = self
    
    def cp(self, src: str, dest: str, recurse: bool=False):
        """
        Copies a file or directory from the source path to the destination path.

        Parameters:
        - src (str): The source path of the file or directory to copy.
        - dest (str): The destination path where the file or directory will be copied.
        - recurse (bool, optional): If True, copies directories recursively. Defaults to False.
        """
        copy_func = shutil.copytree if recurse else shutil.copy
        copy_func(src, dest)

    def ls(self, path: str):
        """
        Lists files and directories in the specified path.

        Parameters:
        - path (str): The path to list files and directories from.

        Returns:
        - list: A list of FileInfoFixture objects containing information about each file or directory.
        """
        _paths = Path(path).glob('*')
        _objects = [
            FileInfoFixure(str(p.absolute()), p.name, p.stat().st_size, int(p.stat().st_mtime)) for p in _paths
        ]

        return _objects
    
    def mkdirs(self, path:str):
        """
        Creates directories recursively at the specified path.

        Parameters:
        - path (str): The path where directories will be created.
        """
        Path(path).mkdir(parents=True, exists_ok=True)

    def mv(self, path: str, content: str, overwrite: bool=False):
        """
        Moves a file or directory to a new location.

        Parameters:
        - path (str): The path to move the file or directory to.
        - content (str): The content of the file to be moved.
        - overwrite (bool, optional): If True, overwrites the file if it already exists. Defaults to False.
        """
        _f = Path(path)
        if _f.exists() and not overwrite:
            raise FileExistsError('File already exists', path)
        
        _f.write_text(content, encoding='utf-8')
    
    def rm(self, path: str, recurse: bool=False):
        """
        Removes a file or directory at the specified path.

        Parameters:
        - path (str): The path of the file or directory to remove.
        - recurse (bool, optional): If True, removes directories recursively. Defaults to False.
        """
        delete_func = shutil.rmtree if recurse else os.remove
        delete_func(path)

@pytest.fixture(scope='session')
def spark() -> SparkSession:
    """
    Fixture providing a preconfigured SparkSession with Cloud Provider Support.

    Returns:
    - SparkSession: A preconfigured SparkSession object.
    """
    logging.info('Configuring Spark Session for Testing Environment')
    spark = SparkConfig(app_name='spark-solution-unit-test') \
        .get_sparkContext()
    
    logging.info('Spark Session Configured')
    yield spark

    logging.info('Shutting Down Spark Session')
    #spark.stop()

@pytest.fixture(scope='session')
def spark_delta() -> SparkSession:
    """
    Fixture providing a preconfigured SparkSession with Hive and Delta support.
    After the test session, the temporary warehouse directory is deleted.

    Returns:
    - SparkSession: A preconfigured SparkSession object.
    """
    logging.info('Configuring Spark Session for Testing Environment')
    warehouse_dir = tempfile.TemporaryDirectory().name
    spark = SparkConfig(app_name='spark-solution-unit-test', warehouse_dir=warehouse_dir) \
        .get_sparkContext()

    logging.info('Spark Session Configured')
    yield spark

    logging.info('Shutting Down Spark Session')
    #spark.stop()

    if Path(warehouse_dir).exists():
        shutil.rmtree(warehouse_dir)

@pytest.fixture(scope='session', autouse=True)
def dbutils_fixture() -> Iterator[None]:
    """
    Fixture to patch the `get_dbutils` function.
    Please note that the patch is applied on the string name of the function.
    If you change the name or location of it, patching won't work.

    Yields:
    - None: This fixture is used for patching and does not return anything.
    """
    logging.info('Patching the DBUtils object')
    with patch('spark_solutions.common.get_dbutils', lambda _: DBUtilsFixture()):
        yield
    
    logging.info('Test Session Finished - Patching Completed')