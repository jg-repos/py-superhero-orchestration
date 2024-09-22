import logging
import pytest
import os

logger = logging.getLogger(f'py4j.{__name__}')

#ENV Variables
CLOUD_PROVIDER=os.getenv('CLOUD_PROVIDER', 'LOCAL')

@pytest.mark.output
@pytest.mark.usefixtures('spark')
def test_output_message_flow(spark):
    """
    Test case for verifying the output message flow.

    This test case extracts and transforms the message flow data using the `_extract` and `_transform` functions
    from the `message_flow` module. It then checks if the resulting DataFrame contains at least one row.

    Raises:
    - AssertionError: If the DataFrame count is not greater than 0.
    """
    from spark_solutions.tasks.output import message_flow

    message_flow._extract(spark)
    message_flow._transform(spark)

    df = spark.table('output__message_flow')
    assert df.count() > 0

@pytest.mark.output
@pytest.mark.usefixtures('spark')
def test_output_game_metrics(spark):
    """
    Test case for verifying the output game metrics.

    This test case extracts and transforms the game metrics data using the `_extract` and `_transform` functions
    from the `game_metrics` module. It then checks if the resulting DataFrame contains at least one row.

    Raises:
    - AssertionError: If the DataFrame count is not greater than 0.
    """
    from spark_solutions.tasks.output import game_metrics

    game_metrics._extract(spark)
    game_metrics._transform(spark)

    df = spark.table('output__game_metrics')
    assert df.count() > 0
