variable "key_name" {
  description = "Existing SSH public key name"
  type        = string
  default     = null
}
variable "network_cidr" {
  type = string
  description = "CSR Virtual Network CIDR block"
}
variable "tunnel_proto" {
  type = string
  default = "IPsec"
}
variable "prioritize" {
  description = "Possible values: price, performance. Instance ami adjusted depending on this"
  type = string
  default = "price"
}
variable "public_subnets" {
  description = "Create CSR Public subnets"
  type = list(string)
  default = null
}
variable "public_subnet_ids" {
  description = "Use existing CSR Public subnet ids"
  type = list(string)
  default = null
}
variable "private_subnets" {
  description = "Create CSR Private subnets"
  type = list(string)
  default = null
}
variable "private_subnet_ids" {
  description = "Use existing CSR Private subnet ids"
  type = list(string)
  default = null
}
variable "bgpolan_subnet_ids" {
  description = "Existing BGP on LAN subnet ids"
  type = list(string)
  default = null
}
variable "instance_type" {
  description = "AWS instance type"
  default     = "t3.medium"
}
variable "hostname" {
  description = "Hostname of CSR instance"
}
variable "public_conns" {
  type        = list(string)
  description = "List of connections to Aviatrix over Public IPs"
  default     = []
}
variable "private_conns" {
  type        = list(string)
  description = "List of connections to Aviatrix over Private IPs"
  default     = []
}
variable "csr_bgp_as_num" {
  type        = string
  description = "CSR Remote BGP AS Number"
}
variable "create_client" {
  type    = bool
  default = false
}
variable "private_ips" {
  type    = bool
  default = false
}
variable "advertised_prefixes" {
  type        = list(string)
  description = "List of custom advertised prefixes to send over BGP to Transits"
  default     = []
}
variable "az1" {
  type        = string
  description = "Primary AZ"
  default     = "a"
}
variable "az2" {
  type        = string
  description = "Secondary AZ"
  default     = "b"
}

locals {
  
  #HA enabled/disabled
  is_ha = try(length(var.public_subnet_ids), 0) > 1 || try(length(var.public_subnets), 0) > 1 ? true : false

  #Get unique list of Aviatrix Gateways to pull data sources for
  avtx_gateways = distinct(flatten([[for gateway in var.public_conns : split(":", gateway)[0]], [for gateway in var.private_conns : split(":", gateway)[0]]]))

  #Create flattened list of maps in format: [{name=>gw_name, as_num=>bgp_as_num, tun_num=>x}, ...]
  #This list will be iterated through to create the Aviatrix external conn resources
  public_conns = flatten([for gateway in var.public_conns :
    [for i in range(tonumber(split(":", gateway)[2])) : {
      "name"    = split(":", gateway)[0]
      "as_num"  = split(":", gateway)[1]
      "tun_num" = i + 1
      }
    ]
  ])

  private_conns = flatten([for gateway in var.private_conns :
    [for i in range(tonumber(split(":", gateway)[2])) : {
      "name"    = split(":", gateway)[0]
      "as_num"  = split(":", gateway)[1]
      "tun_num" = i + 1
      }
    ]
  ])
}
