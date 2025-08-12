# # DevOps Scripts Versioning Makefile
# Supports two patterns:
# 1. Project scripts: xlog/ (with version.txt)
# 2. Simple scripts: install/nvim.sh (with embedded version)

.PHONY: bump help versions

help:
	@echo "DevOps Scripts Versioning"
	@echo ""
	@echo "Usage:"
	@echo "  make bump <script_name> [type]     # For project scripts (xlog/)"
	@echo "  make bump <path/file.sh> [type]    # For simple scripts (install/nvim.sh)"
	@echo ""
	@echo "Examples:"
	@echo "  make bump xlog                     # patch bump xlog project"
	@echo "  make bump xlog minor               # minor bump xlog project"
	@echo "  make bump install/nvim.sh          # patch bump simple script"
	@echo "  make bump install/nvim.sh major    # major bump simple script"
	@echo ""
	@echo "Project scripts (have directories):"
	@find . -maxdepth 2 -name "version.txt" -exec dirname {} \; | sed 's|^\./||' | sort
	@echo ""
	@echo "Simple scripts:"
	@find . -name "*.sh" -path "*/install/*" -o -path "*/backup/*" -o -path "*/monitoring/*" | sort

bump:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Error: Specify a script (e.g., make bump xlog or make bump install/nvim.sh)"; \
		echo "Run 'make help' for examples"; \
		exit 1; \
	fi; \
	SCRIPT=$(word 1,$(filter-out $@,$(MAKECMDGOALS))); \
	TYPE=$(word 2,$(filter-out $@,$(MAKECMDGOALS))); \
	if [ -z "$$TYPE" ]; then TYPE="patch"; fi; \
	\
	if [ -d "$$SCRIPT" ] && [ -f "$$SCRIPT/version.txt" ]; then \
		echo "Bumping project script: $$SCRIPT"; \
		$(MAKE) bump-project SCRIPT=$$SCRIPT TYPE=$$TYPE; \
	elif [ -f "$$SCRIPT" ] && echo "$$SCRIPT" | grep -q "\.sh$$"; then \
		echo "Bumping simple script: $$SCRIPT"; \
		$(MAKE) bump-simple SCRIPT=$$SCRIPT TYPE=$$TYPE; \
	else \
		echo "Error: $$SCRIPT is not a valid project directory or .sh file"; \
		exit 1; \
	fi

bump-project:
	@CURRENT_VERSION=$$(cat $(SCRIPT)/version.txt); \
	if ! echo "$$CURRENT_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
		echo "Invalid version format in $(SCRIPT)/version.txt ($$CURRENT_VERSION)"; \
		exit 1; \
	fi; \
	MAJOR=$$(echo $$CURRENT_VERSION | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT_VERSION | cut -d. -f2); \
	PATCH=$$(echo $$CURRENT_VERSION | cut -d. -f3); \
	if [ "$(TYPE)" = "patch" ]; then \
		NEW_VERSION="$$MAJOR.$$MINOR.$$((PATCH + 1))"; \
	elif [ "$(TYPE)" = "minor" ]; then \
		NEW_VERSION="$$MAJOR.$$((MINOR + 1)).0"; \
	elif [ "$(TYPE)" = "major" ]; then \
		NEW_VERSION="$$((MAJOR + 1)).0.0"; \
	else \
		echo "Error: Invalid TYPE '$(TYPE)'; use patch, minor, or major"; \
		exit 1; \
	fi; \
	echo "$$CURRENT_VERSION -> $$NEW_VERSION"; \
	echo $$NEW_VERSION > $(SCRIPT)/version.txt; \
	sed -i.bak "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/v$$NEW_VERSION/g" $(SCRIPT)/*.sh 2>/dev/null || true; \
	rm -f $(SCRIPT)/*.sh.bak; \
	git add $(SCRIPT)/version.txt $(SCRIPT)/*.sh; \
	git commit -m "$(SCRIPT): bump to v$$NEW_VERSION"; \
	git tag "$(SCRIPT)-v$$NEW_VERSION"; \
	echo "Successfully tagged $(SCRIPT)-v$$NEW_VERSION"

bump-simple:
	@if [ ! -f "$(SCRIPT)" ]; then \
		echo "Error: Script file $(SCRIPT) does not exist"; \
		exit 1; \
	fi; \
	SCRIPT_NAME=$$(basename $(SCRIPT) .sh); \
	CURRENT_VERSION=$$(grep -E "^# Version: v?[0-9]+\.[0-9]+\.[0-9]+" $(SCRIPT) | sed -E 's/.*v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/' || echo "0.1.0"); \
	if ! echo "$$CURRENT_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
		echo "No valid version found in $(SCRIPT), starting with 0.1.0"; \
		CURRENT_VERSION="0.1.0"; \
	fi; \
	MAJOR=$$(echo $$CURRENT_VERSION | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT_VERSION | cut -d. -f2); \
	PATCH=$$(echo $$CURRENT_VERSION | cut -d. -f3); \
	if [ "$(TYPE)" = "patch" ]; then \
		NEW_VERSION="$$MAJOR.$$MINOR.$$((PATCH + 1))"; \
	elif [ "$(TYPE)" = "minor" ]; then \
		NEW_VERSION="$$MAJOR.$$((MINOR + 1)).0"; \
	elif [ "$(TYPE)" = "major" ]; then \
		NEW_VERSION="$$((MAJOR + 1)).0.0"; \
	else \
		echo "Error: Invalid TYPE '$(TYPE)'; use patch, minor, or major"; \
		exit 1; \
	fi; \
	echo "$$CURRENT_VERSION -> $$NEW_VERSION"; \
	if grep -q "^# Version:" $(SCRIPT); then \
		sed -i.bak "s/^# Version:.*/# Version: v$$NEW_VERSION/" $(SCRIPT); \
	else \
		sed -i.bak "2i\\# Version: v$$NEW_VERSION" $(SCRIPT); \
	fi; \
	rm -f $(SCRIPT).bak; \
	git add $(SCRIPT); \
	git commit -m "$$SCRIPT_NAME: bump to v$$NEW_VERSION"; \
	git tag "$$SCRIPT_NAME-v$$NEW_VERSION"; \
	echo "Successfully tagged $$SCRIPT_NAME-v$$NEW_VERSION"

versions:
	@echo "Current script versions:"
	@echo "======================="
	@echo ""
	@echo "Project Scripts:"
	@find . -maxdepth 2 -name "version.txt" | while read version_file; do \
		project=$$(dirname $$version_file | sed 's|^\./||'); \
		version=$$(cat $$version_file); \
		echo "  $$project: v$$version"; \
	done
	@echo ""
	@echo "Simple Scripts:"
	@find . -name "*.sh" -path "*/install/*" -o -path "*/backup/*" -o -path "*/monitoring/*" | while read script_file; do \
		script_name=$$(basename $$script_file .sh); \
		version=$$(grep -E "^# Version: v?[0-9]+\.[0-9]+\.[0-9]+" $$script_file | sed -E 's/.*v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/' || echo "unversioned"); \
		echo "  $$script_name: v$$version ($$script_file)"; \
	done

# Ignore extra arguments to avoid Make errors
%:
	@:
