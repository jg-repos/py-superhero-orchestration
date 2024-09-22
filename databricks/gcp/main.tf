terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "1.25.0"
    }
  }
}

terraform {
  backend "gcs" {}
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROVIDER
##
## This configures the Google provider with an alias for token generation.
##
## Alias:
## - `tokengen`: Alias for the Google provider.
## ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  alias = "tokengen"
}


## ---------------------------------------------------------------------------------------------------------------------
## RANDOM STRING RESOURCE
##
## This resource generates a random string of a specified length.
##
## Parameters:
## - `special`: Whether to include special characters in the random string.
## - `upper`: Whether to include uppercase letters in the random string.
## - `length`: The length of the random string.
## ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "this" {
  special = false
  upper   = false
  length  = 4
}

locals {
  cloud   = "gcp"
  program = "spark-databricks"
  project = "datasim"
}

locals  {
  secret_scope        = var.databricks_secret_scope != null ? var.databricks_secret_scope : "${upper(local.cloud)}"
  prefix              = var.resource_prefix != null ? var.resource_prefix : "${local.program}-${local.project}-${random_string.this.id}"
  iam_roles = distinct(concat(var.gcp_iam_bootstrap, [
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountKeyAdmin",
    "roles/iam.roleAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/compute.networkAdmin",
    "roles/compute.storageAdmin",
    "roles/container.admin",
    "roles/storage.objectAdmin",
    "roles/storage.admin",
    "roles/secretmanager.admin",
  ]))

  maven_libraries = distinct(concat(var.databricks_cluster_libraries, []))

  tags    = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}


## ---------------------------------------------------------------------------------------------------------------------
## SERVICE ACCOUNT AUTHENTICATION MODULE
##
## The Service Account Auth Module will authenticate with GCP using
## the Impersonate Service Account Mode to request Access Tokens, and
## create new short-live Service Accounts
##
## Parameters:
## - `project_id`: The ID of the GCP project.
## - `impersonate_service_account_email`: Email of the service account to impersonate.
## - `impersonate_user_email`: Email of the user to impersonate.
## - `new_service_account_name`: Name of the new service account to create.
## - `new_service_account_description`: Description for the new service account.
## - `bootstrap_project_iam_roles`: IAM roles to assign to the service account.
##
## Providers:
## - `google.tokengen`: The Google provider for generating tokens.
## ---------------------------------------------------------------------------------------------------------------------
module "service_account_auth" {
  source                            = "github.com/rethinkr-hub/py-superhero-dataflow.git//batch/serverless_functions/gcp/modules/service_account_auth"
  project_id                        = var.project_id
  impersonate_service_account_email = var.impersonate_service_account_email
  impersonate_user_email            = var.impersonate_user_email
  new_service_account_name          = "${local.prefix}-service-account"
  new_service_account_description   = "${local.prefix} Service Account to Manage Databricks by Terraform"
  bootstrap_project_iam_roles       = local.iam_roles

  providers = {
    google.tokengen = google.tokengen
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GCP WORKSPACE MODULE
##
## This module sets up a Databricks workspace on Google Cloud Platform (GCP).
##
## Parameters:
## - `databricks_account_id`: The ID of the Databricks account.
## - `gcp_project_id`: The ID of the GCP project.
## - `gcp_access_token`: Access token for authenticating with GCP.
## - `gcp_region`: The region where the Databricks workspace will be located in GCP.
##
## Providers:
## - None
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_gcp_workspace" {
  source                = "../modules/gcp_workspace"
  databricks_account_id = var.databricks_account_id
  gcp_project_id        = var.gcp_project_id
  gcp_access_token      = module.service_account_auth.access_token
  gcp_region            = var.gcp_region
  gcp_impersonate_user_email = var.impersonate_user_email
}


provider "databricks" {
  alias                  = "workspace"
  host                   = module.databricks_gcp_workspace.databricks_host
  google_service_account = module.databricks_gcp_workspace.databricks_service_account
  account_id             = var.databricks_account_id
}

module "databricks_admin_user" {
  source = "../modules/databricks_user"
  depends_on = [ module.databricks_gcp_workspace ]

