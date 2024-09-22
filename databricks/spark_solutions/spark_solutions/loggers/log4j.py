from spark_solutions.loggers.default import base_handler
from spark_solutions.loggers import log_level
from logging import Handler, LogRecord
from pyspark.sql import SparkSession

import logging
import os

# Environment Variables
LOG_LEVEL=os.getenv('LOG_LEVEL', 'INFO')

class Log4JProxyHandler(Handler):
    """
    Handler to forward messages to log4j.

    This handler forwards log messages to log4j for logging within the Spark context.
    It extends the `Handler` class from the `logging` module.

    Attributes:
    - Logger: The log4j logger obtained from the SparkSession.
    - app_name: The name of the Spark application.

    Methods:
    - __init__(self, spark_session): Initializes the handler with a log4j logger.
    - emit(self, record): Emits a log message.
    - close(self): Closes the logger.
    """

    def __init__(self, spark_session: SparkSession):
        """
        Initialise handler with a log4j logger.

        Parameters:
        - spark_session (SparkSession): The SparkSession object.
        """
        Handler.__init__(self)
        self.Logger = spark_session._jvm.org.apache.log4j.Logger
        self.app_name = spark_session.sparkContext.appName

    def emit(self, record: LogRecord):
        """
        Emit a log message.

        Parameters:
        - record (LogRecord): The log record to be emitted.
        """
        logger = self.Logger.getLogger(record.name)
        if record.levelno >= logging.CRITICAL:
            # Fatal and critical seem about the same.
            logger.fatal(record.getMessage())
        elif record.levelno >= logging.ERROR:
            logger.error(record.getMessage())
        elif record.levelno >= logging.WARNING:
            logger.warn(record.getMessage())
        elif record.levelno >= logging.INFO:
            logger.info(record.getMessage())
        elif record.levelno >= logging.DEBUG:
            logger.debug(record.getMessage())
        else:
            pass

    def close(self):
        """Close the logger."""
        pass

def inject_logging(sc):
    """
    Injects logging configuration into the Py4J logger.

    This function configures logging for the Py4J library within the Spark context.
    It sets up a custom handler (`Log4JProxyHandler`) to forward log messages to log4j.
    Additionally, it sets the logging level for the Py4J logger.

    Parameters:
    - sc (SparkContext): The SparkContext object.
    """
    logger = logging.getLogger('py4j')
    logger.setLevel(log_level(LOG_LEVEL))

    py4j_handler = Log4JProxyHandler(sc)
    py4j_handler.setLevel(log_level(LOG_LEVEL))

    logger.addHandler(base_handler)
    logger.addHandler(py4j_handler)
    logger.propagate = False