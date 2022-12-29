locals {
  tags_zone = {
    "Name"    = "${var.zone_name}"
    "tf-zone" = "${var.zone_name}"
    "tf-ou"   = var.ou_name
  }

  records_normalized = flatten([
    for record in var.records != null ? var.records : [] : [
      {
        zone_id                          = var.set_one_zone_id_all_records != null ? var.set_one_zone_id_all_records : record.zone_id
        name                             = record.name
        type                             = record.type
        ttl                              = record.alias != null ? null : record.ttl != null ? record.ttl : 60
        records                          = record.records
        allow_overwrite                  = record.allow_overwrite
        health_check_id                  = record.health_check_id
        set_identifier                   = record.set_identifier
        multivalue_answer_routing_policy = record.multivalue_answer_routing_policy
        weight_routing_number            = record.weight_routing_number
        failover_routing_type            = record.failover_routing_type
        latency_routing_region           = record.latency_routing_region
        alias                            = record.alias
        geolocation                      = record.geolocation
        has_geolocation                  = (try(record.geolocation.continent, null) != null || try(record.geolocation.country, null) != null || try(record.geolocation.subdivision, null) != null) ? true : false
      }
    ]
  ])
}

#######################################
# Hosted Zone
#######################################
resource "aws_route53_delegation_set" "create_delegation_set" {
  count = (var.make_hosted_zone && var.make_delegation_set) ? 1 : 0

  reference_name = var.delegation_set_name
}

resource "aws_route53_zone" "create_zone" {
  count = var.make_hosted_zone ? 1 : 0

  name              = var.zone_name
  comment           = var.zone_description != null ? var.zone_description : "Zone: ${var.zone_name}"
  force_destroy     = var.zone_force_destroy
  delegation_set_id = try(aws_route53_delegation_set.create_delegation_set[0].id, var.zone_delegation_set_id)
  tags              = merge(var.tags, var.use_tags_default ? local.tags_zone : {})

  dynamic "vpc" {
    for_each = var.zone_vpc_id != null ? [1] : []
    content {
      vpc_id     = var.zone_vpc_id
      vpc_region = var.zone_vpc_region
    }
  }
}

#######################################
# Record Set
#######################################
resource "aws_route53_record" "create_record_route53" {
  count = length(local.records_normalized)

  name                             = local.records_normalized[count.index].name
  type                             = local.records_normalized[count.index].type
  zone_id                          = var.set_one_zone_id_all_records != null ? var.set_one_zone_id_all_records : try(aws_route53_zone.create_zone[0].id, local.records_normalized[count.index].zone_id)
  ttl                              = local.records_normalized[count.index].ttl
  records                          = local.records_normalized[count.index].records
  allow_overwrite                  = local.records_normalized[count.index].allow_overwrite
  health_check_id                  = local.records_normalized[count.index].health_check_id
  set_identifier                   = local.records_normalized[count.index].set_identifier
  multivalue_answer_routing_policy = local.records_normalized[count.index].multivalue_answer_routing_policy

  dynamic "alias" {
    for_each = local.records_normalized[count.index].alias != null ? [1] : []
    content {
      name                   = local.records_normalized[count.index].alias.name
      zone_id                = local.records_normalized[count.index].alias.zone_id
      evaluate_target_health = local.records_normalized[count.index].alias.evaluate_target_health
    }
  }

  dynamic "weighted_routing_policy" {
    for_each = local.records_normalized[count.index].weight_routing_number != null ? [1] : []

    content {
      weight = local.records_normalized[count.index].weight_routing_number
    }
  }

  dynamic "failover_routing_policy" {
    for_each = local.records_normalized[count.index].failover_routing_type != null ? [1] : []

    content {
      type = local.records_normalized[count.index].failover_routing_type
    }
  }

  dynamic "latency_routing_policy" {
    for_each = local.records_normalized[count.index].latency_routing_region != null ? [1] : []

    content {
      region = local.records_normalized[count.index].latency_routing_region
    }
  }

  dynamic "geolocation_routing_policy" {
    for_each = local.records_normalized[count.index].has_geolocation ? [1] : []

    content {
      continent   = local.records_normalized[count.index].geolocation.continent
      country     = local.records_normalized[count.index].geolocation.country
      subdivision = local.records_normalized[count.index].geolocation.subdivision
    }
  }
}