  user_name = var.impersonate_user_email

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_secret_scope" {
  source       = "../modules/databricks_secret_scope"
  depends_on   = [ module.databricks_gcp_workspace ]

  secret_scope = "GCP" #CLOUD_PROVIDER ENV Variable in spark_solutions.common.service_account_credentials.py
  
  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_service_account_key_name_secret" {
  source          = "../modules/databricks_secret"
  depends_on      = [ module.databricks_gcp_workspace ]

  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  secret_name     = "databricks-sa-key-name"
  secret_data     = module.databricks_gcp_workspace.gcp_databricks_service_account_key_name
  
  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_service_account_key_data_secret" {
  source          = "../modules/databricks_secret"
  depends_on      = [ module.databricks_gcp_workspace ]

  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  secret_name     = "databricks-sa-key-secret"
  secret_data     = module.databricks_gcp_workspace.gcp_databricks_service_account_key_secret

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_repo" {
  source       = "../modules/databricks_repo"
  depends_on   = [ module.databricks_gcp_workspace ]

  git_url      = var.git_url
  git_username = var.git_username
  git_pat      = var.git_pat

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_group_engineer" {
  source               = "../modules/databricks_group"

  group_name           = "datasim-engineers-group"
  allow_cluster_create = true
}

module "databricks_cluster_policy" {
  source     = "../modules/databricks_cluster_policy"
  depends_on = [ module.databricks_group_engineer ]

  group_name = module.databricks_group_engineer.databricks_group_name

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_instance_pool_driver" {
  source                     = "../modules/databricks_instace_pool"
  depends_on                 = [ module.databricks_gcp_workspace ]

  instance_pool_name         = "datasim-driver-node"
  instance_pool_max_capacity = 1

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_instance_pool_dev" {
  source                     = "../modules/databricks_instace_pool"
  depends_on                 = [ module.databricks_gcp_workspace ]

  instance_pool_name         = "datasim-engineer-cluster-dev"
  instance_pool_max_capacity = 2

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_instance_pool_prod" {
  source                     = "../modules/databricks_instace_pool"
  depends_on                 = [ module.databricks_gcp_workspace ]

  instance_pool_name         = "datasim-engineer-cluster-prod"
  node_min_memory_gb         = 8
  node_min_cores             = 4
  instance_pool_max_capacity = 2

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_pipeline_stage_buffer_meta" {
  source                  = "../modules/databricks_pipeline"
  depends_on              = [ 
    module.databricks_instance_pool_dev,
    module.databricks_instance_pool_driver,
    module.databricks_cluster_policy,
    module.databricks_repo 
  ]

  pipeline_name           = "stage_buffer_dlt_pipeline"
  instance_pool_id        = module.databricks_instance_pool_dev.instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool_driver.instance_pool_id
  cluster_policy_id       = module.databricks_cluster_policy.cluster_policy_id
  repo_notebook_path      = "${module.databricks_repo.repo_path}//databricks/spark_solutions/notebooks/stage/buffer_meta.py"
  notification_recipients = var.notification_recipients

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_job_stage_buffer_meta" {
  source                  = "../modules/databricks_job"
  depends_on              = [ 
    module.databricks_instance_pool_dev,
    module.databricks_instance_pool_driver,
    module.databricks_cluster_policy,
    module.databricks_pipeline_stage_buffer_meta 
  ]

  instance_pool_id        = module.databricks_instance_pool_dev.instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool_driver.instance_pool_id
  cluster_policy_id       = module.databricks_cluster_policy.cluster_policy_id
  job_name                = "stage_buffer_meta_job"
  job_tasks               = [
    {
      task_key          = "stage_buffer_meta_spark_etl",
      pipeline_task     = [],
      depends_on        = [],
      python_wheel_task = [
        {
          package_name = "spark_solutions",
          entry_point  = "stage_buffer_meta"
        }
      ]
    },
    {
      task_key          = "stage_buffer_meta_dlt_pipeline",
      python_wheel_task = [],
      pipeline_task     = [
        {
          pipeline_id = module.databricks_pipeline_stage_buffer_meta.pipeline_id
        }
      ],
      depends_on        = [
        {
          task_key = "stage_buffer_meta_spark_etl"
        }
      ]
    }
  ]

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_pipeline_stage_etl_meta" {
  source                  = "../modules/databricks_pipeline"
  depends_on              = [ 
    module.databricks_instance_pool_dev,
    module.databricks_instance_pool_driver,
    module.databricks_cluster_policy,
    module.databricks_repo 
  ]

