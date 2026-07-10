# Projects: <app>:<version-slug>  →  folder v<version-slug>, target <app>-<version-slug>
# Short targets (make shell-<app>) work when the app exists in only one version.
PROJECTS = \
	hello_world:3-3-1 \
	hello_world:2-9-2 \
	blink_led:3-3-1

project_target = $(subst :,-,$(1))
project_app    = $(word 1,$(subst :, ,$(1)))
project_ver    = v$(word 2,$(subst :, ,$(1)))

find_project     = $(firstword $(foreach p,$(PROJECTS),$(if $(filter $(call project_target,$(p)),$(1)),$(p),)))
projects_for_app = $(foreach p,$(PROJECTS),$(if $(filter $(call project_app,$(p)),$(1)),$(p),))

resolve_project = \
	$(if $(strip $(call find_project,$(1))),\
		$(call find_project,$(1)),\
		$(if $(filter 1,$(words $(call projects_for_app,$(1)))),\
			$(firstword $(call projects_for_app,$(1))),))

define check_project
	$(eval _PROJ := $(call resolve_project,$(1)))
	@if [ -z "$(_PROJ)" ]; then \
		if [ -n "$(strip $(call projects_for_app,$(1)))" ]; then \
			echo "Error: '$(1)' exists in multiple versions. Use:"; \
			$(foreach p,$(call projects_for_app,$(1)),echo "  make $(2)-$(call project_target,$(p))";) \
			exit 1; \
		else \
			echo "Error: unknown project '$(1)'"; \
			echo "Run 'make help' to list configured projects."; \
			exit 1; \
		fi; \
	fi
	@if [ ! -d "$(call project_ver,$(_PROJ))/apps/$(call project_app,$(_PROJ))" ]; then \
		echo "Error: app '$(call project_app,$(_PROJ))' not found in $(call project_ver,$(_PROJ))/apps/"; \
		exit 1; \
	fi
endef

.PHONY: help image-% shell-%

help:
	@echo "Targets:"
	@echo "  make image-<app>-<version>   Build the NCS Docker image"
	@echo "  make shell-<app>-<version>   Interactive shell (west inside; no make in container)"
	@echo ""
	@echo "When an app exists in only one version, the short form also works:"
	@echo "  make image-<app>   make shell-<app>"
	@echo ""
	@echo "Configured projects:"
	@$(foreach p,$(PROJECTS),echo "  $(call project_target,$(p))  ($(call project_app,$(p)) on $(call project_ver,$(p)))";)

image-%:
	$(call check_project,$*,image)
	docker compose -f $(call project_ver,$(_PROJ))/docker-compose.yml build

shell-%:
	$(call check_project,$*,shell)
	docker compose -f $(call project_ver,$(_PROJ))/docker-compose.yml run --rm ncs '/shared/container-shell.sh $(call project_app,$(_PROJ))'
