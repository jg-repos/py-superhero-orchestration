## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  type        = string
  description = "Databricks Cluster Name"
}

variable "node_instance_pool_id" {
  type        = string
  description = "Databricks Node Instace Pool ID"
}

variable "driver_instance_pool_id" {
  type        = string
  description = "Databricks Driver Instace Pool ID"
}

variable "cluster_policy_name" {
  type        = string
  description = "Databricks Cluster Policy Name"
}

variable "cluster_policy_id" {
  type        = string
  description = "Databricks Cluster Policy ID"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "spark_env_variable" {
  type        = map(string)
  description = "Databricks CLuster Spark Environment Variables"
  default     = {}
}

variable "spark_conf_variable" {
  type        = map(string)
  description = "Databricks Cluster Spark Conf Parameters"
  default     = {}
}

variable "num_workers_min" {
  type        = number
  description = "Databricks Cluster Autoscale workers minimum"
  default     = 1
}

variable "num_workers_max" {
  type        = number
  description = "Databricks Cluster Autoscale workers maximum"
  default     = 1
}

variable "maven_repo" {
  type        = string
  description = "Maven Library Repo"
  default     = "https://maven-central.storage-download.googleapis.com/maven2/"
}

variable "maven_libraries" {
  type        = list(string)
  description = "Maven JAR Library to be installed on Databricks Cluster"
  default     = [
    "org.apache.hadoop:hadoop-aws:3.3.4",
    "com.amazonaws:aws-java-sdk:1.12.552",
    "org.apache.hadoop:hadoop-azure-datalake:3.3.3",
    "org.apache.hadoop:hadoop-common:3.3.3",
    "org.apache.hadoop:hadoop-azure:3.3.3"
  ]
}