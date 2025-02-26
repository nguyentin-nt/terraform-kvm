import csv
import json
import sys

csv_file = "kvm_vm.csv"
vms = []

with open(csv_file, "r") as file:
    reader = csv.DictReader(file)
    for row in reader:
        vms.append({
            "vm_name": row["vm_name"],
            "ip_address": row["ip_address"],
            "hostname": row["hostname"],
            "app_type": row["app_type"]
        })

# Encode danh sách VM thành một chuỗi JSON
output = {
    "vms": json.dumps(vms)  # Chuyển đổi list thành JSON string
}

print(json.dumps(output))
sys.exit(0)