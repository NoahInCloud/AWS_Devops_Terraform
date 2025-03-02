#!/usr/bin/env python3
import sys
import json
import subprocess
import io
import csv

def main():
    try:
        # Read the JSON query from Terraform (stdin)
        input_data = sys.stdin.read()
        query = json.loads(input_data)
    except Exception as e:
        print(json.dumps({"error": f"Failed to parse input: {str(e)}"}))
        sys.exit(1)

    # Extract parameters from the input
    subscription_id = query.get("subscription_id")
    resource_group  = query.get("resource_group")

    if not subscription_id or not resource_group:
        print(json.dumps({"error": "Missing subscription_id or resource_group in query"}))
        sys.exit(1)

    try:
        # Use Azure CLI to list VMs in the specified resource group and subscription
        cmd = [
            "az", "vm", "list",
            "--resource-group", resource_group,
            "--subscription", subscription_id,
            "--output", "json"
        ]
        cli_output = subprocess.check_output(cmd, universal_newlines=True)
        vm_list = json.loads(cli_output)
    except Exception as e:
        print(json.dumps({"error": f"Failed to retrieve VM list via Azure CLI: {str(e)}"}))
        sys.exit(1)

    # Prepare CSV report
    output_csv = io.StringIO()
    writer = csv.writer(output_csv)
    # Write header row
    writer.writerow(["Name", "Location", "ResourceGroup", "VMId"])
    for vm in vm_list:
        name = vm.get("name", "")
        location = vm.get("location", "")
        rg = vm.get("resourceGroup", "")
        vm_id = vm.get("id", "")
        writer.writerow([name, location, rg, vm_id])

    csv_content = output_csv.getvalue()

    # Return the CSV report as a JSON object with a key "csv"
    result = {"csv": csv_content}
    print(json.dumps(result))

if __name__ == "__main__":
    main()
