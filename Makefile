.SILENT:
.DEFAULT_GOAL := help

COLOR_RESET = \033[0m
COLOR_COMMAND = \033[36m
COLOR_YELLOW = \033[33m
COLOR_GREEN = \033[32m
COLOR_RED = \033[31m

PROJECT := Sample App

## Installs a development environment
install: deploy

## Build the sample-app image
build:
	$(eval $(minikube -p minikube docker-env))
	docker build . --tag sample-app

## Deploy sample-app
deploy-app: build
	$(eval $(minikube -p minikube docker-env))
	kubectl apply -f .k8s/app/

## Deploy db
deploy-db:
	kubectl apply -f .k8s/db/

## Deploy the K8s manifests to your cluster
deploy: deploy-app deploy-db
	kubectl rollout status statefulset/mysql
	kubectl wait --for=condition=available --timeout=600s deployment --all

## Port forward the flast app
serve: deploy
	kubectl port-forward svc/sample-app-service 8080:80

## Cleanup the deployments
cleanup:
	kubectl delete -f .k8s/ -R

## Prints help message
help:
	printf "\n${COLOR_YELLOW}${PROJECT}\n------\n${COLOR_RESET}"
	awk '/^[a-zA-Z\-\_0-9\.%]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "${COLOR_COMMAND}$$ make %s${COLOR_RESET} %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort
	printf "\n"