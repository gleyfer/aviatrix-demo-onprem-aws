# Create private key for launching instances
resource "tls_private_key" "csr_deploy_key" {
  count     = var.key_name == null ? 1 : 0
  algorithm = "RSA"
}

resource "local_file" "private_key" {
  count           = var.key_name == null ? 1 : 0
  content         = tls_private_key.csr_deploy_key[0].private_key_pem
  filename        = "${var.hostname}-key.pem"
  file_permission = "0600"
}

data "aviatrix_transit_gateway" "avtx_gateways" {
  for_each = toset(local.avtx_gateways)
  gw_name  = each.value
}

# Create public S2C+BGP Connections to transit
resource "aviatrix_transit_external_device_conn" "pubConns" {
  for_each          = { for conn in local.public_conns : "${conn.name}.${conn.tun_num}" => conn }
  vpc_id            = data.aviatrix_transit_gateway.avtx_gateways[each.value.name].vpc_id
  connection_name   = "${var.hostname}_to_${each.value.name}-${each.value.tun_num}"
  gw_name           = each.value.name
  tunnel_protocol   = var.tunnel_proto == "LAN" ? "IPsec" : var.tunnel_proto
  connection_type   = "bgp"
  enable_ikev2      = var.tunnel_proto == "IPsec" || var.tunnel_proto == "LAN" ? true : false
  bgp_local_as_num  = each.value.as_num
  bgp_remote_as_num = var.csr_bgp_as_num
  backup_bgp_remote_as_num = local.is_ha ? var.csr_bgp_as_num : null
  ha_enabled        = local.is_ha
  direct_connect    = false
  remote_gateway_ip = aws_eip.csr_public_eip[0].public_ip
  backup_remote_gateway_ip = local.is_ha ? aws_eip.csr_public_eip[1].public_ip : null
  pre_shared_key    = var.tunnel_proto == "IPsec" || var.tunnel_proto == "LAN" ? "aviatrix" : null
  backup_pre_shared_key    = local.is_ha ? "aviatrix" : null

  lifecycle {
    ignore_changes = all
  }
}

# Create private S2C+BGP Connections to transit
resource "aviatrix_transit_external_device_conn" "privConns" {
  for_each          = { for conn in local.private_conns : "${conn.name}.${conn.tun_num}" => conn }
  vpc_id            = data.aviatrix_transit_gateway.avtx_gateways[each.value.name].vpc_id
  connection_name   = "${var.hostname}_to_${each.value.name}-private-${each.value.tun_num}"
  gw_name           = each.value.name
  tunnel_protocol   = var.tunnel_proto
  connection_type   = "bgp"
  enable_ikev2      = var.tunnel_proto == "IPsec" ? true : false
  bgp_local_as_num  = each.value.as_num
  backup_bgp_remote_as_num = local.is_ha ? var.csr_bgp_as_num : null
  bgp_remote_as_num = var.csr_bgp_as_num
  ha_enabled        = local.is_ha
  direct_connect    = var.tunnel_proto == "LAN" ? false : true
  remote_gateway_ip = var.tunnel_proto == "LAN" ? null : tolist(aws_network_interface.CSR_Public_ENI[0].private_ips)[0]
  backup_remote_gateway_ip = local.is_ha && var.tunnel_proto != "LAN" ? tolist(aws_network_interface.CSR_Public_ENI[1].private_ips)[0] : null
  pre_shared_key    = var.tunnel_proto == "IPsec" ? "aviatrix" : null
  backup_pre_shared_key    = local.is_ha && var.tunnel_proto == "IPsec" ? "aviatrix" : null
  local_lan_ip       = var.tunnel_proto == "LAN" ? cidrhost(data.aws_subnet.bgpolan_subnet[0].cidr_block,4) : null
  backup_local_lan_ip       = local.is_ha && var.tunnel_proto == "LAN" ? cidrhost(data.aws_subnet.bgpolan_subnet[1].cidr_block,4) : null
  remote_lan_ip      = var.tunnel_proto == "LAN" ? tolist(aws_network_interface.CSR_BGPOLAN_ENI[0].private_ips)[0] : null
  backup_remote_lan_ip      = local.is_ha && var.tunnel_proto == "LAN" ? tolist(aws_network_interface.CSR_BGPOLAN_ENI[1].private_ips)[0] : null

  lifecycle {
    ignore_changes = all
  }
}
