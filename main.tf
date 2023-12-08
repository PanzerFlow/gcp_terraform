
terraform {
  # Here we configure the providers we need to run our configuration
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.51.0"
    }
  }

  # With this backend configuration we are telling Terraform that the
  # created state should be saved in some Google Cloud Bucket with some prefix
  backend "gcs" {
    ## INSERT YOUR BUCKET HERE!!
    bucket = "panzerflow01-state"
    prefix = "terraform/state"
    credentials = "terraform-sa.json"
  }
}

# Define the "google" provider with the project and the general region + zone
provider "google" {
  credentials = file("terraform-sa.json")
  project = "panzerflow01"
  region = "us-east1"
  zone = "us-east1-b"
}
provider "google-beta" {
  credentials = file("terraform-sa.json")
  project = "panzerflow01"
  region = "us-east1"
  zone = "us-east1-b"
}

# Enable the Compute Engine API
resource "google_project_service" "compute" {
  ## INSERT YOUR PROJECT ID HERE!!
  project = "panzerflow01"
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

# Enable the Cloud Resource Manager API
resource "google_project_service" "cloudresourcemanager" {
  ## INSERT YOUR PROJECT ID HERE!!
  project = "panzerflow01"
  service = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

# Enable the Cloud Storage API
resource "google_project_service" "storage_api" {
  provider = google-beta
  project = "panzerflow01"
  service = "storage.googleapis.com"
  disable_on_destroy = false
}

# Enable the Cloud Composer API
resource "google_project_service" "composer_api" {
  provider = google-beta
  project = "panzerflow01"
  service = "composer.googleapis.com"
  disable_on_destroy = false
}

# Enable the Cloud Composer API
resource "google_project_service" "artifactregistry_api" {
  provider = google-beta
  project = "panzerflow01"
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Creating a bucket to be used for data processing
resource "google_storage_bucket" "datalake" {
  name = "panzerflow01-data-lake"
  location = "US"
  storage_class = "STANDARD"
  force_destroy = true

  depends_on = [google_project_service.storage_api]
}

# Creating a bigquery dataset to be used for data processing
resource "google_bigquery_dataset" "bq_set" {
  dataset_id                  = "panzerflow01_bq_set"
  friendly_name               = "bq_set"
  description                 = "This is the data set we will use for dbt and spark testing"
  location                    = "US"
}

# Creating a docker registery to store images that will be used in airflow k8s pods
resource "google_artifact_registry_repository" "registry" {
  provider = google-beta
  location      = "us-east1"
  repository_id = "panzerflow01-registry"
  description   = "Docker registry to store the airflow task images"
  format        = "DOCKER"

  depends_on = [google_project_service.artifactregistry_api]
}

# resource "google_composer_environment" "composer" {
#   provider = google-beta
#   name   = "example-composer-env"
#   region = "us-east1"

#   config {

#     software_config {
#       image_version = "composer-2.5.2-airflow-2.6.3"
#     }

#     workloads_config {
#       scheduler {
#         cpu        = 0.5
#         memory_gb  = 1.875
#         storage_gb = 1
#         count      = 1
#       }
#       web_server {
#         cpu        = 0.5
#         memory_gb  = 1.875
#         storage_gb = 1
#       }
#       worker {
#         cpu = 0.5
#         memory_gb  = 1.875
#         storage_gb = 1
#         min_count  = 1
#         max_count  = 3
#       }
#     }
#   environment_size = "ENVIRONMENT_SIZE_SMALL"
#   }
# depends_on = [google_project_service.composer_api]
# }