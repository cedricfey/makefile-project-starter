include default.config

env.sh: default.config doc/examples/env.sh
	@cp doc/examples/env.sh env.sh
	@sed -i \
		-e 's|<APP_NAME>|${APP_NAME}|g' \
		-e 's|<PROJECT_NAME>|${PROJECT_NAME}|g' \
		-e 's|<SCALINGO_APP_NAME>|${SCALINGO_APP_NAME}|g' \
		-e 's|<APP_IMAGE>|${APP_IMAGE}|g' \
		env.sh

docker-compose.yml:
	@cp doc/examples/docker-compose.yml $@
	@sed -i \
		-e 's|<APP_IMAGE>|${APP_IMAGE}|g' \
		$@

docker-compose.test.yml:
	@cp doc/examples/docker-compose.test.yml $@

docker-compose.local.yml:
	@cp doc/examples/docker-compose.local.yml $@

docker-compose.traefik.yml:
	@cp doc/examples/docker-compose.traefik.yml $@

.PHONY: install
install: env.sh docker-compose.yml docker-compose.test.yml docker-compose.local.yml docker-compose.traefik.yml

.PHONY: clean
clean:
	rm env.sh

default.config:
	@echo -n "App name? " && read name &&  echo "APP_NAME=$${name}" > $@ && \
	echo -n "Project name? ($${name})" && read project_name &&  echo "PROJECT_NAME=$${project_name:-$$name}" >> $@ && \
	echo -n "Scalingo app name? ($${name})" && read scalingo_app_name &&  echo "SCALINGO_APP_NAME=$${scalingo_app_name:-$$name}" >> $@ && \
	echo -n "Registry url? (localhost/$${name})" && read registry_project_url &&  echo "REGISTRY_PROJECT_URL=$${registry_project_url:-localhost/$$name}" >> $@
	echo -n "App image? (localhost/$${name}:latest)" && read app_image &&  echo "APP_IMAGE=$${app_image:-localhost/$$name:latest}" >> $@

# @echo -n "Are you sure? [y/N] " && read ans && if [ $${ans:-'N'} = 'y' ]; then make ENV=test spec-tests; fi