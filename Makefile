# Comandos del equipo. Escribe `make` para ver la lista.
.DEFAULT_GOAL := help
SHELL := /bin/bash

help: ## Muestra esta ayuda
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-10s %s\n", $$1, $$2}'

setup: ## Instala todo desde cero en una máquina nueva
	@scripts/setup.sh

update: ## Trae los cambios del equipo (git pull) y los aplica
	@scripts/update.sh

start: ## Enciende la plataforma
	@source scripts/common.sh && "$$TUTOR" dev start -d

stop: ## Apaga la plataforma
	@source scripts/common.sh && "$$TUTOR" dev stop

restart: ## Reinicia el LMS y Studio (tras cambiar código montado)
	@source scripts/common.sh && "$$TUTOR" dev restart lms cms

logs: ## Muestra los logs del LMS
	@source scripts/common.sh && "$$TUTOR" dev logs -f --tail=100 lms

shell: ## Abre una consola de Django en el LMS
	@source scripts/common.sh && "$$TUTOR" dev run lms ./manage.py lms shell

admin: ## Crea un superusuario: make admin USER_NAME=admin EMAIL=tu@correo.com
	@source scripts/common.sh && "$$TUTOR" dev do createuser --staff --superuser $(or $(USER_NAME),admin) $(or $(EMAIL),admin@local.openedx.io)

tutor: ## Ejecuta cualquier comando de Tutor de este proyecto: make tutor ARGS="config printvalue LMS_HOST"
	@source scripts/common.sh && "$$TUTOR" $(ARGS)

backup: ## Respalda usuarios y cursos en backups/
	@scripts/backup.sh

restore: ## Restaura un respaldo: make restore BACKUP=backups/...
	@scripts/restore.sh "$(BACKUP)"

doctor: ## Muestra versiones y estado para comparar con el equipo
	@scripts/doctor.sh

.PHONY: help setup update start stop restart logs shell admin tutor backup restore doctor
