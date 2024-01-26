output "wireguard_server_public_ip" {
  description = "The public IP address of the Wireguard server"
  value       = aws_instance.wireguard_server.public_ip
}
