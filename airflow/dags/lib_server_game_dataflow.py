from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.utils.trigger_rule import TriggerRule
from airflow.operators.dummy import DummyOperator
from airflow.utils.dates import days_ago
from airflow.decorators import dag, task

import time

default_args = {
    "depends_on_past" : False,
    "start_date"      : days_ago( 0 ),
    "retries"         : 0
}

@dag(
    'lib-server-game-pipeline', 
    default_args= default_args, 
    catchup=False, 
    is_paused_upon_creation=True, 
    schedule_interval= '0 6 * * *')
def raw_etl():
    from airflow_modules import superhero

    def group_key_exists(p):
        @task(task_id='lib.server.game.wait_redis_key')
        def wait_redis_key(p):
            return superhero.wait_redis_key('lib.server.game', p)
        
        return wait_redis_key(p)

    @task(task_id='lib.server.game.message_threshold')
    def message_threshold(partitions):
        return superhero.message_threshold('lib.server.game', partitions)
    
    @task(task_id='lib.server.game.wait_kafka_topic')
    def wait_kafka_topic(message_threshold):
        return superhero.wait_kafka_topic('lib.server.game', message_threshold)

    @task(task_id='lib.server.game.redis_state_change')
    def redis_state_change(partitions_state, elapsed_time=0, timeout_retry=30):
        superhero.publish_redis_message('lib.server.game', '{"message": "start"}')
        
        partition_keys = partitions_state.keys()
        while partitions_state:
            if elapsed_time > timeout_retry:
                superhero.publish_redis_message('lib.server.game', '{"message": "start"}')
                elapsed_time = 0

            for p in partition_keys:
                if p in partitions_state:
                    if partitions_state[p] != superhero.get_redis_key('lib.server.game', p, 'last_offset'):
                        return

            time.sleep(superhero.REDIS_SENSOR_SLEEP)
            elapsed_time += superhero.REDIS_SENSOR_SLEEP

    partitions = superhero.list_partitions(superhero.get_kafka_partitions('lib.server.game'))
    partitions_state = superhero.get_redis_state('lib.server.game', partitions)
    wait_message_threshold = message_threshold(partitions)
    wait_kafka_messages = wait_kafka_topic(wait_message_threshold)
    state_change = redis_state_change(partitions_state)
    repeat_dag = TriggerDagRunOperator(
        task_id='lib.server.game.repeat', 
        trigger_dag_id='lib-server-game-pipeline',
        trigger_rule=TriggerRule.ALL_DONE)
        
    for p in partitions:
        group_key_exists(p) >> wait_message_threshold

    wait_message_threshold >> wait_kafka_messages >> state_change >> repeat_dag
    

raw_dag = raw_etl()