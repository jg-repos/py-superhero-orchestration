import logging
import typing
import os

logger = logging.getLogger(f'py4j.{__name__}')

#ENV Variables
CLOUD_PROVIDER = os.getenv('CLOUD_PROVIDER', 'LOCAL')
SERVICE_ACCOUNT_KEY_NAME = os.getenv('SERVICE_ACCOUNT_KEY_NAME', 'databricks-sa-key-name')
SERVICE_ACCOUNT_KEY_SECRET = os.getenv('SERVICE_ACCOUNT_KEY_SECRET', 'databricks-sa-key-secret')

def get_credentials_aws() -> typing.Tuple:
    """Retrieves a secret value from AWS Secrets Manager.

    Returns:
    - Tuple[str, str]: AWS Client ID & Secret
    
    Raises:
    - botocore.exceptions.ClientError: If there is an error accessing the secret.
    """
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

    logger.info('Requesting AWS Credentials for Spark Session')
    return access_secret(SERVICE_ACCOUNT_KEY_NAME), \
        access_secret(SERVICE_ACCOUNT_KEY_SECRET)

def get_credentials_azure():
    """
    Retrieves credentials from Azure Key Vault.

    This function retrieves the credentials required for accessing Azure services
    from Azure Key Vault. It assumes that environment variables for the Key Vault
    name (KEY_VAULT_NAME) and Azure tenant ID (AZURE_TENANT_ID) have been set.

    Returns:
    - Tuple[str, str]: A tuple containing the Azure service account key name and
                       the Azure service account key secret retrieved from Azure Key Vault.

    Raises:
    - AssertionError: If either KEY_VAULT_NAME or AZURE_TENANT_ID environment
                      variables are not set.
    - azure.core.exceptions.ResourceNotFoundError: If the secret is not found in
                                                    the Azure Key Vault.
    - azure.core.exceptions.ClientAuthenticationError: If authentication fails when
                                                        accessing the Azure Key Vault.
    """
    from azure.keyvault.secrets import SecretClient
    from azure.identity import AzureCliCredential
    
    # ENV Variables
    KEY_VAULT_NAME = os.getenv('KEY_VAULT_NAME', None)
    AZURE_TENANT_ID = os.getenv('AZURE_TENANT_ID', None)
    assert(not KEY_VAULT_NAME is None)
    assert(not AZURE_TENANT_ID is None)

    def local_credentials() -> AzureCliCredential:
        """
        Local Azure Credentials

        Function to return local stored Azure Credentials. 
        This is scoped inside a function to reduce the occurrencces of breaks 
        where either Power Shell isn't available or az cli hasn't been installed.

        Ensure that local credentials have been established prior to use
        `az login`

        Returns:
        - AzureCliCredentials: 

        Raises:
        - azure.core.exceptions.ClientAuthenticationError: If authentication fails.
        """
        return AzureCliCredential()
    
    def access_secret(key_vault_name, secret_name):
        """
        Retrieves a secret from Azure Key Vault.

        Parameters:
        - key_vault_name (str): The name of the Azure Key Vault.
        - secret_name (str): The name of the secret to retrieve.

        Returns:
        - str: The value of the secret retrieved from Azure Key Vault.

        Raises:
        - azure.core.exceptions.ResourceNotFoundError: If the secret is not found.
        - azure.core.exceptions.ClientAuthenticationError: If authentication fails.
        """
        vault_client = SecretClient(
            vault_url=f'https://{key_vault_name}.vault.azure.net',
            credential=local_credentials()
        )

        return vault_client.get_secret(secret_name).value
    
    logger.info('Requesting Azure Credentials for Spark Session')    
    return access_secret(KEY_VAULT_NAME, SERVICE_ACCOUNT_KEY_NAME), \
        access_secret(KEY_VAULT_NAME, SERVICE_ACCOUNT_KEY_SECRET)

