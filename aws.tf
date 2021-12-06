data "aws_region" "current" {}

#Need to pull VPC ID from any existing public subnet ids, if specified
data "aws_subnet" "public_subnet" {
  count = var.public_subnet_ids != null ? 1 : 0
  id = var.public_subnet_ids[count.index]
}

#Need to pull route tables for existing public subnet ids
data "aws_route_table" "public_rtb" {
  count = var.public_subnet_ids != null ? length(var.public_subnet_ids) : 0
  subnet_id = var.public_subnet_ids[count.index]
}

#Need to pull cidrs for existing BGPoLAN subnets
data "aws_subnet" "bgpolan_subnet" {
  count = var.bgpolan_subnet_ids != null ? length(var.bgpolan_subnet_ids) : 0
  id = var.bgpolan_subnet_ids[count.index]
}

#Create AWS VPC and Subnets
resource "aws_vpc" "csr_aws_vpc" {
  count = var.public_subnet_ids != null ? 0 : 1
  cidr_block = var.network_cidr
}

resource "aws_subnet" "csr_aws_public_subnet" {
  count = var.public_subnet_ids != null ? 0 : length(var.public_subnets)
  vpc_id                  = aws_vpc.csr_aws_vpc[0].id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone       = count.index == 0 ? "${data.aws_region.current.name}${var.az1}" : "${data.aws_region.current.name}${var.az2}"

  tags = {
    "Name" = "${var.hostname} Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "csr_aws_private_subnet" {
  count = var.private_subnet_ids != null ? 0 : length(var.private_subnets)
  vpc_id                  = aws_vpc.csr_aws_vpc[0].id
  cidr_block              = var.private_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone       = count.index == 0 ? "${data.aws_region.current.name}${var.az1}" : "${data.aws_region.current.name}${var.az2}"

  tags = {
    "Name" = "${var.hostname} Private Subnet ${count.index + 1}"
  }
}

#Create IGW for public subnet
resource "aws_internet_gateway" "csr_igw" {
  count = var.public_subnet_ids != null ? 0 : 1
  vpc_id = aws_vpc.csr_aws_vpc[0].id

  tags = {
    "Name" = "${var.hostname} Public Subnet IGW"
  }
}

#Create AWS Public and Private Subnet Route Tables
resource "aws_route_table" "csr_public_rtb" {
  count = var.public_subnet_ids != null ? 0 : length(var.public_subnets)
  vpc_id = aws_vpc.csr_aws_vpc[0].id

  tags = {
    "Name" = "${var.hostname} Public Route Table ${count.index + 1}"
  }
}

resource "aws_route_table" "csr_private_rtb" {
  count = var.private_subnet_ids != null ? 0 : var.private_subnets != null ? length(var.private_subnets) : 0
  vpc_id = aws_vpc.csr_aws_vpc[0].id

  tags = {
    "Name" = "${var.hostname} Private Route Table ${count.index + 1}"
  }
}

resource "aws_route" "csr_public_default" {
  count = var.public_subnet_ids != null ? 0 : length(var.public_subnets)
  route_table_id         = aws_route_table.csr_public_rtb[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.csr_igw[0].id
  depends_on             = [aws_route_table.csr_public_rtb, aws_internet_gateway.csr_igw]
}

resource "aws_route" "csr_private_default" {
  count = var.private_subnet_ids != null ? 0 : var.private_subnets != null ? length(var.private_subnets) : 0
  route_table_id         = aws_route_table.csr_private_rtb[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.CSR_Private_ENI[0].id
  depends_on             = [aws_route_table.csr_private_rtb, aws_instance.CSROnprem, aws_network_interface.CSR_Private_ENI]
}

resource "aws_route_table_association" "csr_public_rtb_assoc" {
  count = var.public_subnet_ids != null ? 0 : length(var.public_subnets)
  subnet_id      = aws_subnet.csr_aws_public_subnet[count.index].id
  route_table_id = aws_route_table.csr_public_rtb[count.index].id
}

resource "aws_route_table_association" "csr_private_rtb_assoc" {
  count = var.private_subnet_ids != null ? 0 : var.private_subnets != null ? length(var.private_subnets) : 0
  subnet_id      = aws_subnet.csr_aws_private_subnet[count.index].id
  route_table_id = aws_route_table.csr_private_rtb[count.index].id
}

resource "aws_security_group" "csr_public_sg" {
  name        = "csr_public-${var.hostname}"
  description = "Security group for public CSR ENI"
  vpc_id      = var.public_subnet_ids != null ? data.aws_subnet.public_subnet[0].vpc_id : aws_vpc.csr_aws_vpc[0].id

  lifecycle {
    ignore_changes = [ vpc_id ]
  }

  tags = {
    "Name" = "${var.hostname} Public SG"
  }
}

resource "aws_security_group" "csr_private_sg" {
  name        = "csr_private-${var.hostname}"
  description = "Security group for private CSR ENI"
  vpc_id      = var.public_subnet_ids != null ? data.aws_subnet.public_subnet[0].vpc_id : aws_vpc.csr_aws_vpc[0].id

  lifecycle {
    ignore_changes = [ vpc_id ]
  }

  tags = {
    "Name" = "${var.hostname} Private SG"
  }
}

resource "aws_security_group_rule" "csr_public_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.id

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_security_group_rule" "client_forward_ssh" {
  count             = var.create_client ? 1 : 0
  type              = "ingress"
  from_port         = 2222
  to_port           = 2222
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.id

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_security_group_rule" "csr_public_dhcp" {
  type              = "ingress"
  from_port         = 67
  to_port           = 67
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.id

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_security_group_rule" "csr_public_ntp" {
  type              = "ingress"
  from_port         = 123
  to_port           = 123
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.id
  
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_security_group_rule" "csr_public_snmp" {
  type              = "ingress"
  from_port         = 161
  to_port           = 161
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.id

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_security_group_rule" "csr_public_esp" {
  type              = "ingress"
  from_port         = 500
  to_port           = 500
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.id
  
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_security_group_rule" "csr_public_ipsec" {
  type              = "ingress"
  from_port         = 4500
  to_port           = 4500
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.id

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_security_group_rule" "csr_public_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_public_sg.id

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_security_group_rule" "csr_private_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_private_sg.id

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_security_group_rule" "csr_private_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csr_private_sg.id

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_network_interface" "CSR_Public_ENI" {
  count = var.public_subnet_ids != null ? length(var.public_subnet_ids) : length(var.public_subnets)
  subnet_id         = var.public_subnet_ids != null ? var.public_subnet_ids[count.index] : aws_subnet.csr_aws_public_subnet[count.index].id
  security_groups   = [aws_security_group.csr_public_sg.id]
  source_dest_check = false

  lifecycle {
    ignore_changes = all
  }

  tags = {
    "Name" = "${var.hostname} Public Interface ${count.index + 1}"
  }
}

resource "aws_network_interface" "CSR_Private_ENI" {
  count = var.private_subnet_ids != null ? length(var.private_subnet_ids) : var.private_subnets != null ? length(var.private_subnets) : 0
  subnet_id       = var.private_subnet_ids != null ? var.private_subnet_ids[count.index] : aws_subnet.csr_aws_private_subnet[count.index].id
  security_groups = [aws_security_group.csr_private_sg.id]
  source_dest_check = false

  tags = {
    "Name" = "${var.hostname} Private Interface ${count.index + 1}"
  }

  attachment {
    instance     = aws_instance.CSROnprem[count.index].id
    device_index = 1
  }
}

resource "aws_network_interface" "CSR_BGPOLAN_ENI" {
  count = var.bgpolan_subnet_ids != null ? length(var.bgpolan_subnet_ids) : 0
  subnet_id       = var.bgpolan_subnet_ids[count.index]
  private_ips     = [cidrhost(data.aws_subnet.bgpolan_subnet[count.index].cidr_block,tonumber(substr(var.hostname,-1,-1))+4)]
  security_groups = [aws_security_group.csr_private_sg.id]
  source_dest_check = false

  lifecycle {
    ignore_changes = all
  }

  tags = {
    "Name" = "${var.hostname} BGPoLAN Interface ${count.index + 1}"
  }
}

resource "aws_network_interface_attachment" "bgpolan_attachment" {
  count = var.bgpolan_subnet_ids != null ? length(var.bgpolan_subnet_ids) : 0
  instance_id          = aws_instance.CSROnprem[count.index].id
  network_interface_id = aws_network_interface.CSR_BGPOLAN_ENI[count.index].id
  device_index         = 2
}

resource "aws_eip" "csr_public_eip" {
  count = var.public_subnet_ids != null ? length(var.public_subnet_ids) : length(var.public_subnets)
  vpc               = true
  network_interface = aws_network_interface.CSR_Public_ENI[count.index].id
  depends_on        = [aws_internet_gateway.csr_igw]

  tags = {
    "Name" = "${var.hostname} Public IP ${count.index + 1}"
  }
}

resource "aws_key_pair" "csr_deploy_key" {
  count      = var.key_name == null ? 1 : 0
  key_name   = "${var.hostname}_sshkey"
  public_key = tls_private_key.csr_deploy_key[0].public_key_openssh

  lifecycle {
    ignore_changes = [ tags ]
  }
}

data "aws_ami" "amazon-linux" {
  count       = var.create_client ? 1 : 0
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20211027"]
  }
}

data "aws_ami" "csr_aws_ami" {
  owners = ["aws-marketplace"]
  most_recent = true

  filter {
    name   = "name"
    values = var.prioritize == "price" ? ["cisco_CSR-.17.3.1a-BYOL-624f5bb1-7f8e-4f7c-ad2c-03ae1cd1c2d3-ami-0032671e883fdd77a.4"] : ["cisco_CSR-.17.3.3-SEC-dbfcb230-402e-49cc-857f-dacb4db08d34"]
  }
}

resource "aws_instance" "test_client" {
  count                       = var.create_client ? var.private_subnet_ids != null ? length(var.private_subnet_ids) : length(var.private_subnets) : 0
  ami                         = data.aws_ami.amazon-linux.*.id[0]
  instance_type               = "t3.micro"
  key_name                    = var.key_name == null ? "${var.hostname}_sshkey" : var.key_name
  subnet_id                   = var.private_subnet_ids != null ? var.private_subnet_ids[count.index] : aws_subnet.csr_aws_private_subnet[count.index].id
  vpc_security_group_ids      = [aws_security_group.csr_private_sg.id]
  associate_public_ip_address = false

  tags = {
    "Name" = "TestClient_${var.hostname}-${count.index + 1}"
  }
}

data "aws_network_interface" "test_client_if" {
  count                       = var.create_client ? var.private_subnet_ids != null ? length(var.private_subnet_ids) : length(var.private_subnets) : 0
  id    = aws_instance.test_client[count.index].primary_network_interface_id
}

data "aws_instance" "CSROnprem" {
  count = var.public_subnet_ids != null ? length(var.public_subnet_ids) : length(var.public_subnets)
  instance_id = aws_instance.CSROnprem[count.index].id
  get_user_data = true
}

resource "aws_instance" "CSROnprem" {
  count = var.public_subnet_ids != null ? length(var.public_subnet_ids) : length(var.public_subnets)
  ami           = data.aws_ami.csr_aws_ami.id
  instance_type = var.instance_type
  key_name      = var.key_name == null ? "${var.hostname}_sshkey" : var.key_name

  network_interface {
    network_interface_id = aws_network_interface.CSR_Public_ENI[count.index].id
    device_index         = 0
  }

  user_data = templatefile("${path.module}/csr_aws.sh", {
    public_conns   = aviatrix_transit_external_device_conn.pubConns
    private_conns  = aviatrix_transit_external_device_conn.privConns
    pub_conn_keys  = keys(aviatrix_transit_external_device_conn.pubConns)
    priv_conn_keys = keys(aviatrix_transit_external_device_conn.privConns)
    csr_eip        = aws_eip.csr_public_eip[count.index].public_ip
    csr_pip        = tolist(aws_network_interface.CSR_Public_ENI[count.index].private_ips)[0]
    gateway        = data.aviatrix_transit_gateway.avtx_gateways
    hostname       = "${var.hostname}-${count.index + 1}"
    is_ha          = local.is_ha
    test_client_ip = var.create_client ? data.aws_network_interface.test_client_if[count.index].private_ip : ""
    private_if     = var.private_subnet_ids != null || var.private_subnets != null ? true : false
    bgpolan_if     = var.bgpolan_subnet_ids != null ? true : false
    adv_prefixes   = var.advertised_prefixes
  })

  lifecycle {
    ignore_changes = [ ami ]
  }

  tags = {
    "Name" = "${var.hostname}-${count.index + 1}"
  }
}
