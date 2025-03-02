terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1"
    }
  }
}

# Call an external Python script to retrieve LAPS credentials.
data "external" "laps_credentials" {
  program = ["python3", "${path.module}/get_laps.py"]
  query = {
    devName = "cl01"
  }
}

output "laps_credentials" {
  description = "Retrieved LAPS credentials for the device"
  value       = data.external.laps_credentials.result
  sensitive   = true
}
