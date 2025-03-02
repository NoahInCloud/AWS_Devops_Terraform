#!/usr/bin/env python3
import sys
import json
import boto3
from dateutil import parser
from datetime import datetime

def main():
    try:
        input_data = sys.stdin.read()
        query = json.loads(input_data)
    except Exception as e:
        print(json.dumps({"error": "Failed to parse input: " + str(e)}))
        sys.exit(1)
    
    client = boto3.client("cloudtrail")
    kwargs = {}
    
    # Process start_time
    if "start_time" in query:
        try:
            start_time = parser.isoparse(query["start_time"])
            kwargs["StartTime"] = start_time
        except Exception as e:
            print(json.dumps({"error": "Invalid start_time: " + str(e)}))
            sys.exit(1)
    
    # Process end_time
    if "end_time" in query:
        try:
            end_time = parser.isoparse(query["end_time"])
            kwargs["EndTime"] = end_time
        except Exception as e:
            print(json.dumps({"error": "Invalid end_time: " + str(e)}))
            sys.exit(1)
    
    # Process max_records
    if "max_records" in query:
        try:
            kwargs["MaxResults"] = int(query["max_records"])
        except Exception as e:
            print(json.dumps({"error": "Invalid max_records: " + str(e)}))
            sys.exit(1)
    
    # Build LookupAttributes based on additional filters
    lookup_attributes = []
    if "caller" in query:
        lookup_attributes.append({
            "AttributeKey": "Username",
            "AttributeValue": query["caller"]
        })
    if "resource_group" in query:
        # AWS CloudTrail does not support resource group filtering directly.
        # As a simulation, we assume events have a ResourceName that matches the resource group.
        lookup_attributes.append({
            "AttributeKey": "ResourceName",
            "AttributeValue": query["resource_group"]
        })
    if "resource_provider" in query:
        lookup_attributes.append({
            "AttributeKey": "EventSource",
            "AttributeValue": query["resource_provider"]
        })
    
    if lookup_attributes:
        kwargs["LookupAttributes"] = lookup_attributes

    # Call CloudTrail LookupEvents API
    try:
        response = client.lookup_events(**kwargs)
        events = response.get("Events", [])
    except Exception as e:
        print(json.dumps({"error": "Failed to lookup events: " + str(e)}))
        sys.exit(1)
    
    result = {"events": events}
    print(json.dumps(result))

if __name__ == "__main__":
    main()
