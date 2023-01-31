BUILD_SUBPATH ?=dev
BUILD_ID ?=$(shell test -d .git && git rev-parse HEAD | cut -c -8)
REF_ID ?=$(shell test -d .git \
	 && git symbolic-ref --short HEAD \
	 | sed -e 's/[^a-z0-9]/-/g' -e 's/^[-+]//' -e 's/[-+]$$//' \
	 | cut -c 1-62)

default: help
include makefiles/install.mk
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

check: ##- Run tests
