data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = var.function_source_path
  output_path = "../dist/${var.function_name}.zip"
  excludes    = [ "__pycache__" ]
}

resource "google_storage_bucket_object" "object" {
  name   = "${var.function_name}-${data.archive_file.function_zip.output_md5}.zip"
  bucket = var.bucket_name
  source = data.archive_file.function_zip.output_path
}

resource "google_cloudfunctions2_function" "function" {
  name = var.function_name
  location = "us-central1"
  description = var.function_description

  build_config {
    runtime = "python310"
    entry_point = var.entry_point
    source {
      storage_source {
        bucket = var.bucket_name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count  = 1
    available_memory    = "256M"
    timeout_seconds     = 60
    environment_variables = var.environment_variables
    dynamic "secret_environment_variables" {
      for_each = var.secret_environment_variables
      content {
        key = secret_environment_variables.value["key"]
        project_id = secret_environment_variables.value["project_id"]
        secret = secret_environment_variables.value["secret"]
        version = secret_environment_variables.value["version"]
      }
    }
  }

  dynamic "event_trigger" {
    for_each = var.event_trigger
    content {
      trigger_region = event_trigger.value["trigger_region"]
      event_type = event_trigger.value["event_type"]
      pubsub_topic = event_trigger.value["pubsub_topic"]
      retry_policy = event_trigger.value["retry_policy"]
    }
  }

}

output "function_uri" {
  value = google_cloudfunctions2_function.function.service_config[0].uri
}

output "function_name" {
  value = google_cloudfunctions2_function.function.name
}






