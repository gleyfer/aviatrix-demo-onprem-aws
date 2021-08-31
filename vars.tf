variable "key_name" {
  description = "Existing SSH public key name"
  type        = string
  default     = null
}
variable "network_cidr" {
  description = "CSR Virtual Network CIDR block"
}
variable "public_sub" {
  description = "CSR Public subnet"
}
variable "private_sub" {
  description = "CSR Private subnet"
}
variable "instance_type" {
  description = "AWS instance type"
  default     = "t2.medium"
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

locals {

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
