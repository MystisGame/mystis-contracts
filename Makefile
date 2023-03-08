default: help

help: 
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  deploy            - Deploy the compiled contract"

deploy:
	@echo "⏳ Deploying contract..."
	@python3 ./scripts/deploy.py 
	@echo "Deployed successfully"

