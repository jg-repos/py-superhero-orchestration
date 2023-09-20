"""
This file configures the Python package with entrypoints used for future runs on Databricks.

Please follow the `entry_points` documentation for more details on how to configure the entrypoint:
* https://setuptools.pypa.io/en/latest/userguide/entry_point.html
"""

from setuptools import find_packages, setup
from spark_solutions import __version__

PACKAGE_REQUIREMENTS = ["pyyaml"]

# packages for local development and unit testing
# please note that these packages are already available in DBR, there is no need to install them on DBR.
LOCAL_REQUIREMENTS = [
    "pyspark==3.2.1",
    "delta-spark==1.1.0",
    "scikit-learn",
    "pandas",
    "mlflow",
]

TEST_REQUIREMENTS = [
    # development & testing tools
    "pytest",
    "coverage[toml]",
    "pytest-cov",
    "dbx>=0.8"
]

setup(
    name="spark_solutions",
    packages=find_packages(exclude=["tests", "tests.*"]),
    setup_requires=["setuptools","wheel"],
    install_requires=PACKAGE_REQUIREMENTS,
    extras_require={"local": LOCAL_REQUIREMENTS, "test": TEST_REQUIREMENTS},
    entry_points = {
        "console_scripts": [
            "stage_buffer_meta = spark_solutions.tasks.clean.stage_buffer_meta:entrypoint"
            "stage_etl_meta = spark_solutions.tasks.clean.stage_etl_meta:entrypoint",
            "stage_log_meta = spark_solutions.tasks.clean.stage_log_meta:entrypoiont",
            "stage_lib_server_game = spark_solutions.tasks.clean.stage_lib_server_game:entrypoint",
            "stage_lib_server_lobby = spark_solutions.tasks.clean.stage_lib_server_lobby:entrypoint",
    ]},
    version=__version__,
    description="Data Simulator Spark ETL Examples",
    author="Jason Grein @ Rethinkr",
)