  pipeline_name           = "stage_etl_dlt_pipeline"
  instance_pool_id        = module.databricks_instance_pool_dev.instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool_driver.instance_pool_id
  cluster_policy_id       = module.databricks_cluster_policy.cluster_policy_id
  repo_notebook_path      = "${module.databricks_repo.repo_path}//databricks/spark_solutions/notebooks/stage/etl_meta.py"
  notification_recipients = var.notification_recipients

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_job_stage_etl_meta" {
  source                  = "../modules/databricks_job"
  depends_on              = [ 
    module.databricks_instance_pool_dev,
    module.databricks_instance_pool_driver,
    module.databricks_cluster_policy,
    module.databricks_pipeline_stage_etl_meta 
  ]

  instance_pool_id        = module.databricks_instance_pool_dev.instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool_driver.instance_pool_id
  cluster_policy_id       = module.databricks_cluster_policy.cluster_policy_id
  job_name                = "stage_etl_meta_job"
  job_tasks               = [
    {
      task_key          = "stage_etl_meta_spark_etl",
      pipeline_task     = [],
      depends_on        = [],
      python_wheel_task = [
        {
          package_name = "spark_solutions",
          entry_point  = "stage_etl_meta"
        }
      ]
    },
    {
      task_key          = "stage_etl_meta_dlt_pipeline",
      python_wheel_task = [],
      pipeline_task     = [
        {
          pipeline_id = module.databricks_pipeline_stage_etl_meta.pipeline_id
        }
      ],
      depends_on = [
        {
          task_key = "stage_etl_meta_spark_etl"
        }
      ]
    }
  ]

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_pipeline_stage_log_meta" {
  source                  = "../modules/databricks_pipeline"
  depends_on              = [ 
    module.databricks_instance_pool_dev,
    module.databricks_instance_pool_driver,
    module.databricks_cluster_policy,
    module.databricks_repo 
  ]

  pipeline_name           = "stage_log_dlt_pipeline"
  instance_pool_id        = module.databricks_instance_pool_dev.instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool_driver.instance_pool_id
  cluster_policy_id       = module.databricks_cluster_policy.cluster_policy_id
  repo_notebook_path      = "${module.databricks_repo.repo_path}//databricks/spark_solutions/notebooks/stage/log_meta.py"
  notification_recipients = var.notification_recipients

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_job_stage_log_meta" {
  source                  = "../modules/databricks_job"
  depends_on              = [ 
    module.databricks_instance_pool_dev,
    module.databricks_instance_pool_driver,
    module.databricks_cluster_policy,
    module.databricks_pipeline_stage_log_meta 
  ]

  instance_pool_id        = module.databricks_instance_pool_dev.instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool_driver.instance_pool_id
  cluster_policy_id       = module.databricks_cluster_policy.cluster_policy_id
  job_name                = "stage_log_meta_job"
  job_tasks               = [
    {
      task_key          = "stage_log_meta_spark_etl",
      pipeline_task     = [],
      depends_on        = [],
      python_wheel_task = [
        {
          package_name = "spark_solutions",
          entry_point  = "stage_log_meta"
        }
      ]
    },
    {
      task_key          = "stage_log_meta_dlt_pipeline",
      python_wheel_task = [],
      pipeline_task     = [
        {
          pipeline_id = module.databricks_pipeline_stage_log_meta.pipeline_id
        }
      ],
      depends_on        = [
        {
          task_key = "stage_log_meta_spark_etl"
        }
      ]
    }
  ]

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_pipeline_stage_lib_server_game" {
  source                  = "../modules/databricks_pipeline"
  depends_on              = [ 
    module.databricks_instance_pool_dev,
    module.databricks_instance_pool_driver,
    module.databricks_cluster_policy,
    module.databricks_repo 
  ]

