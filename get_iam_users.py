#!/usr/bin/env python3
import sys
import json
import boto3
from datetime import datetime, timezone

def main():
    try:
        # Read JSON input from Terraform
        input_data = sys.stdin.read()
        query = json.loads(input_data)
    except Exception as e:
        print(json.dumps({"error": f"Failed to parse input: {str(e)}"}))
        sys.exit(1)
    
    # Retrieve query parameters
    date_threshold_str = query.get("date_threshold")
    properties_str = query.get("properties", "UserName,Arn,CreateDate")
    properties = [p.strip() for p in properties_str.split(",")]

    try:
        # Parse the date threshold in the format provided (e.g., 2006-01-02T15:04:05Z)
        date_threshold = datetime.strptime(date_threshold_str, "%Y-%m-%dT%H:%M:%SZ")
        date_threshold = date_threshold.replace(tzinfo=timezone.utc)
    except Exception as e:
        print(json.dumps({"error": f"Invalid date_threshold format: {str(e)}"}))
        sys.exit(1)
    
    iam = boto3.client("iam")
    filtered_users = []

    # Use a paginator to iterate over all IAM users
    paginator = iam.get_paginator("list_users")
    for page in paginator.paginate():
        for user in page.get("Users", []):
            # Filter based on the CreateDate
            if user.get("CreateDate") and user["CreateDate"] > date_threshold:
                # Build a dictionary with only the requested properties
                filtered_user = {}
                for prop in properties:
                    value = user.get(prop)
                    if isinstance(value, datetime):
                        value = value.isoformat()
                    filtered_user[prop] = value
                filtered_users.append(filtered_user)
    
    result = {"users": filtered_users}
    print(json.dumps(result))

if __name__ == "__main__":
    main()
