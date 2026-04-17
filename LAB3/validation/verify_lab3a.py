import json
import boto3
from botocore.exceptions import ClientError

# LAB3A validation checks the multi-region TGW backbone.
# Primary side = logical Tokyo / data-authority side in us-west-2
# Secondary side = Sao Paulo compute side in sa-east-1

PRIMARY_REGION = "us-west-2"
SECONDARY_REGION = "sa-east-1"

PRIMARY_TGW_NAME = "lab3-tokyo-tgw"
SECONDARY_TGW_NAME = "lab3-saopaulo-tgw"

# Update this if your actual primary VPC CIDR is different.
PRIMARY_VPC_CIDR = "10.10.0.0/16"
SAOPAULO_VPC_CIDR = "10.30.0.0/16"

ec2_primary = boto3.client("ec2", region_name=PRIMARY_REGION)
ec2_secondary = boto3.client("ec2", region_name=SECONDARY_REGION)

results = []


def record_result(name: str, passed: bool, details: str = "") -> None:
    status = "PASS" if passed else "FAIL"
    print(f"{status}: {name}")
    if details:
        print(f"      {details}")

    results.append({
        "check": name,
        "passed": passed,
        "details": details
    })


def safe_tags_to_dict(resource: dict) -> dict:
    return {tag["Key"]: tag["Value"] for tag in resource.get("Tags", [])}


def find_tgw_by_name(client, expected_name: str):
    try:
        resp = client.describe_transit_gateways()
        for tgw in resp.get("TransitGateways", []):
            tags = safe_tags_to_dict(tgw)
            if tags.get("Name") == expected_name:
                return tgw
    except ClientError as e:
        record_result(f"Transit Gateway lookup failed: {expected_name}", False, str(e))
    return None


def find_default_tgw_route_table(client, tgw_id: str):
    try:
        resp = client.describe_transit_gateway_route_tables(
            Filters=[
                {"Name": "transit-gateway-id", "Values": [tgw_id]},
                {"Name": "default-association-route-table", "Values": ["true"]}
            ]
        )
        route_tables = resp.get("TransitGatewayRouteTables", [])
        return route_tables[0] if route_tables else None
    except ClientError as e:
        record_result(f"Default TGW route table lookup failed for {tgw_id}", False, str(e))
        return None


def find_vpc_attachment_for_tgw(client, tgw_id: str):
    try:
        resp = client.describe_transit_gateway_vpc_attachments(
            Filters=[
                {"Name": "transit-gateway-id", "Values": [tgw_id]}
            ]
        )
        attachments = resp.get("TransitGatewayVpcAttachments", [])
        return attachments[0] if attachments else None
    except ClientError as e:
        record_result(f"VPC attachment lookup failed for {tgw_id}", False, str(e))
        return None


def find_peering_attachment(primary_client, primary_tgw_id: str, secondary_region: str):
    try:
        resp = primary_client.describe_transit_gateway_peering_attachments(
            Filters=[
                {"Name": "transit-gateway-id", "Values": [primary_tgw_id]}
            ]
        )
        for att in resp.get("TransitGatewayPeeringAttachments", []):
            requester_region = att.get("RequesterTgwInfo", {}).get("Region")
            accepter_region = att.get("AccepterTgwInfo", {}).get("Region")

            if requester_region == PRIMARY_REGION and accepter_region == secondary_region:
                return att
    except ClientError as e:
        record_result("TGW peering attachment lookup failed", False, str(e))
    return None


def find_exact_tgw_route(client, route_table_id: str, cidr: str):
    try:
        resp = client.search_transit_gateway_routes(
            TransitGatewayRouteTableId=route_table_id,
            Filters=[
                {"Name": "route-search.exact-match", "Values": [cidr]}
            ]
        )
        routes = resp.get("Routes", [])
        return routes[0] if routes else None
    except ClientError as e:
        record_result(f"TGW route lookup failed for {cidr}", False, str(e))
        return None


def get_route_attachment_id(route: dict) -> str:
    attachments = route.get("TransitGatewayAttachments", [])
    if attachments:
        return attachments[0].get("TransitGatewayAttachmentId", "attachment-unknown")
    return "attachment-unknown"


# --------------------------------------------------
# Primary TGW
# --------------------------------------------------
primary_tgw = find_tgw_by_name(ec2_primary, PRIMARY_TGW_NAME)

