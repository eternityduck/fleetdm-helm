.PHONY: cluster install uninstall lint template clean port-forward status help

CLUSTER_NAME ?= fleetdm-local
NAMESPACE ?= fleetdm
RELEASE_NAME ?= fleetdm
CHART_PATH ?= ./charts/fleetdm
HELM_TIMEOUT ?= 10m

help: ## Show this help message
	@echo "FleetDM Helm Chart - Local Kubernetes Deployment"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

cluster: ## Create a local Minikube cluster
	@echo "Creating Minikube cluster: $(CLUSTER_NAME)"
	@minikube start -p $(CLUSTER_NAME) --memory=4096 --cpus=2 --driver=docker
	@kubectl cluster-info --context $(CLUSTER_NAME)
	@echo ""
	@echo "Cluster $(CLUSTER_NAME) is ready!"

cluster-delete: ## Delete the local Minikube cluster
	@echo "Deleting Minikube cluster: $(CLUSTER_NAME)"
	@minikube delete -p $(CLUSTER_NAME)

lint: ## Lint the Helm chart
	@echo "Linting Helm chart..."
	@helm lint $(CHART_PATH)

template: ## Render Helm templates locally
	@echo "Rendering Helm templates..."
	@helm template $(RELEASE_NAME) $(CHART_PATH) --namespace $(NAMESPACE)

install: ## Install FleetDM Helm chart to the cluster
	@echo "Creating namespace $(NAMESPACE) if it doesn't exist..."
	@kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "Installing FleetDM Helm chart..."
	@helm upgrade --install $(RELEASE_NAME) $(CHART_PATH) \
		--namespace $(NAMESPACE) \
		--timeout $(HELM_TIMEOUT) \
		--wait
	@echo ""
	@echo "Installation complete! Run 'make status' to check the deployment."
	@echo "Run 'make port-forward' to access FleetDM at http://localhost:8080"

uninstall: ## Remove all deployed resources
	@echo "Uninstalling FleetDM Helm chart..."
	@helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE) || true
	@echo "Deleting namespace $(NAMESPACE)..."
	@kubectl delete namespace $(NAMESPACE) --ignore-not-found
	@echo "Uninstallation complete!"

status: ## Show deployment status
	@echo "=== Helm Release Status ==="
	@helm status $(RELEASE_NAME) --namespace $(NAMESPACE) 2>/dev/null || echo "Release not found"
	@echo ""
	@echo "=== Pods ==="
	@kubectl get pods -n $(NAMESPACE) -o wide 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "=== Services ==="
	@kubectl get svc -n $(NAMESPACE) 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "=== PVCs ==="
	@kubectl get pvc -n $(NAMESPACE) 2>/dev/null || echo "Namespace not found"

port-forward: ## Forward FleetDM port to localhost:8080
	@echo "Forwarding FleetDM to http://localhost:8080"
	@echo "Press Ctrl+C to stop"
	@kubectl port-forward -n $(NAMESPACE) svc/$(RELEASE_NAME) 8080:8080

service-url: ## Get FleetDM service URL via Minikube
	@echo "FleetDM URL:"
	@minikube -p $(CLUSTER_NAME) service $(RELEASE_NAME) -n $(NAMESPACE) --url
