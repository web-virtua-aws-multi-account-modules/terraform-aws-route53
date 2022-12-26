output "zone" {
  description = "Route53 zone hosted"
  value       = try(aws_route53_zone.create_zone[0], null)
}

output "zone_id" {
  description = "Zone ID zone hosted"
  value       = try(aws_route53_zone.create_zone[0].id, null)
}

output "zone_arn" {
  description = "ARN zone hosted"
  value       = try(aws_route53_zone.create_zone[0].arn, null)
}

output "zone_name_servers" {
  description = "Name servers zone hosted"
  value       = try(aws_route53_zone.create_zone[0].name_servers, null)
}

output "zone_name" {
  description = "Zone name zone hosted"
  value       = try(aws_route53_zone.create_zone[0].name, null)
}

output "delegation_set" {
  description = "Delegation set"
  value       = try(aws_route53_delegation_set.create_delegation_set[0], null)
}

output "delegation_set_id" {
  description = "Delegation set ID"
  value       = try(aws_route53_delegation_set.create_delegation_set[0].id, null)
}

output "delegation_set_arn" {
  description = "Delegation set ARN"
  value       = try(aws_route53_delegation_set.create_delegation_set[0].arn, null)
}

output "records" {
  description = "Records sets"
  value       = try(aws_route53_record.create_record_route53, null)
}

output "records_names" {
  description = "Records sets names"
  value       = try(aws_route53_record.create_record_route53[*].name, null)
}

output "records_fqdn" {
  description = "Records sets fqdn"
  value       = try(aws_route53_record.create_record_route53[*].fqdn, null)
}
