
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

# a bucket to hold sources

resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "bucket" {
  name = "${random_id.bucket_prefix.hex}-gcf-source" 
  location = "US"
  uniform_bucket_level_access = true
}

# can't reasonably be an plaintext env
resource "google_secret_manager_secret" "twilio_token" {
  secret_id = "twilio_token"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "twilio_token_version" {
  secret = google_secret_manager_secret.twilio_token.id
  secret_data = var.twilio_token
}

# topic where we will publish received messages

resource "google_pubsub_topic" "messages_received" {
  name = "messages_rcv"
}

resource "google_pubsub_topic" "messages_to_send" {
  name = "messages_snd"
}

# subscription for the worker
resource "google_pubsub_subscription" "messages_rcv_pull_sub" {
  name  = "messages_rcv_pull_sub"
  topic = google_pubsub_topic.messages_received.name

  ack_deadline_seconds = 20
}

# Processes messages on the work queue
module "worker_dev" {
  source = "./modules/python-function"
  entry_point = "work_published"
  function_name = "worker"
  function_description = "Performs some kind of processing on a message"
  function_source_path = "../worker"
  bucket_name = google_storage_bucket.bucket.name
  environment_variables = {
    DESTINATION_TOPIC = google_pubsub_topic.messages_to_send.id
    ADMIN_NUMBER = var.admin_number
  }
  event_trigger = [{
    trigger_region = "us-central1"
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = google_pubsub_topic.messages_received.id
    retry_policy = "RETRY_POLICY_RETRY"
  }]
}

# Receives messages from somewhere on the internet
module "receiver_dev" {
  source = "./modules/python-function"
  entry_point = "text_received"
  function_name = "receiver"
  function_description = "receives texts"
  function_source_path = "../receiver"
  bucket_name = google_storage_bucket.bucket.name
  environment_variables = {
    PUB_SUB_TOPIC = google_pubsub_topic.messages_received.id
  }
  secret_environment_variables = [{
      key        = "TWILIO_TOKEN"
      project_id = var.gcp_project
      secret     = google_secret_manager_secret.twilio_token.secret_id
      version    = "latest"
  }]
  depends_on = [
    google_secret_manager_secret_version.twilio_token_version
  ]
}

# Sends messages to some service
module "sender_dev" {
  source = "./modules/python-function"
  entry_point = "send_message"
  function_name = "sender"
  function_description = "sends texts"
  function_source_path = "../sender"
  bucket_name = google_storage_bucket.bucket.name
  environment_variables = {
    PUB_SUB_TOPIC = google_pubsub_topic.messages_to_send.id
    ACCOUNT_SID = var.twilio_sid
    FROM_NUMBER = var.twilio_number
  }
  secret_environment_variables = [{
      key        = "TWILIO_TOKEN"
      project_id = var.gcp_project
      secret     = google_secret_manager_secret.twilio_token.secret_id
      version    = "latest"
  }]
  event_trigger = [{
    trigger_region = "us-central1"
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = google_pubsub_topic.messages_to_send.id
    retry_policy = "RETRY_POLICY_RETRY"
  }]
  depends_on = [
    google_secret_manager_secret_version.twilio_token_version
  ]
}

# Allow anyone on the internet with access to the endpoint to invoke this function
resource "google_cloud_run_service_iam_binding" "binding" {
  project = var.gcp_project
  location = "us-central1"
  service = module.receiver_dev.function_name
  role = "roles/run.invoker"
  members = [
    "allUsers",
  ]
}

output "receiver_url" {
  value = module.receiver_dev.function_uri
}
