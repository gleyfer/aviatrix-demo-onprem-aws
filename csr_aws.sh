ios-config-1="username admin privilege 15 password Password123"
ios-config-2="hostname ${hostname}"
%{ if private_if || bgpolan_if ~}
ios-config-3="interface GigabitEthernet2"
ios-config-4="ip address dhcp"
ios-config-5="ip nat inside"
ios-config-6="no shut"
ios-config-7="exit"
%{ endif ~}
%{ if test_client_ip != "" ~}
ios-config-8="ip nat inside source static tcp ${test_client_ip} 22 interface GigabitEthernet1 2222"
ios-config-9="ip access-list extended testclient_nat"
ios-config-10="permit ip host ${test_client_ip} any"
ios-config-11="exit"
ios-config-12="ip nat inside source list testclient_nat interface GigabitEthernet1 overload"
%{ endif ~}
%{ for key, conn in public_conns ~}
%{ if conn.tunnel_protocol == "IPsec" ~}
%{ if conn.pre_shared_key != "" ~}
ios-config-${index(pub_conn_keys, key)}01="crypto ikev2 keyring ${csr_eip}-${gateway[conn.gw_name].public_ip}"
ios-config-${index(pub_conn_keys, key)}02="peer ${csr_eip}-${gateway[conn.gw_name].public_ip}"
ios-config-${index(pub_conn_keys, key)}03="address ${gateway[conn.gw_name].public_ip}"
ios-config-${index(pub_conn_keys, key)}04="identity address ${gateway[conn.gw_name].public_ip}"
ios-config-${index(pub_conn_keys, key)}05="pre-shared-key ${conn.pre_shared_key}"
ios-config-${index(pub_conn_keys, key)}06="exit"
ios-config-${index(pub_conn_keys, key)}07="exit"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}08="crypto ikev2 proposal avx-s2c"
ios-config-${index(pub_conn_keys, key)}09="encryption aes-cbc-256"
ios-config-${index(pub_conn_keys, key)}10="integrity sha256"
ios-config-${index(pub_conn_keys, key)}11="group 14"
ios-config-${index(pub_conn_keys, key)}12="exit"
ios-config-${index(pub_conn_keys, key)}13="crypto ikev2 policy 200"
ios-config-${index(pub_conn_keys, key)}14="proposal avx-s2c"
ios-config-${index(pub_conn_keys, key)}15="exit"
ios-config-${index(pub_conn_keys, key)}16="crypto ikev2 profile ${csr_eip}-${gateway[conn.gw_name].public_ip}"
ios-config-${index(pub_conn_keys, key)}17="match identity remote address ${gateway[conn.gw_name].public_ip} 255.255.255.255"
ios-config-${index(pub_conn_keys, key)}18="identity local address ${csr_eip}"
ios-config-${index(pub_conn_keys, key)}19="authentication remote pre-share"
ios-config-${index(pub_conn_keys, key)}20="authentication local pre-share"
ios-config-${index(pub_conn_keys, key)}21="keyring local ${csr_eip}-${gateway[conn.gw_name].public_ip}"
ios-config-${index(pub_conn_keys, key)}22="lifetime 28800"
ios-config-${index(pub_conn_keys, key)}23="dpd 10 3 periodic"
ios-config-${index(pub_conn_keys, key)}24="exit"
ios-config-${index(pub_conn_keys, key)}25="crypto ipsec transform-set ${csr_eip}-${gateway[conn.gw_name].public_ip} esp-aes 256 esp-sha256-hmac"
ios-config-${index(pub_conn_keys, key)}26="mode tunnel"
ios-config-${index(pub_conn_keys, key)}27="exit"
ios-config-${index(pub_conn_keys, key)}28="crypto ipsec df-bit clear"
ios-config-${index(pub_conn_keys, key)}29="crypto ipsec profile ${csr_eip}-${gateway[conn.gw_name].public_ip}"
ios-config-${index(pub_conn_keys, key)}30="set security-association lifetime seconds 3600"
ios-config-${index(pub_conn_keys, key)}31="set transform-set ${csr_eip}-${gateway[conn.gw_name].public_ip}"
ios-config-${index(pub_conn_keys, key)}32="set pfs group14"
ios-config-${index(pub_conn_keys, key)}33="set ikev2-profile ${csr_eip}-${gateway[conn.gw_name].public_ip}"
ios-config-${index(pub_conn_keys, key)}34="exit"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}35="interface Tunnel ${index(pub_conn_keys, key) + 1}"
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(pub_conn_keys, key)}36="ip address ${split("/", split(",", conn.remote_tunnel_cidr)[0])[0]} 255.255.255.252"
%{ else ~}
ios-config-${index(pub_conn_keys, key)}36="ip address ${split("/", split(",", conn.backup_remote_tunnel_cidr)[0])[0]} 255.255.255.252"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}37="ip mtu 1436"
ios-config-${index(pub_conn_keys, key)}38="ip tcp adjust-mss 1387"
ios-config-${index(pub_conn_keys, key)}39="tunnel source GigabitEthernet1"
%{ if conn.tunnel_protocol == "IPsec" ~}
ios-config-${index(pub_conn_keys, key)}40="tunnel mode ipsec ipv4"
ios-config-${index(pub_conn_keys, key)}41="tunnel protection ipsec profile ${csr_eip}-${gateway[conn.gw_name].public_ip}"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}42="tunnel destination ${gateway[conn.gw_name].public_ip}"
ios-config-${index(pub_conn_keys, key)}43="ip virtual-reassembly"
ios-config-${index(pub_conn_keys, key)}44="exit"
ios-config-${index(pub_conn_keys, key)}45="router bgp ${conn.bgp_remote_as_num}"
ios-config-${index(pub_conn_keys, key)}46="bgp log-neighbor-changes"
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(pub_conn_keys, key)}47="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} remote-as ${conn.bgp_local_as_num}"
ios-config-${index(pub_conn_keys, key)}48="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} timers 10 30 30"
%{ else ~}
ios-config-${index(pub_conn_keys, key)}47="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[0])[0]} remote-as ${conn.bgp_local_as_num}"
ios-config-${index(pub_conn_keys, key)}48="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[0])[0]} timers 10 30 30"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}49="address-family ipv4"
ios-config-${index(pub_conn_keys, key)}50="redistribute connected"
%{ if length(adv_prefixes) != 0 ~}
ios-config-${index(pub_conn_keys, key)}800="redistribute static"
%{ endif ~}
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(pub_conn_keys, key)}51="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} activate"
ios-config-${index(pub_conn_keys, key)}52="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} soft-reconfiguration inbound"
%{ else ~}
ios-config-${index(pub_conn_keys, key)}51="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[0])[0]} activate"
ios-config-${index(pub_conn_keys, key)}52="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[0])[0]} soft-reconfiguration inbound"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}53="maximum-paths 4"
ios-config-${index(pub_conn_keys, key)}54="exit-address-family"
ios-config-${index(pub_conn_keys, key)}55="exit"
%{ if length(split(",", conn.local_tunnel_cidr)) > 1 && is_ha == false ~}
%{ if conn.tunnel_protocol == "IPsec" ~}
%{ if conn.pre_shared_key != "" ~}
ios-config-${index(pub_conn_keys, key)}56="crypto ikev2 keyring ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}57="peer ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}58="address ${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}59="identity address ${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}60="pre-shared-key ${conn.pre_shared_key}"
ios-config-${index(pub_conn_keys, key)}61="exit"
ios-config-${index(pub_conn_keys, key)}62="exit"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}63="crypto ikev2 profile ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}64="match identity remote address ${gateway[conn.gw_name].ha_public_ip} 255.255.255.255"
ios-config-${index(pub_conn_keys, key)}65="identity local address ${csr_eip}"
ios-config-${index(pub_conn_keys, key)}66="authentication remote pre-share"
ios-config-${index(pub_conn_keys, key)}67="authentication local pre-share"
ios-config-${index(pub_conn_keys, key)}68="keyring local ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}69="lifetime 28800"
ios-config-${index(pub_conn_keys, key)}70="dpd 10 3 periodic"
ios-config-${index(pub_conn_keys, key)}71="exit"
ios-config-${index(pub_conn_keys, key)}72="crypto ipsec transform-set ${csr_eip}-${gateway[conn.gw_name].ha_public_ip} esp-aes 256 esp-sha256-hmac"
ios-config-${index(pub_conn_keys, key)}73="mode tunnel"
ios-config-${index(pub_conn_keys, key)}74="exit"
ios-config-${index(pub_conn_keys, key)}75="crypto ipsec profile ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}76="set security-association lifetime seconds 3600"
ios-config-${index(pub_conn_keys, key)}77="set transform-set ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}78="set pfs group14"
ios-config-${index(pub_conn_keys, key)}79="set ikev2-profile ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}80="exit"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}81="interface Tunnel ${index(pub_conn_keys, key) +1}0"
ios-config-${index(pub_conn_keys, key)}82="ip address ${split("/", split(",", conn.remote_tunnel_cidr)[1])[0]} 255.255.255.252"
ios-config-${index(pub_conn_keys, key)}83="ip mtu 1436"
ios-config-${index(pub_conn_keys, key)}84="ip tcp adjust-mss 1387"
ios-config-${index(pub_conn_keys, key)}85="tunnel source GigabitEthernet1"
%{ if conn.tunnel_protocol == "IPsec" ~}
ios-config-${index(pub_conn_keys, key)}86="tunnel mode ipsec ipv4"
ios-config-${index(pub_conn_keys, key)}87="tunnel protection ipsec profile ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}88="tunnel destination ${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}89="ip virtual-reassembly"
ios-config-${index(pub_conn_keys, key)}90="exit"
ios-config-${index(pub_conn_keys, key)}91="router bgp ${conn.bgp_remote_as_num}"
ios-config-${index(pub_conn_keys, key)}92="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} remote-as ${conn.bgp_local_as_num}"
ios-config-${index(pub_conn_keys, key)}93="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} timers 10 30 30"
ios-config-${index(pub_conn_keys, key)}94="address-family ipv4"
ios-config-${index(pub_conn_keys, key)}95="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} activate"
ios-config-${index(pub_conn_keys, key)}96="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} soft-reconfiguration inbound"
ios-config-${index(pub_conn_keys, key)}97="exit-address-family"
ios-config-${index(pub_conn_keys, key)}98="exit"
%{ endif ~}
%{ if length(split(",", conn.local_tunnel_cidr)) > 1 && is_ha == true ~}
%{ if conn.tunnel_protocol == "IPsec" ~}
%{ if conn.pre_shared_key != "" ~}
ios-config-${index(pub_conn_keys, key)}56="crypto ikev2 keyring ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}57="peer ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}58="address ${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}59="identity address ${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}60="pre-shared-key ${conn.pre_shared_key}"
ios-config-${index(pub_conn_keys, key)}61="exit"
ios-config-${index(pub_conn_keys, key)}62="exit"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}63="crypto ikev2 profile ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}64="match identity remote address ${gateway[conn.gw_name].ha_public_ip} 255.255.255.255"
ios-config-${index(pub_conn_keys, key)}65="identity local address ${csr_eip}"
ios-config-${index(pub_conn_keys, key)}66="authentication remote pre-share"
ios-config-${index(pub_conn_keys, key)}67="authentication local pre-share"
ios-config-${index(pub_conn_keys, key)}68="keyring local ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}69="lifetime 28800"
ios-config-${index(pub_conn_keys, key)}70="dpd 10 3 periodic"
ios-config-${index(pub_conn_keys, key)}71="exit"
ios-config-${index(pub_conn_keys, key)}72="crypto ipsec transform-set ${csr_eip}-${gateway[conn.gw_name].ha_public_ip} esp-aes 256 esp-sha256-hmac"
ios-config-${index(pub_conn_keys, key)}73="mode tunnel"
ios-config-${index(pub_conn_keys, key)}74="exit"
ios-config-${index(pub_conn_keys, key)}75="crypto ipsec profile ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}76="set security-association lifetime seconds 3600"
ios-config-${index(pub_conn_keys, key)}77="set transform-set ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}78="set pfs group14"
ios-config-${index(pub_conn_keys, key)}79="set ikev2-profile ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}80="exit"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}81="interface Tunnel ${index(pub_conn_keys, key) +1}0"
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(pub_conn_keys, key)}82="ip address ${split("/", split(",", conn.remote_tunnel_cidr)[1])[0]} 255.255.255.252"
%{ else ~}
ios-config-${index(pub_conn_keys, key)}82="ip address ${split("/", split(",", conn.backup_remote_tunnel_cidr)[1])[0]} 255.255.255.252"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}83="ip mtu 1436"
ios-config-${index(pub_conn_keys, key)}84="ip tcp adjust-mss 1387"
ios-config-${index(pub_conn_keys, key)}85="tunnel source GigabitEthernet1"
%{ if conn.tunnel_protocol == "IPsec" ~}
ios-config-${index(pub_conn_keys, key)}86="tunnel mode ipsec ipv4"
ios-config-${index(pub_conn_keys, key)}87="tunnel protection ipsec profile ${csr_eip}-${gateway[conn.gw_name].ha_public_ip}"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}88="tunnel destination ${gateway[conn.gw_name].ha_public_ip}"
ios-config-${index(pub_conn_keys, key)}89="ip virtual-reassembly"
ios-config-${index(pub_conn_keys, key)}90="exit"
ios-config-${index(pub_conn_keys, key)}91="router bgp ${conn.bgp_remote_as_num}"
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(pub_conn_keys, key)}92="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} remote-as ${conn.bgp_local_as_num}"
ios-config-${index(pub_conn_keys, key)}93="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} timers 10 30 30"
%{ else ~}
ios-config-${index(pub_conn_keys, key)}92="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[1])[0]} remote-as ${conn.bgp_local_as_num}"
ios-config-${index(pub_conn_keys, key)}93="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[1])[0]} timers 10 30 30"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}94="address-family ipv4"
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(pub_conn_keys, key)}95="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} activate"
ios-config-${index(pub_conn_keys, key)}96="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} soft-reconfiguration inbound"
%{ else ~}
ios-config-${index(pub_conn_keys, key)}95="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[1])[0]} activate"
ios-config-${index(pub_conn_keys, key)}96="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[1])[0]} soft-reconfiguration inbound"
%{ endif ~}
ios-config-${index(pub_conn_keys, key)}97="exit-address-family"
ios-config-${index(pub_conn_keys, key)}98="exit"
%{ endif ~}
%{ endfor ~}
%{ for key, conn in private_conns ~}
%{ if bgpolan_if == false ~}
%{ if conn.tunnel_protocol == "IPsec" ~}
%{ if conn.pre_shared_key != "" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}01="crypto ikev2 keyring ${csr_pip}-${gateway[conn.gw_name].private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}02="peer ${csr_pip}-${gateway[conn.gw_name].private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}03="address ${gateway[conn.gw_name].private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}04="identity address ${gateway[conn.gw_name].private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}05="pre-shared-key ${conn.pre_shared_key}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}06="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}07="exit"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}08="crypto ikev2 proposal avx-s2c"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}09="encryption aes-cbc-256"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}10="integrity sha256"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}11="group 14"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}12="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}13="crypto ikev2 policy 200"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}14="proposal avx-s2c"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}15="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}16="crypto ikev2 profile ${csr_pip}-${gateway[conn.gw_name].private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}17="match identity remote address ${gateway[conn.gw_name].private_ip} 255.255.255.255"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}18="identity local address ${csr_pip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}19="authentication remote pre-share"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}20="authentication local pre-share"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}21="keyring local ${csr_pip}-${gateway[conn.gw_name].private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}22="lifetime 28800"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}23="dpd 10 3 periodic"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}24="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}25="crypto ipsec transform-set ${csr_pip}-${gateway[conn.gw_name].private_ip} esp-aes 256 esp-sha256-hmac"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}26="mode tunnel"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}27="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}28="crypto ipsec df-bit clear"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}29="crypto ipsec profile ${csr_pip}-${gateway[conn.gw_name].private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}30="set security-association lifetime seconds 3600"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}31="set transform-set ${csr_pip}-${gateway[conn.gw_name].private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}32="set pfs group14"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}33="set ikev2-profile ${csr_pip}-${gateway[conn.gw_name].private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}34="exit"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}35="interface Tunnel ${index(priv_conn_keys, key) + length(pub_conn_keys) + 1}"
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}36="ip address ${split("/", split(",", conn.remote_tunnel_cidr)[0])[0]} 255.255.255.252"
%{ else ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}36="ip address ${split("/", split(",", conn.backup_remote_tunnel_cidr)[0])[0]} 255.255.255.252"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}37="ip mtu 1436"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}38="ip tcp adjust-mss 1387"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}39="tunnel source GigabitEthernet1"
%{ if conn.tunnel_protocol == "IPsec" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}40="tunnel mode ipsec ipv4"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}41="tunnel protection ipsec profile ${csr_pip}-${gateway[conn.gw_name].private_ip}"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}42="tunnel destination ${gateway[conn.gw_name].private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}43="ip virtual-reassembly"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}44="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}45="router bgp ${conn.bgp_remote_as_num}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}46="bgp log-neighbor-changes"
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}47="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} remote-as ${conn.bgp_local_as_num}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}48="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} timers 10 30 30"
%{ else ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}47="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[0])[0]} remote-as ${conn.bgp_local_as_num}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}48="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[0])[0]} timers 10 30 30"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}49="address-family ipv4"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}50="redistribute connected"
%{ if length(adv_prefixes) != 0 ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}800="redistribute static"
%{ endif ~}
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}51="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} activate"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}52="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[0])[0]} soft-reconfiguration inbound"
%{ else ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}51="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[0])[0]} activate"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}52="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[0])[0]} soft-reconfiguration inbound"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}53="maximum-paths 4"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}54="exit-address-family"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}55="exit"
%{ if length(split(",", conn.local_tunnel_cidr)) > 1 && is_ha == false ~}
%{ if conn.tunnel_protocol == "IPsec" ~}
%{ if conn.pre_shared_key != "" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}56="crypto ikev2 keyring ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}57="peer ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}58="address ${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}59="identity address ${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}60="pre-shared-key ${conn.pre_shared_key}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}61="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}62="exit"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}63="crypto ikev2 profile ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}64="match identity remote address ${gateway[conn.gw_name].ha_private_ip} 255.255.255.255"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}65="identity local address ${csr_pip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}66="authentication remote pre-share"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}67="authentication local pre-share"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}68="keyring local ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}69="lifetime 28800"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}70="dpd 10 3 periodic"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}71="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}72="crypto ipsec transform-set ${csr_pip}-${gateway[conn.gw_name].ha_private_ip} esp-aes 256 esp-sha256-hmac"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}73="mode tunnel"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}74="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}75="crypto ipsec profile ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}76="set security-association lifetime seconds 3600"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}77="set transform-set ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}78="set pfs group14"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}79="set ikev2-profile ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}80="exit"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}81="interface Tunnel ${index(priv_conn_keys, key) + length(pub_conn_keys) + 1}0"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}82="ip address ${split("/", split(",", conn.remote_tunnel_cidr)[1])[0]} 255.255.255.252"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}83="ip mtu 1436"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}84="ip tcp adjust-mss 1387"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}85="tunnel source GigabitEthernet1"
%{ if conn.tunnel_protocol == "IPsec" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}86="tunnel mode ipsec ipv4"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}87="tunnel protection ipsec profile ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}88="tunnel destination ${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}89="ip virtual-reassembly"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}90="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}91="router bgp ${conn.bgp_remote_as_num}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}92="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} remote-as ${conn.bgp_local_as_num}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}93="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} timers 10 30 30"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}94="address-family ipv4"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}95="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} activate"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}96="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} soft-reconfiguration inbound"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}97="exit-address-family"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}98="exit"
%{ endif ~}
%{ if length(split(",", conn.local_tunnel_cidr)) > 1 && is_ha == true ~}
%{ if conn.tunnel_protocol == "IPsec" ~}
%{ if conn.pre_shared_key != "" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}56="crypto ikev2 keyring ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}57="peer ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}58="address ${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}59="identity address ${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}60="pre-shared-key ${conn.pre_shared_key}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}61="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}62="exit"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}63="crypto ikev2 profile ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}64="match identity remote address ${gateway[conn.gw_name].ha_private_ip} 255.255.255.255"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}65="identity local address ${csr_pip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}66="authentication remote pre-share"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}67="authentication local pre-share"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}68="keyring local ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}69="lifetime 28800"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}70="dpd 10 3 periodic"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}71="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}72="crypto ipsec transform-set ${csr_pip}-${gateway[conn.gw_name].ha_private_ip} esp-aes 256 esp-sha256-hmac"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}73="mode tunnel"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}74="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}75="crypto ipsec profile ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}76="set security-association lifetime seconds 3600"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}77="set transform-set ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}78="set pfs group14"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}79="set ikev2-profile ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}80="exit"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}81="interface Tunnel ${index(priv_conn_keys, key) + length(pub_conn_keys) + 1}0"
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}82="ip address ${split("/", split(",", conn.remote_tunnel_cidr)[1])[0]} 255.255.255.252"
%{ else ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}82="ip address ${split("/", split(",", conn.backup_remote_tunnel_cidr)[1])[0]} 255.255.255.252"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}83="ip mtu 1436"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}84="ip tcp adjust-mss 1387"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}85="tunnel source GigabitEthernet1"
%{ if conn.tunnel_protocol == "IPsec" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}86="tunnel mode ipsec ipv4"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}87="tunnel protection ipsec profile ${csr_pip}-${gateway[conn.gw_name].ha_private_ip}"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}88="tunnel destination ${gateway[conn.gw_name].ha_private_ip}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}89="ip virtual-reassembly"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}90="exit"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}91="router bgp ${conn.bgp_remote_as_num}"
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}92="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} remote-as ${conn.bgp_local_as_num}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}93="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} timers 10 30 30"
%{ else ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}92="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[1])[0]} remote-as ${conn.bgp_local_as_num}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}93="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[1])[0]} timers 10 30 30"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}94="address-family ipv4"
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}95="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} activate"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}96="neighbor ${split("/", split(",", conn.local_tunnel_cidr)[1])[0]} soft-reconfiguration inbound"
%{ else ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}95="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[1])[0]} activate"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}96="neighbor ${split("/", split(",", conn.backup_local_tunnel_cidr)[1])[0]} soft-reconfiguration inbound"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}97="exit-address-family"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}98="exit"
%{ endif ~}
%{ else ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}01="router bgp ${conn.bgp_remote_as_num}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}02="bgp log-neighbor-changes"
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}03="neighbor ${conn.local_lan_ip} remote-as ${conn.bgp_local_as_num}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}04="neighbor ${conn.local_lan_ip} timers 10 30 30"
%{ else ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}03="neighbor ${conn.backup_local_lan_ip} remote-as ${conn.bgp_local_as_num}"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}04="neighbor ${conn.backup_local_lan_ip} timers 10 30 30"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}05="address-family ipv4"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}06="redistribute connected"
%{ if length(adv_prefixes) != 0 ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}800="redistribute static"
%{ endif ~}
%{ if substr(hostname, -1, -1) == "1" ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}07="neighbor ${conn.local_lan_ip} activate"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}08="neighbor ${conn.local_lan_ip} soft-reconfiguration inbound"
%{ else ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}07="neighbor ${conn.backup_local_lan_ip} activate"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}08="neighbor ${conn.backup_local_lan_ip} soft-reconfiguration inbound"
%{ endif ~}
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}09="maximum-paths 4"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}10="exit-address-family"
ios-config-${index(priv_conn_keys, key) + length(pub_conn_keys)}11="exit"
%{ endif ~}
%{ endfor ~}
%{ for index, prefix in adv_prefixes ~}
ios-config-140${index}="ip route ${split("/", prefix)[0]} ${cidrnetmask(prefix)} Null0"
%{ endfor ~}
ios-config-1500="end"
ios-config-1501="wr mem"
