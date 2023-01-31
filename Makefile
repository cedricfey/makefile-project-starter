BUILD_SUBPATH ?=dev
BUILD_ID ?=$(shell test -d .git && git rev-parse HEAD | cut -c -8)
REF_ID ?=$(shell test -d .git \
	 && git symbolic-ref --short HEAD \
	 | sed -e 's/[^a-z0-9]/-/g' -e 's/^[-+]//' -e 's/[-+]$$//' \
	 | cut -c 1-62)

default: help
include makefiles/*.mk

ci-build: docker-pull docker-build
ci-push: docker-push
ci-push-release: docker-pull-final docker-push-release

.PHONY: start
start: docker-compose-pull docker-compose-start ##- Start
.PHONY: deploy
deploy: docker-compose-pull docker-compose-deploy ##- Deploy (start remotely)
.PHONY: stop
stop: docker-compose-stop ##- Stop

# check: ##- Run tests

## Tests

test-most:
	@$(MAKE) dockerized-test-setup
	@$(MAKE) -e stage=test dockerized-rails-test
	@$(MAKE) dockerized-test-teardown

test-system:
	@$(MAKE) dockerized-test-setup
	@$(MAKE) -e stage=test dockerized-rails-test-system
	@$(MAKE) dockerized-test-teardown

.PHONY: set-test-docker-compose-files
set-test-docker-compose-files:
	$(eval compose_files=-f docker-compose.yml -f docker-compose.test.yml)
	$(eval TEST_IMAGE?=${REGISTRY_PROJECT_URL}/${BUILD_SUBPATH}:${BUILD_ID}-test)

dockerized-test-setup:
	@$(MAKE) -e stage=test generate-env dockerized-test-init

dockerized-test-init: environment test-docker-compose-clean
	@$(load_env); \
		set -eux; \
		export TEST_IMAGE=${TEST_IMAGE}; \
		docker-compose ${compose_files} up -d; \
		docker-compose ${compose_files} run rails bundle exec sh -c " \
			rm -rf coverage; \
			bundle exec rake db:migrate \
		"

dockerized-test-teardown:
	@$(MAKE) -e stage=test test-docker-compose-clean

test-docker-compose-clean: set-test-docker-compose-files docker-compose-clean

.PHONY: dockerized-rails-test
dockerized-rails-test: environment set-test-docker-compose-files
	@$(load_env); \
		set -eux; \
		export TEST_IMAGE=${TEST_IMAGE}; \
		docker-compose ${compose_files} run rails \
			env RAILS_ENV=test bundle exec rake test

.PHONY: dockerized-rails-test-system
dockerized-rails-test-system: environment set-test-docker-compose-files
	@$(load_env); \
		set -eux; \
		export TEST_IMAGE=${TEST_IMAGE}; \
		docker-compose ${compose_files} run rails \
			env RAILS_ENV=test bundle exec rake test:system

## Deployments

.PHONY: build
build: docker-compose-build

.PHONY: start
start: docker-compose-pull docker-compose-start ##- Start

.PHONY: deploy
deploy: deploy-scalingo ##- alias for deploy-scalingo

.PHONY: deploy-scalingo
deploy-scalingo: scalingo-deploy-current-branch ##- Deploy on Scalingo

.PHONY: stop
stop: docker-compose-stop ##- Stop

## Debug

.PHONY: logs
logs: docker-compose-logs ##- Logs

.PHONY: logs-scalingo
logs-scalingo: scalingo-logs ##- Logs

.PHONY: backup-db
backup-db: scalingo-postgresql-backup ##- Backup database

.PHONY: clean
clean: docker-compose-clean ##- Stop and remove volumes

.PHONY: status
status: docker-compose-ps ##- Print container's status

.PHONY: console
console: environment ##- Enter console
	-$(load_env); docker-compose ${compose_files} exec rails /bin/ash

.PHONY: local-start
local-start: set-local-docker-compose-files docker-compose-build docker-compose-start ##- Build and start
	@$(load_env); docker-compose exec rails sh -c "[ -x ./docker.local.sh ] && sudo ./docker.local.sh; true"

.PHONY: local-ports
local-ports: environment ##- Display available local ports
	@echo 'Local ports:'
	@$(load_env); env | grep LOCAL_PORT | sed -e 's/^LOCAL_PORT_/ - /' -e 's/=/: /'

.PHONY: local-reset
local-reset:
	echo 'Prune existing volumes...'
	$(MAKE) local-clean
	echo 'Start container...'
	$(MAKE) local-start
	echo 'Ready!'
