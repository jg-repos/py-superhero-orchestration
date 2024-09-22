terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "~> 1.39.0"
      configuration_aliases = [ databricks.workspace ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SPARK VERSION DATA BLOCK
##
## This data block retrieves the latest Long-Term Support (LTS) version of Spark from Databricks.
## 
## Parameters:
## - `long_term_support`: Boolean flag indicating to fetch the latest LTS version.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_spark_version" "latest_lts" {
  provider   = databricks.workspace
  
  long_term_support = true
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS_CLUSTER_POLICY DATA BLOCK
##
## This data block retrieves information about a specific cluster policy from Databricks.
## 
## Parameters:
## - `name`: The name of the cluster policy to retrieve information about.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_cluster_policy" "this" {
  provider = databricks.workspace

  name     = var.cluster_policy_name
}


## ---------------------------------------------------------------------------------------------------------------------
## LOCALS BLOCK
##
## This locals block decodes the JSON definition of a Databricks cluster policy and extracts the autotermination 
## minutes value.
## 
## Parameters:
## - `raw_data`: The decoded JSON data of the Databricks cluster policy.
## - `autotermination_minutes`: The extracted autotermination minutes value from the cluster policy data.
## ---------------------------------------------------------------------------------------------------------------------
locals {
  raw_data                = jsondecode(data.databricks_cluster_policy.this.definition)
  autotermination_minutes = local.raw_data.autotermination_minutes.value
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS CLUSTER RESOURCE
##
## This resource block defines a Databricks cluster.
## 
## Parameters:
## - `cluster_name`: The name of the Databricks cluster.
## - `spark_version`: The ID of the latest LTS Spark version.
## - `instance_pool_id`: The ID of the instance pool for worker nodes.
## - `driver_instance_pool_id`: The ID of the instance pool for the driver node.
## - `policy_id`: The ID of the cluster policy applied to the cluster.
## - `autotermination_minutes`: The auto-termination minutes for the cluster.
## - `min_workers`: The minimum number of worker nodes for autoscaling.
## - `max_workers`: The maximum number of worker nodes for autoscaling.
## - `spark_env_vars`: Environment variables for the Spark configuration.
## - `spark_conf`: Spark configuration variables.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_cluster" "this" {
  provider                = databricks.workspace

  cluster_name            = var.cluster_name
  spark_version           = data.databricks_spark_version.latest_lts.id
  instance_pool_id        = var.node_instance_pool_id
  driver_instance_pool_id = var.driver_instance_pool_id
  policy_id               = var.cluster_policy_id
  autotermination_minutes = local.autotermination_minutes

  autoscale {
    min_workers = var.num_workers_min
    max_workers = var.num_workers_max
  }

  spark_env_vars = var.spark_env_variable
  spark_conf = var.spark_conf_variable
}

resource "databricks_artifact_allowlist" "this" {
  provider = databricks.workspace
  for_each = toset(var.maven_libraries)

  artifact_type = "LIBRARY_MAVEN"
  artifact_matcher {
    artifact   = each.value
    match_type = "PREFIX_MATCH"
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS LIBRARY RESOURCE
##
## This resource block defines a Databricks library.
## 
## Parameters:
## - `cluster_id`: The ID of the Databricks cluster to which the library will be attached.
## - `maven_repo`: The Maven repository for the library.
## - `coordinates`: The Maven coordinates for the library.
## ---------------------------------------------------------------------------------------------------------------------
/*
resource "databricks_library" "this" {
  provider   = databricks.workspace
  depends_on = [ databricks_artifact_allowlist.this ]

  for_each   = toset(var.maven_libraries)

  cluster_id = databricks_cluster.this.id
  maven {
    repo        = var.maven_repo
    coordinates = each.value
  }
}
*/