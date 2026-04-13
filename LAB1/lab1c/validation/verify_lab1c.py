import json
import boto3
from botocore.exceptions import ClientError

# Basic config for the Lab 1C validation checks.
# These values match the rebuilt stack unless renamed later.
REGION = "us-west-2"
PROJECT_NAME = "lab1-redone"

WAF_NAME = f"{PROJECT_NAME}-waf"
ALB_NAME = f"{PROJECT_NAME}-alb"
DASHBOARD_NAME = f"{PROJECT_NAME}-dashboard"

waf = boto3.client("wafv2", region_name=REGION)
elbv2 = boto3.client("elbv2", region_name=REGION)
cloudwatch = boto3.client("cloudwatch", region_name=REGION)

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


# --------------------------------------------------
# Look up the ALB first
# --------------------------------------------------
alb_arn = None

try:
    resp = elbv2.describe_load_balancers(Names=[ALB_NAME])
    lbs = resp.get("LoadBalancers", [])

    if lbs:
        alb = lbs[0]
        alb_arn = alb["LoadBalancerArn"]
        record_result("ALB exists", True, ALB_NAME)
    else:
        record_result("ALB exists", False, f"Load balancer not found: {ALB_NAME}")

except ClientError as e:
    record_result("ALB lookup", False, str(e))


# --------------------------------------------------
# WAF Web ACL validation
# --------------------------------------------------
web_acl_arn = None

try:
    resp = waf.list_web_acls(Scope="REGIONAL")
    web_acls = resp.get("WebACLs", [])

    matched = None
    for acl in web_acls:
        if acl.get("Name") == WAF_NAME:
            matched = acl
            break

    if matched:
        web_acl_arn = matched.get("ARN")
        record_result("WAF Web ACL exists", True, WAF_NAME)
    else:
        record_result("WAF Web ACL exists", False, f"Web ACL not found: {WAF_NAME}")

except ClientError as e:
    record_result("WAF Web ACL lookup", False, str(e))


# --------------------------------------------------
# WAF association to ALB validation
# --------------------------------------------------
if alb_arn:
    try:
        resp = waf.get_web_acl_for_resource(ResourceArn=alb_arn)
        web_acl = resp.get("WebACL")

        if web_acl:
            associated_name = web_acl.get("Name", "Unknown")
            if associated_name == WAF_NAME:
                record_result(
                    "WAF is associated with ALB",
                    True,
                    f"{associated_name} -> {ALB_NAME}"
                )
            else:
                record_result(
                    "WAF is associated with ALB",
                    False,
                    f"Different Web ACL attached: {associated_name}"
                )
        else:
            record_result("WAF is associated with ALB", False, "No Web ACL associated with ALB")

    except ClientError as e:
        record_result("WAF association lookup", False, str(e))


# --------------------------------------------------
# CloudWatch dashboard validation
# --------------------------------------------------
try:
    resp = cloudwatch.get_dashboard(DashboardName=DASHBOARD_NAME)
    dashboard_body = resp.get("DashboardBody", "")

    if dashboard_body:
        record_result("CloudWatch dashboard exists", True, DASHBOARD_NAME)

        try:
            parsed = json.loads(dashboard_body)
            widgets = parsed.get("widgets", [])

            if widgets:
                record_result(
                    "CloudWatch dashboard has widgets",
                    True,
                    f"Widget count: {len(widgets)}"
                )
            else:
                record_result("CloudWatch dashboard has widgets", False, "Dashboard exists but has no widgets")

        except json.JSONDecodeError:
            record_result("CloudWatch dashboard body is valid JSON", False, "Dashboard body could not be parsed")

    else:
        record_result("CloudWatch dashboard exists", False, "Dashboard body empty")

except ClientError as e:
    record_result("CloudWatch dashboard lookup", False, str(e))


# --------------------------------------------------
# Write report
# --------------------------------------------------
output_file = "lab1c_validation.json"

with open(output_file, "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2)

print(f"\nValidation report written to {output_file}")