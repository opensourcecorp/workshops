local_team_servers := $(shell vagrant status | grep -E -o 'team[0-9]+')

up-local:
	@vagrant up db
	@vagrant up $(local_team_servers)

provision-local:
# Don't re-provision DB at the same time, since it throws off team server tests
	@vagrant provision db
	@vagrant provision $(local_team_servers)

down-local:
	@vagrant destroy -f
