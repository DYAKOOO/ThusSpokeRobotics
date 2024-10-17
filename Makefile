# Set the remote and branch (change these if needed)
REMOTE := origin
BRANCH := main

# Get the commit message from the command line
# (or use a default if not provided)
MSG ?= Automated commit from Makefile

# PHONY targets
.PHONY: push force-push

# Default target (runs when you just type "make")
push:
	@echo "Adding all changes..."
	git add .
	@echo "Committing changes..."
	git commit -m "$(MSG)"
	@echo "Pushing to $(REMOTE)/$(BRANCH)..."
	git push $(REMOTE) $(BRANCH)

# Target to force push (use with caution!)
force-push:
	@echo "Adding all changes..."
	git add .
	@echo "Committing changes..."
	git commit -m "$(MSG)"
	@echo "Force pushing to $(REMOTE)/$(BRANCH)..."
	git push -f $(REMOTE) $(BRANCH)

# Target to show git status
status:
	@git status

# Target to pull latest changes
pull:
	@echo "Pulling latest changes from $(REMOTE)/$(BRANCH)..."
	git pull $(REMOTE) $(BRANCH)