terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1"
    }
  }
}

# Call an external Python script to retrieve AWS IAM user data.
data "external" "iam_users" {
  # This will run the Python script get_iam_users.py (ensure it's in the same directory).
  program = ["python3", "${path.module}/get_iam_users.py"]
  
  # Pass query parameters: a date threshold (60 days ago) and a comma-separated list of properties.
  query = {
    date_threshold = formatdate("2006-01-02T15:04:05Z", timeadd(timestamp(), "-60d"))
    properties     = "UserName,Arn,CreateDate"
  }
}

output "filtered_iam_users" {
  description = "Filtered AWS IAM users as JSON"
  value       = data.external.iam_users.result
}
