from spark_solutions.common import get_dbutils

import os

#ENV Variables
CLOUD_PROVIDER = os.getenv('CLOUD_PROVIDER', 'AWS')
SERVICE_ACCOUNT_KEY_NAME = os.getenv('SERVICE_ACCOUNT_KEY_NAME', 'databricks-sa-key-name')
SERVICE_ACCOUNT_KEY_SECRET = os.getenv('SERVICE_ACCOUNT_KEY_SECRET', 'databricks-sa-key-secret')

def get_credentials_aws():
    from aws_secretsmanager_caching import SecretCache, SecretCacheConfig

    import botocore 
    import botocore.session
    
    def access_secret(secret_name):
        client = botocore.session \
            .get_session() \
            .create_client('secretsmanager')
        cache_config = SecretCacheConfig()
        cache = SecretCache( config = cache_config, client = client)

        return cache.get_secret_string(secret_name)

    return access_secret(SERVICE_ACCOUNT_KEY_NAME), \
        access_secret(SERVICE_ACCOUNT_KEY_SECRET)

def get_credentials_azure():
    from azure.keyvault.secrets import SecretClient
    from azure.identity import DefaultAzureCredentials
    
    # ENV Variables
    KEY_VAULT_NAME = os.getenv('KEY_VAULT_NAME', None)
    AZURE_TENANT_ID = os.getenv('AZURE_TENANT_ID', None)
    assert(not KEY_VAULT_NAME is None)
    assert(not AZURE_TENANT_ID is None)

    def local_credentials() -> DefaultAzureCredentials:
        """
        Local Azure Credentials

        Function to return local stored Azure Credentials. 
        This is scoped inside a function to reduce the occurrencces of breaks 
        where either Power Shell isn't available or az cli hasn't been installed.

        Ensure that local credentials have been established prior to use
        `az login`
        """
        return DefaultAzureCredentials(
            exclude_environment_credential=True,
            exclude_managed_identity_credentials=True,
            exclude_visual_studio_code_credential=True,
            exclude_shared_token_cache_credential=True
        )
    
    def access_secret(secret_name):
        vault_client = SecretClient(
            vault_url='https://{KEY_VAULT_NAME}.vault.azure.net',
            credentials=local_credentials()
        )

        return vault_client.get_secret(secret_name)
    
    return access_secret(SERVICE_ACCOUNT_KEY_NAME), \
        access_secret(SERVICE_ACCOUNT_KEY_SECRET)

def get_credentials_gcp():
    from google.cloud import secretmanager

    import hashlib

    # ENV Variables
    GOOGLE_PROJECT_ID = os.getenv('GOOGLE_PROJECT_ID', None)
    assert(not GOOGLE_PROJECT_ID is None)

    def access_secret_version(secret_id, version_id="latest"):
        # Create the Secret Manager client.
        client = secretmanager.SecretManagerServiceClient()

        # Build the resource name of the secret version.
        name = f"projects/{GOOGLE_PROJECT_ID}/secrets/{secret_id}/versions/{version_id}"

        # Access the secret version.
        response = client.access_secret_version(name=name)

        # Return the decoded payload.
        return response.payload.data.decode('UTF-8')

    def secret_hash(secret_value): 
        # return the sha224 hash of the secret value
        return hashlib.sha224(bytes(secret_value, "utf-8")).hexdigest()
    
    return secret_hash(access_secret_version(SERVICE_ACCOUNT_KEY_NAME)), \
            secret_hash(access_secret_version(SERVICE_ACCOUNT_KEY_SECRET))

def get_credentials(spark):
    dbutils = get_dbutils(spark)
    if dbutils is None:
        if CLOUD_PROVIDER == 'GCP':
            return get_credentials_gcp()
        elif CLOUD_PROVIDER == 'AZURE':
            return get_credentials_azure()
        
        return get_credentials_aws()
        
    return dbutils.secrets.get(scope='gcp', key=SERVICE_ACCOUNT_KEY_NAME), \
        dbutils.secrets.get(scope='gcp', key=SERVICE_ACCOUNT_KEY_SECRET)