# AWS Route53 for multiples accounts and regions with Terraform module
* This module simplifies creating and configuring of the Route53 across multiple accounts and regions on AWS

* Is possible use this module with one region using the standard profile or multi account and regions using multiple profiles setting in the modules.

## Actions necessary to use this module:

* Create file versions.tf with the exemple code below:
```hcl
terraform {
  required_version = ">= 1.1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.9"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
  }
}
```

* Criate file provider.tf with the exemple code below:
```hcl
provider "aws" {
  alias   = "alias_profile_a"
  region  = "us-east-1"
  profile = "my-profile"
}

provider "aws" {
  alias   = "alias_profile_b"
  region  = "us-east-2"
  profile = "my-profile"
}
```


## Features enable of Route53 configurations for this module:

- Route53 hosted zone
- Records sets
- Delegation set

## Usage exemples


### Create Route53 with a new hosted zone without records

```hcl
module "hosted_zone_test" {
  source           = "web-virtua-aws-multi-account-modules/route53/aws"
  make_hosted_zone = true
  zone_name        = "test.com"
  zone_description = "Zone to test creation of hosted zone without records"

  providers = {
    aws = aws.alias_profile_b
  }
}
```

### Create Route53 with a new hosted zone with records

```hcl
module "hosted_zone_test" {
  source           = "web-virtua-aws-multi-account-modules/route53/aws"
  make_hosted_zone = true
  zone_name        = "test.com"
  zone_description = "Zone to test creation of hosted zone with records"
  records          = var.records

  providers = {
    aws = aws.alias_profile_b
  }
}
```

### Create records with a hosted zone existing to geolocation records, in this case will be use one zone id for all records set

```hcl
module "hosted_zone_test_geolocation" {
  source                      = "web-virtua-aws-multi-account-modules/route53/aws"
  set_one_zone_id_all_records = var.zone_id_existing

  records = [
    {
      name           = "geolocation"
      type           = "A"
      set_identifier = "geo-us"
      records = [
        "203.0.113.200"
      ]
      "geolocation" = {
        "country" = "US"
      }
    },
    {
      name           = "geolocation"
      type           = "A"
      set_identifier = "geo-eu"
      records = [
        "203.0.113.200"
      ]
      "geolocation" = {
        "continent" = "EU"
      }
    },
  ]

  providers = {
    aws = aws.alias_profile_a
  }
}
```

### Create records with a hosted zone foreach failover records, in this case will can be use one zone id foreach record set or the same

```hcl
module "hosted_zone_test_failover" {
  source = "web-virtua-aws-multi-account-modules/route53/aws"

  records = [
    {
      name                  = "failover"
      type                  = "A"
      failover_routing_type = "PRIMARY"
      set_identifier        = "primary"
      health_check_id       = aws_route53_health_check.failover_primary.id
      zone_id               = var.zone_id_existing_a
      records = [
        "203.0.113.200"
      ]
    },
    {
      name                  = "failover"
      type                  = "A"
      failover_routing_type = "SECONDARY"
      set_identifier        = "secondary"
      zone_id               = var.zone_id_existing_b
      records = [
        "203.0.113.202"
      ]
    },
  ]

  providers = {
    aws = aws.alias_profile_a
  }
}
```

### Create records with a hosted zone existing to alias records, in this case will be use one zone id for all records set

```hcl
module "hosted_zone_test_simple_alias" {
  source                      = "web-virtua-aws-multi-account-modules/route53/aws"
  set_one_zone_id_all_records = var.zone_id_existing

  records = [
    {
      name = "alias-simple"
      type = "A"
      alias = {
        name                   = aws_elb.simple_alias.dns_name
        zone_id                = aws_elb.simple_alias.zone_id
        evaluate_target_health = true
      }
    },
  ]

  providers = {
    aws = aws.alias_profile_a
  }
}
```

## Variables