  pipeline_name           = "stage_lib_server_game_dlt_pipeline"
  instance_pool_id        = module.databricks_instance_pool_dev.instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool_driver.instance_pool_id
  cluster_policy_id       = module.databricks_cluster_policy.cluster_policy_id
  repo_notebook_path      = "${module.databricks_repo.repo_path}//databricks/spark_solutions/notebooks/stage/lib_server_game.py"
  notification_recipients = var.notification_recipients

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_job_stage_lib_server_game" {
  source                  = "../modules/databricks_job"
  depends_on              = [ 
    module.databricks_instance_pool_dev,
    module.databricks_instance_pool_driver,
    module.databricks_cluster_policy,
    module.databricks_pipeline_stage_lib_server_game 
  ]

  instance_pool_id        = module.databricks_instance_pool_dev.instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool_driver.instance_pool_id
  cluster_policy_id       = module.databricks_cluster_policy.cluster_policy_id
  job_name                = "stage_lib_server_game_job"
  job_tasks               = [
    {
      task_key          = "stage_lib_server_game_spark_etl",
      pipeline_task     = [],
      depends_on        = [],
      python_wheel_task = [
        {
          package_name = "spark_solutions",
          entry_point  = "stage_lib_server_game"
        }
      ]
    },
    {
      task_key          = "stage_lib_server_game_dlt_pipeline",
      python_wheel_task = [],
      pipeline_task     = [
        {
          pipeline_id = module.databricks_pipeline_stage_lib_server_game.pipeline_id
        }
      ],
      depends_on        = [
        {
          task_key = "stage_lib_server_game_spark_etl"
        }
      ]
    }
  ]

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_pipeline_stage_lib_server_lobby" {
  source                  = "../modules/databricks_pipeline"
  depends_on              = [ 
    module.databricks_instance_pool_dev,
    module.databricks_instance_pool_driver,
    module.databricks_cluster_policy,
    module.databricks_repo 
  ]

  pipeline_name           = "stage_lib_server_lobby_dlt_pipeline"
  instance_pool_id        = module.databricks_instance_pool_dev.instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool_driver.instance_pool_id
  cluster_policy_id       = module.databricks_cluster_policy.cluster_policy_id
  repo_notebook_path      = "${module.databricks_repo.repo_path}//databricks/spark_solutions/notebooks/stage/lib_server_lobby.py"
  notification_recipients = var.notification_recipients

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_job_stage_lib_server_lobby" {
  source                  = "../modules/databricks_job"
  depends_on              = [ 
    module.databricks_instance_pool_dev,
    module.databricks_instance_pool_driver,
    module.databricks_cluster_policy,
    module.databricks_pipeline_stage_lib_server_lobby 
  ]

  instance_pool_id        = module.databricks_instance_pool_dev.instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool_driver.instance_pool_id
  cluster_policy_id       = module.databricks_cluster_policy.cluster_policy_id
  job_name                = "stage_lib_server_lobby_job"
  job_tasks               = [
    {
      task_key          = "stage_lib_server_lobby_spark_etl",
      pipeline_task     = [],
      depends_on        = [],
      python_wheel_task = [
        {
          package_name = "spark_solutions",
          entry_point  = "stage_lib_server_lobby"
        }
      ]
    },
    {
      task_key          = "stage_lib_server_lobby_dlt_pipeline",
      python_wheel_task = [],
      pipeline_task     = [
        {
          pipeline_id = module.databricks_pipeline_stage_lib_server_lobby.pipeline_id
        }
      ],
      depends_on        = [
        {
          task_key = "stage_lib_server_lobby_spark_etl"
        }
      ]
    }
  ]

  providers = {
    databricks.workspace = databricks.workspace
  }
}