# Default bump target assumes patch
# Usage: make bump xlog [major|minor]
bump:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Error: Specify a script (e.g., make bump xlog)"; \
		exit 1; \
	fi; \
	SCRIPT=$(word 1,$(filter-out $@,$(MAKECMDGOALS))); \
	TYPE=$(word 2,$(filter-out $@,$(MAKECMDGOALS))); \
	if [ -z "$$TYPE" ]; then TYPE="patch"; fi; \
	if [ ! -f "$$SCRIPT/version.txt" ]; then \
		echo "0.1.0" > $$SCRIPT/version.txt; \
		echo "Created $$SCRIPT/version.txt with initial version 0.1.0"; \
	else \
		CURRENT_VERSION=$$(cat $$SCRIPT/version.txt); \
		if ! echo "$$CURRENT_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
			echo "Invalid version format in $$SCRIPT/version.txt ($$CURRENT_VERSION); resetting to 0.1.0"; \
			echo "0.1.0" > $$SCRIPT/version.txt; \
		fi; \
	fi; \
	CURRENT_VERSION=$$(cat $$SCRIPT/version.txt); \
	MAJOR=$$(echo $$CURRENT_VERSION | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT_VERSION | cut -d. -f2); \
	PATCH=$$(echo $$CURRENT_VERSION | cut -d. -f3); \
	if [ "$$TYPE" = "patch" ]; then \
		NEW_VERSION="$$MAJOR.$$MINOR.$$((PATCH + 1))"; \
	elif [ "$$TYPE" = "minor" ]; then \
		NEW_VERSION="$$MAJOR.$$((MINOR + 1)).0"; \
	elif [ "$$TYPE" = "major" ]; then \
		NEW_VERSION="$$((MAJOR + 1)).0.0"; \
	else \
		echo "Error: Invalid TYPE '$$TYPE'; use patch, minor, or major"; \
		exit 1; \
	fi; \
	echo $$NEW_VERSION > $$SCRIPT/version.txt; \
	git add $$SCRIPT/version.txt; \
	git commit -m "$$SCRIPT: bump to $$NEW_VERSION"; \
	git tag $$SCRIPT-v$$NEW_VERSION

# Ignore extra arguments to avoid Make errors
.PHONY: bump
%:
	@:
