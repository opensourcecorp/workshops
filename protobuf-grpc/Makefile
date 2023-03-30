# This target is just here to make regeneration easier without changing
# directories
gen:
	@make -s -C ./proto gen

go-tools:
	@printf 'Getting Go tool deps from tools.go...\n'
	@grep -E -o '".*"' tools.go | xargs -I{} go install {}
