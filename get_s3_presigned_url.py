#!/usr/bin/env python3
import sys
import json
import boto3

def main():
    try:
        # Read JSON input from Terraform
        input_data = sys.stdin.read()
        query = json.loads(input_data)
    except Exception as e:
        print(json.dumps({"error": f"Failed to parse input: {str(e)}"}))
        sys.exit(1)

    bucket = query.get("bucket")
    key = query.get("key")
    expiry = int(query.get("expiry", 3600))

    s3 = boto3.client("s3")
    try:
        presigned_url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": bucket, "Key": key},
            ExpiresIn=expiry
        )
    except Exception as e:
        print(json.dumps({"error": f"Failed to generate pre-signed URL: {str(e)}"}))
        sys.exit(1)

    result = {"url": presigned_url}
    print(json.dumps(result))

if __name__ == "__main__":
    main()
