output "vpnserver_public_ip" {
  value = aws_instance.openvpn.public_ip
}

output "vpnserver_ssh_connect" {
  value = "ssh -i ~/.ssh/yoobee-aws-key.pub ec2-user@${aws_instance.openvpn.public_ip}"
}

output "vpnserver_private_ip" {
  value = aws_instance.openvpn.private_ip
}