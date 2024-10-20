local_team_servers := $(shell vagrant status | grep -E -o 'team[0-9]+')

ci:
	@bash ./scripts/ci.sh

up-local:
# NOTE: --parallel might not work for all providers, but does for libvirt
	@vagrant up --parallel

up-aws:
	@terraform -chdir=./terraform apply

yeet-aws:
	@terraform -chdir=./terraform apply -auto-approve
	@printf 'Waiting 30s for EC2 instances to hopefully process userdata...\n' && sleep 30
	@make -s provision-aws

connect-aws:
	ssh -p 2332 admin@$(shell terraform -chdir=./terraform output -json | jq -r '.instance_ips.value[]')

provision-local:
# Don't re-provision DB at the same time, since it throws off team server tests
	@vagrant provision db
	@vagrant provision $(local_team_servers)

provision-aws:
# TODO: just run this script without cd-ing but need to test later
	@(cd ./terraform && bash ../scripts/provision-ec2.sh)

down-local:
	@vagrant destroy -f

down-aws:
	@terraform -chdir=./terraform destroy

nuke-aws:
	@terraform -chdir=./terraform destroy -auto-approve