if primary_tgw:
    primary_tgw_id = primary_tgw["TransitGatewayId"]
    record_result("Primary TGW exists", True, primary_tgw_id)

    primary_rt = find_default_tgw_route_table(ec2_primary, primary_tgw_id)
    if primary_rt:
        primary_tgw_rt_id = primary_rt["TransitGatewayRouteTableId"]
        record_result("Primary TGW default route table exists", True, primary_tgw_rt_id)
    else:
        primary_tgw_rt_id = None
        record_result("Primary TGW default route table exists", False, "No default association route table found")
else:
    primary_tgw_id = None
    primary_tgw_rt_id = None
    record_result("Primary TGW exists", False, f"Name tag not found: {PRIMARY_TGW_NAME}")


# --------------------------------------------------
# Secondary TGW
# --------------------------------------------------
secondary_tgw = find_tgw_by_name(ec2_secondary, SECONDARY_TGW_NAME)

if secondary_tgw:
    secondary_tgw_id = secondary_tgw["TransitGatewayId"]
    record_result("Secondary TGW exists", True, secondary_tgw_id)

    secondary_rt = find_default_tgw_route_table(ec2_secondary, secondary_tgw_id)
    if secondary_rt:
        secondary_tgw_rt_id = secondary_rt["TransitGatewayRouteTableId"]
        record_result("Secondary TGW default route table exists", True, secondary_tgw_rt_id)
    else:
        secondary_tgw_rt_id = None
        record_result("Secondary TGW default route table exists", False, "No default association route table found")
else:
    secondary_tgw_id = None
    secondary_tgw_rt_id = None
    record_result("Secondary TGW exists", False, f"Name tag not found: {SECONDARY_TGW_NAME}")


# --------------------------------------------------
# Primary VPC Attachment
# --------------------------------------------------
if primary_tgw_id:
    primary_attachment = find_vpc_attachment_for_tgw(ec2_primary, primary_tgw_id)
    if primary_attachment:
        record_result(
            "Primary VPC attachment exists",
            True,
            f'{primary_attachment["TransitGatewayAttachmentId"]} ({primary_attachment["State"]})'
        )
    else:
        record_result("Primary VPC attachment exists", False, "No primary VPC attachment found")


# --------------------------------------------------
# Secondary VPC Attachment
# --------------------------------------------------
if secondary_tgw_id:
    secondary_attachment = find_vpc_attachment_for_tgw(ec2_secondary, secondary_tgw_id)
    if secondary_attachment:
        record_result(
            "Secondary VPC attachment exists",
            True,
            f'{secondary_attachment["TransitGatewayAttachmentId"]} ({secondary_attachment["State"]})'
        )
    else:
        record_result("Secondary VPC attachment exists", False, "No secondary VPC attachment found")


# --------------------------------------------------
# TGW Peering
# --------------------------------------------------
if primary_tgw_id:
    peering = find_peering_attachment(ec2_primary, primary_tgw_id, SECONDARY_REGION)
    if peering:
        peering_id = peering["TransitGatewayAttachmentId"]
        peering_state = peering["State"]

        record_result("TGW peering attachment exists", True, peering_id)
        record_result(
            "TGW peering attachment state is available",
            peering_state == "available",
            peering_state
        )
    else:
        peering_id = None
        record_result("TGW peering attachment exists", False, "No primary-to-secondary peering attachment found")
else:
    peering_id = None


# --------------------------------------------------
# Primary route to Sao Paulo
# --------------------------------------------------
if primary_tgw_rt_id:
    primary_route = find_exact_tgw_route(ec2_primary, primary_tgw_rt_id, SAOPAULO_VPC_CIDR)
    if primary_route:
        record_result(
            "Primary TGW route to Sao Paulo exists",
            True,
            f'{SAOPAULO_VPC_CIDR} -> {get_route_attachment_id(primary_route)}'
        )
    else:
        record_result("Primary TGW route to Sao Paulo exists", False, SAOPAULO_VPC_CIDR)


# --------------------------------------------------
# Secondary route to Primary
# --------------------------------------------------
if secondary_tgw_rt_id:
    secondary_route = find_exact_tgw_route(ec2_secondary, secondary_tgw_rt_id, PRIMARY_VPC_CIDR)
    if secondary_route:
        record_result(
            "Secondary TGW route to Primary exists",
            True,
            f'{PRIMARY_VPC_CIDR} -> {get_route_attachment_id(secondary_route)}'
        )
    else:
        record_result("Secondary TGW route to Primary exists", False, PRIMARY_VPC_CIDR)


# --------------------------------------------------
# Write report
# --------------------------------------------------
output_file = "lab3a_validation.json"

with open(output_file, "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2)

print(f"\nValidation report written to {output_file}")