def get_credentials_gcp():
    """
    Retrieves credentials from Google Cloud Secret Manager.

    This function retrieves the credentials required for accessing Google Cloud Platform services
    from Google Cloud Secret Manager. It assumes that the environment variable for the
    Google Cloud project number (GOOGLE_PROJECT_NUMBER) has been set.

    Returns:
    - Tuple[str, str]: A tuple containing the Google service account key name and
                       the Google service account key secret retrieved from Secret Manager.

    Raises:
    - AssertionError: If GOOGLE_PROJECT_NUMBER environment variable is not set.
    - google.api_core.exceptions.PermissionDenied: If the client does not have permission
                                                     to access the secret.
    - google.api_core.exceptions.NotFound: If the secret or its version is not found.
    - google.api_core.exceptions.ServiceUnavailable: If the service is unavailable.
    """
    from google.cloud import secretmanager

    import hashlib

    # ENV Variables
    GOOGLE_PROJECT_NUMBER = os.getenv('GOOGLE_PROJECT_NUMBER', None)
    assert(not GOOGLE_PROJECT_NUMBER is None)

    def access_secret_version(secret_id, version_id="latest"):
        """
        Retrieves a secret from Google Cloud Secret Manager.

        Parameters:
        - secret_id (str): The ID of the secret to retrieve.
        - version_id (str): The version of the secret to retrieve. Defaults to "latest".

        Returns:
        - str: The value of the secret retrieved from Secret Manager.

        Raises:
        - google.api_core.exceptions.PermissionDenied: If the client does not have permission.
        - google.api_core.exceptions.NotFound: If the secret or its version is not found.
        - google.api_core.exceptions.ServiceUnavailable: If the service is unavailable.
        """
        client = secretmanager.SecretManagerServiceClient()
        name = f"projects/{GOOGLE_PROJECT_NUMBER}/secrets/{secret_id}/versions/{version_id}"
        response = client.access_secret_version(name=name)
        return response.payload.data.decode('UTF-8')
    
    logger.info('Requesting GCP Credentials for Spark Session')
    return access_secret_version(SERVICE_ACCOUNT_KEY_NAME), \
            access_secret_version(SERVICE_ACCOUNT_KEY_SECRET)

def get_credentials_spark_config(sc):
    """
    Retrieves credentials from Spark configuration.

    This function retrieves the credentials required for accessing services
    from the Spark configuration. It assumes that the service account client ID
    and client secret are stored in the Spark configuration using keys corresponding
    to SERVICE_ACCOUNT_KEY_NAME and SERVICE_ACCOUNT_KEY_SECRET, respectively.

    Parameters:
    - sc (SparkContext): The SparkContext object.

    Returns:
    - Tuple[str, str]: A tuple containing the service account client ID and
                       the service account client secret retrieved from Spark configuration.

    """
    # Only to be used for Local Debug Purposes
    logger.info('Extracting Credentials from Spark Config for Spark Session')
    SERVICE_ACCOUNT_CLIENT_ID=sc.conf.get(SERVICE_ACCOUNT_KEY_NAME)
    SERVICE_ACCOUNT_CLIENT_SECRET=sc.conf.get(SERVICE_ACCOUNT_KEY_SECRET)

    return SERVICE_ACCOUNT_CLIENT_ID, SERVICE_ACCOUNT_CLIENT_SECRET

def get_credentials_env():
    """
    Retrieves credentials from environment variables.

    This function retrieves the credentials required for accessing services
    from environment variables. It assumes that the service account client ID
    and client secret are stored in the environment variables SERVICE_ACCOUNT_CLIENT_ID
    and SERVICE_ACCOUNT_CLIENT_SECRET, respectively.

    Returns:
    - Tuple[str, str]: A tuple containing the service account client ID and
                       the service account client secret retrieved from environment variables.

    """
    # Only to be used for Local Debug Purposes
    logger.info('Extracting Credentials from Environment Variables for Spark Session')
    SERVICE_ACCOUNT_CLIENT_ID=os.getenv('SERVICE_ACCOUNT_CLIENT_ID', None)
    SERVICE_ACCOUNT_CLIENT_SECRET=os.getenv('SERVICE_ACCOUNT_CLIENT_SECRET', None)

    return SERVICE_ACCOUNT_CLIENT_ID, SERVICE_ACCOUNT_CLIENT_SECRET

def get_credentials():
    """
    Retrieves credentials based on the specified cloud provider or from environment variables.

    This function retrieves the credentials required for accessing cloud services.
    It first attempts to retrieve the credentials from environment variables. If the
    environment variables are not set, it checks the value of the CLOUD_PROVIDER variable
    and retrieves the credentials accordingly from GCP, Azure, or AWS.

    Returns:
    - Tuple[str, str]: A tuple containing the service account client ID and
                       the service account client secret retrieved based on the specified
                       cloud provider or from environment variables.

    """
    service_account_client, service_account_secret = get_credentials_env()
    if service_account_client and service_account_secret:
        return service_account_client, service_account_secret
    
    if CLOUD_PROVIDER == 'GCP':
        return get_credentials_gcp()
    elif CLOUD_PROVIDER == 'AZURE':
        return get_credentials_azure()
    elif CLOUD_PROVIDER == 'AWS':
        return get_credentials_aws()
        
    return SERVICE_ACCOUNT_KEY_NAME, SERVICE_ACCOUNT_KEY_SECRET
