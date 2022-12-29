variable "make_hosted_zone" {
  description = "If true will be create one hosted zone"
  type        = bool
  default     = false
}

variable "make_delegation_set" {
  description = "If true will be create one delegation set"
  type        = bool
  default     = false
}

variable "delegation_set_name" {
  description = "Name to delegation set, if defined will be attached on hosted zone"
  type        = string
  default     = null
}

variable "zone_name" {
  description = "Name to zone"
  type        = string
  default     = null
}

variable "zone_description" {
  description = "Comment for the hosted zone"
  type        = string
  default     = null
}

variable "zone_force_destroy" {
  description = "Destroy all records when delete zone"
  type        = bool
  default     = false
}

variable "zone_delegation_set_id" {
  description = "The ID of the reusable delegation set whose NS records you want to assign to the hosted zone. Conflicts with the vpc"
  type        = string
  default     = null
}

variable "zone_vpc_id" {
  description = "Can be used to associate with a private hosted zone. Conflicts with the delegation_set_id"
  type        = string
  default     = null
}

variable "zone_vpc_region" {
  description = "Region of the VPC to associate. Defaults to AWS provider region"
  type        = string
  default     = null
}

variable "use_tags_default" {
  description = "If true will be use the tags default to hosted zone"
  type        = bool
  default     = true
}

variable "ou_name" {
  description = "Organization unit name"
  type        = string
  default     = "no"
}

variable "tags" {
  description = "Tags to Route53"
  type        = map(any)
  default     = {}
}

#######################################
# Record Set
#######################################
variable "set_one_zone_id_all_records" {
  description = "This variable set foreach record in item list to one hosted zone, if set set_one_zone_id_all_records variable all records will set this zone id"
  type        = string
  default     = null
}

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
  default = null
}