| Name | Type | Default | Required | Description | Options |
|------|-------------|------|---------|:--------:|:--------|
| make_hosted_zone | `bool` | `false` | no | If true will be create one hosted zone | `*`false <br> `*`true |
| make_delegation_set | `bool` | `false` | no | If true will be create one delegation set | `*`false <br> `*`true |
| delegation_set_name | `string` | `null` | no | Name to delegation set, if defined will be attached on hosted zone | `-` |
| zone_name | `string` | `null` | no | Name to zone | `-` |
| zone_description | `string` | `null` | no | Comment for the hosted zone | `-` |
| zone_force_destroy | `bool` | `false` | no | Destroy all records when delete zone | `*`false <br> `*`true |
| zone_delegation_set_id | `string` | `null` | no | The ID of the reusable delegation set whose NS records you want to assign to the hosted zone. Conflicts with the vpc | `-` |
| zone_vpc_id | `string` | `null` | no | Can be used to associate with a private hosted zone. Conflicts with the delegation_set_id | `-` |
| zone_vpc_region | `string` | `null` | no | Region of the VPC to associate. Defaults to AWS provider region | `-` |
| use_tags_default | `bool` | `true` | no | If true will be use the tags default to hosted zone | `*`false <br> `*`true |
| ou_name | `string` | `no` | no | Organization unit name | `-` |
| tags | `map(any)` | `{}` | no | Tags to Route53 hosted zone | `-` |
| set_one_zone_id_all_records | `string` | `null` | no | This variable set foreach record in item list to one hosted zone, if set set_one_zone_id_all_records variable all records will set this zone id | `-` |
| records | `list(object)` | `null` | no | This variable setup each list item to one or many hosted zone, if set set_one_zone_id_all_records variable then all records will set this zone id else each record on list will receive the zone id in zone_id variable, in this configuration every list item will can have one hosted zone different | `-` |

* Model of variable records, above a exemple of a list with simple record of type A and CNAME, weight and latency
```hcl
variable "records" {
  description = "Define the records configurations for one zone hosted"
  type = list(object({
    zone_id                          = optional(string, null)       # if don't create a new hosted zone or not set set_one_zone_id_all_records will be necessery set this
    name                             = string
    type                             = string                       # Valid values are A, AAAA, CAA, CNAME, DS, MX, NAPTR, NS, PTR, SOA, SPF, SRV and TXT
    ttl                              = optional(number, null)       # It's required if don't has alias records configuration
    records                          = optional(list(string), null)
    allow_overwrite                  = optional(bool, false)        # Allow creation of this record in Terraform to overwrite an existing record
    health_check_id                  = optional(string, null)
    set_identifier                   = optional(string, null)       # It's only used when configured with failover, geolocation, latency, multivalue_answer, or weighted
    multivalue_answer_routing_policy = optional(bool, null)         # Set to true to indicate a multivalue answer routing policy. Conflicts with any other routing policy

    weight_routing_number  = optional(number, null)
    failover_routing_type  = optional(string, null) # can be PRIMARY or SECONDARY. A PRIMARY record will be served if its healthcheck is passing, otherwise the SECONDARY will be served. See http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover-configuring-options.html#dns-failover-failover-rrsets
    latency_routing_region = optional(string, null) # set one region for this rule, can set many records for differents regions

    alias = optional(object({ # this block has conflicts with ttl and records
      name                   = string
      zone_id                = string
      evaluate_target_health = bool
    }), null)

    geolocation = optional(object({        # this block has conflicts with ttl and records
      continent   = optional(string, null) # It's accepted two letters, exemple AF, AN, AS, EU, OC, NA and SA
      country     = optional(string, null) # * for all countries or set BR, US, FR...
      subdivision = optional(string, null) # A subdivision code for a country.
    }), null)
  }))
  default = [
    {
      name = "cname-simple"
      type = "CNAME"
      records = [
        "mineiros.io"
      ]
    },
    {
      name = "a-simple"
      type = "A"
      records = [
        "203.0.113.200"
      ]
    },
    {
      name                  = "a-weight"
      type                  = "A"
      weight_routing_number = 70
      set_identifier        = "live"
      records = [
        "203.0.113.200"
      ]
    },
    {
      name                   = "a-latency"
      type                   = "A"
      latency_routing_region = "us-east-1"
      set_identifier         = "us-east-1"
      records = [
        "203.0.113.200"
      ]
    }
  ]
}
```


## Resources

| Name | Type |
|------|------|
| [aws_route53_zone.create_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_record.create_record_route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_delegation_set.create_delegation_set](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_delegation_set) | resource |

## Outputs

| Name | Description |
|------|-------------|
| `zone` | All Route53 zone hosted |
| `zone_id` | Zone ID to zone hosted |
| `zone_arn` | ARN to zone hosted |
| `zone_name_servers` | Name servers to zone hosted |
| `zone_name` | Zone name to zone hosted|
| `delegation_set` | All delegation set |
| `delegation_set_id` | Delegation set ID |
| `delegation_set_arn` | Delegation set ARN |
| `records` | All records sets |
| `records_names` | All records sets names |
| `records_fqdn` | All records sets FQDN |
