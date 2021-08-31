output "hostname" {
  value = var.hostname
}
output "public_ip" {
  value = aws_eip.csr_public_eip.public_ip
}
output "ssh_cmd_csr" {
  value = var.key_name == null ? "ssh -i ${var.hostname}-key.pem ec2-user@${aws_eip.csr_public_eip.public_ip}" : "ssh -i ${var.key_name}.pem ec2-user@${aws_eip.csr_public_eip.public_ip}" 
}
output "ssh_cmd_client" {
  value = var.key_name == null ? "ssh -i ${var.hostname}-key.pem ec2-user@${aws_eip.csr_public_eip.public_ip} -p 2222" : "ssh -i ${var.key_name}.pem ec2-user@${aws_eip.csr_public_eip.public_ip} -p 2222" 
}
output "user_data" {
  value = base64decode(data.aws_instance.CSROnprem.user_data_base64)
}
