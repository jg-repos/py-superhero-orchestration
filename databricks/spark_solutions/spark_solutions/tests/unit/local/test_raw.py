import datetime
import pytest
import gzip
import json
import os

def parse_datetime(date_str):
    try:
        return datetime.datetime.strptime(date_str, '%Y-%m-%dT%H:%M:%S.%f')
    except ValueError:
        try:
            return datetime.datetime.strptime(date_str, '%Y-%m-%dT%H:%M:%S')
        except ValueError:
            return datetime.datetime.strptime(date_str, '%Y-%m-%d')


def assert_schema(row, key, obj_type):
    assert key in row
    if row[key]:
        if obj_type.__name__ == 'datetime' and isinstance(row[key], str):
            assert isinstance(parse_datetime(row[key]), datetime.datetime)
        else:
            assert isinstance(row[key], obj_type)

@pytest.mark.raw
@pytest.mark.local
@pytest.mark.table_buffer_meta
def test_raw_buffer_meta():
    INPUT_DIR = os.getenv('INPUT_DIR')
    d0,d1=datetime.date.today(), datetime.date.today() - datetime.timedelta(1)
    drange = [
        f'{INPUT_DIR}/raw/buffer_meta/{d0.year}/{d0.month:02d}/{d0.day:02d}',
        f'{INPUT_DIR}/raw/buffer_meta/{d1.year}/{d1.month:02d}/{d1.day:02d}',
    ]

    for folder in drange:
        file_paths = [os.path.join(folder, f) for f in os.listdir(os.path.join(folder))]
        for zip_contents in file_paths:
            with gzip.open(zip_contents, 'rb') as f:
                data = json.load(f)
                assert isinstance(data, list)

                for row in data:
                    assert_schema(row, 'etl_id', str)
                    assert_schema(row, 'msg_id', str)
                    assert_schema(row, 'checksum', str)
                    assert_schema(row, 'headers', str)
                    assert_schema(row, 'key', str)
                    assert_schema(row, 'offset', int)
                    assert_schema(row, 'partition', int)
                    assert_schema(row, 'serialized_key_size', int)
                    assert_schema(row, 'serialized_value_size', int)
                    assert_schema(row, 'timestamp', datetime.datetime)
                    assert_schema(row, 'timestamp_type', int)
                    assert_schema(row, 'topic', str)
                    assert_schema(row, '_is_protocol', bool)

@pytest.mark.raw
@pytest.mark.local
@pytest.mark.table_etl_meta
def test_raw_etl_meta():
    INPUT_DIR = os.getenv('INPUT_DIR')
    d0,d1=datetime.date.today(), datetime.date.today() - datetime.timedelta(1)
    drange = [
        f'{INPUT_DIR}/raw/etl_meta/{d0.year}/{d0.month:02d}/{d0.day:02d}',
        f'{INPUT_DIR}/raw/etl_meta/{d1.year}/{d1.month:02d}/{d1.day:02d}',
    ]

    for folder in drange:
        file_paths = [os.path.join(folder, f) for f in os.listdir(os.path.join(folder))]
        for zip_contents in file_paths:
            with gzip.open(zip_contents, 'rb') as f:
                data = json.load(f)
                assert isinstance(data, list)

                for row in data:
                    assert_schema(row, 'etl_id', str)
                    assert_schema(row, 'service', str)
                    assert_schema(row, 'mode', str)
                    assert_schema(row, 'timestamp_start', datetime.datetime)
                    assert_schema(row, 'timestamp_end', datetime.datetime)

@pytest.mark.raw
@pytest.mark.local
@pytest.mark.table_log_meta
def test_raw_log_meta():
    INPUT_DIR = os.getenv('INPUT_DIR')
    d0,d1=datetime.date.today(), datetime.date.today() - datetime.timedelta(1)
    drange = [
        f'{INPUT_DIR}/raw/log_meta/{d0.year}/{d0.month:02d}/{d0.day:02d}',
        f'{INPUT_DIR}/raw/log_meta/{d1.year}/{d1.month:02d}/{d1.day:02d}',
    ]

    for folder in drange:
        file_paths = [os.path.join(folder, f) for f in os.listdir(os.path.join(folder))]
        for zip_contents in file_paths:
            with gzip.open(zip_contents, 'rb') as f:
                data = json.load(f)
                assert isinstance(data, list)

                for row in data:
                    assert_schema(row, 'etl_id', str)
                    assert_schema(row, 'msg_id', str)
                    assert_schema(row, 'level', str)
                    assert_schema(row, 'timestamp', datetime.datetime)
                    assert_schema(row, 'name', str)
                    assert_schema(row, 'log_message', str)

@pytest.mark.raw
@pytest.mark.local
@pytest.mark.table_lib_server_game
def test_raw_lib_server_game():
    INPUT_DIR = os.getenv('INPUT_DIR')
    d0,d1=datetime.date.today(), datetime.date.today() - datetime.timedelta(1)
    drange = [
        f'{INPUT_DIR}/raw/lib_server_game/{d0.year}/{d0.month:02d}/{d0.day:02d}',
        f'{INPUT_DIR}/raw/lib_server_game/{d1.year}/{d1.month:02d}/{d1.day:02d}',
    ]

    for folder in drange:
        file_paths = [os.path.join(folder, f) for f in os.listdir(os.path.join(folder))]
        for zip_contents in file_paths:
            with gzip.open(zip_contents, 'rb') as f:
                data = json.load(f)
                assert isinstance(data, list)

                for row in data:
                    assert_schema(row, 'etl_id', str)
                    assert_schema(row, 'msg_id', str)
                    assert_schema(row, 'timestamp', datetime.datetime)
                    assert_schema(row, 'game_token', str)
                    assert_schema(row, 'user_token', str)
                    assert_schema(row, 'action', str)
                    assert_schema(row, 'enemy_token', str)
                    assert_schema(row, 'enemy_damage', int)
                    assert_schema(row, 'enemy_health_prior', int)
                    assert_schema(row, 'enemy_health_post', int)

@pytest.mark.raw
@pytest.mark.local
@pytest.mark.table_lib_server_lobby
def test_raw_lib_server_lobby():
    INPUT_DIR = os.getenv('INPUT_DIR')
    d0,d1=datetime.date.today(), datetime.date.today() - datetime.timedelta(1)
    drange = [
        f'{INPUT_DIR}/raw/lib_server_lobby/{d0.year}/{d0.month:02d}/{d0.day:02d}',
        f'{INPUT_DIR}/raw/lib_server_lobby/{d1.year}/{d1.month:02d}/{d1.day:02d}',
    ]

    for folder in drange:
        file_paths = [os.path.join(folder, f) for f in os.listdir(os.path.join(folder))]
        for zip_contents in file_paths:
            with gzip.open(zip_contents, 'rb') as f:
                data = json.load(f)
                assert isinstance(data, list)

                for row in data:
                    assert_schema(row, 'etl_id', str)
                    assert_schema(row, 'msg_id', str)
                    assert_schema(row, 'game_token', str)
                    assert_schema(row, 'user_token', str)
                    assert_schema(row, 'superhero_id', int)
                    assert_schema(row, 'superhero_attack', int)
                    assert_schema(row, 'superhero_health', int)