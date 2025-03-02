provider "aws" {
  region = "eu-west-1"  # Equivalent to Azure's "westeurope"
}

provider "local" {}

###############################
# Variables & Random Suffix
###############################
variable "location" {
  default = "eu-west-1"
}

resource "random_string" "storage_suffix" {
  length  = 4
  upper   = false
  special = false
}

###############################
# S3 Bucket (simulate Azure Storage Account)
###############################
resource "aws_s3_bucket" "storage" {
  bucket = "mystorageacct${random_string.storage_suffix.result}"
  acl    = "private"

  tags = {
    Environment = "Test"
  }
}

###############################
# Create Local File with Current Timestamp
###############################
resource "local_file" "sample_upload" {
  filename = "C:/Temp/SampleUpload.txt"   # Adjust path as needed
  content  = timestamp()
}

###############################
# Upload the File to "File Share" 1 and Directory (simulate using S3 object key prefix)
###############################
resource "aws_s3_object" "uploaded_file" {
  bucket = aws_s3_bucket.storage.bucket
  key    = "share1/myDirectory/SampleUpload.txt"
  source = local_file.sample_upload.filename
  etag   = filemd5(local_file.sample_upload.filename)
}

###############################
# Simulate File Copy: Upload the Same File to "File Share" 2 and Directory
###############################
resource "aws_s3_object" "copied_file" {
  bucket = aws_s3_bucket.storage.bucket
  key    = "share2/myDirectory2/SampleCopy.txt"
  source = local_file.sample_upload.filename
  etag   = filemd5(local_file.sample_upload.filename)
}

###############################
# Outputs
###############################
output "uploaded_file_id" {
  description = "S3 object key for the uploaded file (simulating the Azure file share upload)"
  value       = aws_s3_object.uploaded_file.key
}

output "copied_file_id" {
  description = "S3 object key for the copied file (simulating the Azure file share copy)"
  value       = aws_s3_object.copied_file.key
}
