output "instance_ips" {
  value = { for instance in module.team_servers : instance.tags_all["Name"] => instance.public_ip }
}

output "db_ip" {
  value = module.db.public_ip
}
