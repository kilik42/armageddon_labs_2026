
# Output the Transit Gateway ID so we can reference it in the secondary region for peering.
output "tgw_id" {
  description = "Transit Gateway ID for the logical primary region"
  value       = aws_ec2_transit_gateway.lab3_tgw.id
}

# The TGW attachment ID for the primary VPC is needed in the secondary region to create the peering attachment, so we output it here.
output "peering_attachment_id" {
  description = "TGW peering attachment ID from primary to Sao Paulo"
  value       = aws_ec2_transit_gateway_peering_attachment.to_saopaulo.id
}