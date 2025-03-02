terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1"
    }
  }
}

###############################
# Query: Logs from a Specific Start Time to Present
###############################
data "external" "logs_from_start" {
  program = ["python3", "${path.module}/get_cloudtrail_events.py"]
  query = {
    start_time = formatdate("2006-01-02T15:04:05Z", timeadd(timestamp(), "-60d"))
  }
}

###############################
# Query: Logs Between a Specific Time Range
###############################
data "external" "logs_in_range" {
  program = ["python3", "${path.module}/get_cloudtrail_events.py"]
  query = {
    start_time = "2020-08-14T10:30:00Z"
    end_time   = "2020-08-14T11:30:00Z"
  }
}

###############################
# Query: Logs for a Specific "Resource Group"
###############################
# Note: AWS CloudTrail does not have a concept of resource groups.
# For simulation, we assume events related to a particular resource are tagged with a specific ResourceName.
data "external" "rg_logs" {
  program = ["python3", "${path.module}/get_cloudtrail_events.py"]
  query = {
    resource_group = "tw-rg01"
  }
}

###############################
# Query: Logs for a Specific Resource Provider
###############################
# Here we filter by the EventSource attribute (e.g. "elasticloadbalancing.amazonaws.com")
data "external" "provider_logs" {
  program = ["python3", "${path.module}/get_cloudtrail_events.py"]
  query = {
    resource_provider = "elasticloadbalancing.amazonaws.com"
    start_time        = "2020-08-14T10:30:00Z"
    end_time          = "2020-08-14T11:30:00Z"
  }
}

###############################
# Query: Logs with a Specific Caller
###############################
data "external" "caller_logs" {
  program = ["python3", "${path.module}/get_cloudtrail_events.py"]
  query = {
    caller      = "Noah@example.io"
    max_records = "10"
  }
}

###############################
# Query: Last 10 Activity Log Events
###############################
data "external" "last_10" {
  program = ["python3", "${path.module}/get_cloudtrail_events.py"]
  query = {
    max_records = "10"
  }
}

###############################
# Outputs
###############################
output "logs_from_start" {
  description = "Log entries from 60 days ago to present"
  value       = data.external.logs_from_start.result.events
}

output "logs_in_range" {
  description = "Log entries from 2020-08-14T10:30:00Z to 2020-08-14T11:30:00Z"
  value       = data.external.logs_in_range.result.events
}

output "resource_group_logs" {
  description = "Log entries for events matching resource group 'tw-rg01'"
  value       = data.external.rg_logs.result.events
}

output "provider_logs" {
  description = "Log entries for provider 'elasticloadbalancing.amazonaws.com' between 2020-08-14T10:30:00Z and 2020-08-14T11:30:00Z"
  value       = data.external.provider_logs.result.events
}

output "caller_logs" {
  description = "Last 10 log entries with caller 'Noah@example.io'"
  value       = data.external.caller_logs.result.events
}

output "last_10_logs" {
  description = "The last 10 CloudTrail events"
  value       = data.external.last_10.result.events
}
