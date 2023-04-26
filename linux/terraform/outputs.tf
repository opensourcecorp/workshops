output "instance_ips" {
  value = {for instance in module.team_server : instance.tags_all["Name"] => instance.public_ip}
}