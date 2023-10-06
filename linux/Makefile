local_team_servers := $(shell vagrant status | grep -E -o 'team[0-9]+')

up-local:
	@vagrant up db
	@vagrant up $(local_team_servers)

up-aws:
	@(cd ./terraform && terraform apply)

yeet-aws:
	@(cd ./terraform && terraform apply -auto-approve)
# Give time for userdata to run
	@(sleep 30)
	@make -s provision-aws

provision-local:
# Don't re-provision DB at the same time, since it throws off team server tests
	@vagrant provision db
	@vagrant provision $(local_team_servers)

provision-aws:
	@(cd ./terraform && bash ../scripts/provision-ec2.sh)

down-local:
	@vagrant destroy -f

down-aws:
	@(cd ./terraform && terraform destroy)

nuke-aws:
	@(cd ./terraform && terraform destroy -auto-approve)
