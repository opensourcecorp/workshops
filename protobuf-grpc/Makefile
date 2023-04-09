# This target should be invoked on first clone to ensure the developer
# workstation is setup correctly with dependencies
setup:
	@printf 'Initializing submodules...\n'
	@make -s -C proto submodules
	@printf 'Getting Go package deps...\n'
	@go mod tidy
	@printf 'Getting Go tool deps from tools.go...\n'
	@grep -E -o '".*"' tools.go | xargs -I{} go install {}

# This target is just here to make regeneration easier without changing
# directories
gen:
	@make -s -C ./proto generate
