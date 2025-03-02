#!/usr/bin/env python3
import sys
import json
import os
from azure.storage.blob import BlobServiceClient

def main():
    # Read JSON input from Terraform (stdin)
    try:
        input_data = sys.stdin.read()
        query = json.loads(input_data)
    except Exception as e:
        print(json.dumps({"error": f"Failed to read input: {str(e)}"}))
        sys.exit(1)

    # Extract parameters (resource_group is provided but not used directly)
    resource_group  = query.get("resource_group")
    storage_account = query.get("storage_account")
    container       = query.get("container")

    # Get connection string from environment variable
    connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
    if not connection_string:
        print(json.dumps({"error": "Environment variable AZURE_STORAGE_CONNECTION_STRING is not set."}))
        sys.exit(1)

    try:
        # Create the BlobServiceClient using the connection string
        blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        container_client = blob_service_client.get_container_client(container)
    except Exception as e:
        print(json.dumps({"error": f"Failed to connect to Azure Blob Storage: {str(e)}"}))
        sys.exit(1)

    # Initialize list and total size counter
    blobs = []
    total_size = 0

    try:
        # List all blobs in the container and sum their sizes
        for blob in container_client.list_blobs():
            size = blob.size if blob.size else 0
            blobs.append({
                "name": blob.name,
                "size": size
            })
            total_size += size
    except Exception as e:
        print(json.dumps({"error": f"Failed to list blobs: {str(e)}"}))
        sys.exit(1)

    # Prepare the result
    result = {
        "blobs": blobs,
        "total_size": total_size
    }

    # Output the result as JSON
    print(json.dumps(result))

if __name__ == "__main__":
    main()
