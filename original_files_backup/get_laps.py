#!/usr/bin/env python3
import sys
import json
import boto3

def main():
    try:
        # Read input from Terraform (stdin)
        input_data = sys.stdin.read()
        query = json.loads(input_data)
    except Exception as e:
        print(json.dumps({"error": f"Error reading input: {str(e)}"}))
        sys.exit(1)
    
    dev_name = query.get("devName")
    if not dev_name:
        print(json.dumps({"error": "Missing devName in query"}))
        sys.exit(1)
    
    # Define the parameter name in SSM (adjust path as needed)
    parameter_name = f"/LAPS/{dev_name}"
    
    # Create an SSM client
    ssm = boto3.client("ssm")
    
    try:
        response = ssm.get_parameter(
            Name=parameter_name,
            WithDecryption=True
        )
        secret_value = response["Parameter"]["Value"]
    except Exception as e:
        print(json.dumps({"error": f"Error retrieving parameter {parameter_name}: {str(e)}"}))
        sys.exit(1)
    
    # Return the secret value in a JSON object
    result = {"password": secret_value}
    print(json.dumps(result))

if __name__ == "__main__":
    main()
