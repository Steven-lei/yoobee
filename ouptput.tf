# output "vpnserver_public_ip" {
#   value = aws_instance.openvpn.public_ip
# }
# output "vpnserver_private_ip" {
#   value = aws_instance.openvpn.private_ip
# }
# output "vpnserver_ssh_connect" {
#   description = "SSH command to connect to and confiugre the VPN Server"
#   value = <<-EOT
# VPN server has been launched. Be aware that the username could be root, ec2-user, or ubuntu depending on the AMI.
# ssh -i ~/.ssh/yoobee-aws-key openvpnas@${aws_instance.openvpn.public_ip}
# EOT
# }

# output "load_balancer_dns_name" {
#   description = "DNS name of the Application Load Balancer"
#   value       = aws_lb.web_alb.dns_name
# }