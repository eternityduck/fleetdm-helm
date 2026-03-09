# FleetDM Helm Chart

A Helm chart for deploying [FleetDM](https://fleetdm.com/) with MySQL and Redis on Kubernetes.

## Overview

This chart deploys a complete FleetDM stack to a local Kubernetes cluster using Minikube:

- **FleetDM Server** - Device management platform
- **MySQL 8.0** - Primary database
- **Redis 7** - Cache and session storage

Features:
- Automatic database migrations on install
- Persistent storage for MySQL and Redis
- CI/CD with semantic versioning

## Prerequisites

- [Helm](https://helm.sh/docs/intro/install/) v3.x
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- Docker

## Quick Start

### 1. Create Cluster

```bash
make cluster
```

### 2. Install FleetDM

```bash
make install
```

### 3. Access FleetDM

```bash
make port-forward
# Open http://localhost:8080
```

### 4. Cleanup

```bash
make uninstall      # Remove FleetDM
make cluster-delete # Delete cluster
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make cluster` | Create Minikube cluster |
| `make cluster-delete` | Delete Minikube cluster |
| `make install` | Install FleetDM |
| `make uninstall` | Remove FleetDM |
| `make status` | Show deployment status |
| `make port-forward` | Forward to localhost:8080 |
| `make service-url` | Get Minikube service URL |
| `make logs` | Show FleetDM logs |
| `make lint` | Lint Helm chart |
| `make template` | Render templates |
| `make clean` | Delete cluster |

## Configuration

Create `values-override.yaml` to customize:

```yaml
fleet:
  replicaCount: 2
  resources:
    limits:
      cpu: 2
      memory: 4Gi

mysql:
  auth:
    password: secure-password
    rootPassword: secure-root-password
```

Install with overrides:

```bash
helm upgrade --install fleetdm ./charts/fleetdm \
  -n fleetdm --create-namespace \
  -f values-override.yaml
```

### Configuration Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `fleet.replicaCount` | FleetDM replicas | `1` |
| `fleet.image.tag` | FleetDM version | `v4.81.0` |
| `fleet.resources.limits.cpu` | CPU limit | `1` |
| `fleet.resources.limits.memory` | Memory limit | `2Gi` |
| `fleet.tls.enabled` | Enable TLS | `false` |
| `fleet.logging.debug` | Debug logging | `false` |
| `service.type` | Service type | `NodePort` |
| `service.nodePort` | NodePort | `30080` |
| `mysql.auth.password` | MySQL password | `fleet` |
| `mysql.auth.rootPassword` | MySQL root password | `rootpassword` |
| `mysql.persistence.size` | MySQL storage | `8Gi` |
| `redis.persistence.size` | Redis storage | `2Gi` |
| `redis.auth.enabled` | Enable Redis auth | `false` |

## Verification

Check pods are running:

```bash
kubectl get pods -n fleetdm
```

Expected:

```
NAME                       READY   STATUS    RESTARTS   AGE
fleetdm-xxx                1/1     Running   0          5m
fleetdm-mysql-0            1/1     Running   0          5m
fleetdm-redis-0            1/1     Running   0          5m
```

Test health endpoint:

```bash
make port-forward &
curl http://localhost:8080/healthz
```

Test MySQL:

```bash
kubectl exec -it -n fleetdm fleetdm-mysql-0 -- \
  mysql -ufleet -pfleet -e "SHOW DATABASES;"
```

Test Redis:

```bash
kubectl exec -it -n fleetdm fleetdm-redis-0 -- redis-cli PING
# Expected: PONG
```

## First-Time Setup

1. Open FleetDM in browser (http://localhost:8080)
2. Create admin account
3. Configure organization
4. Enroll devices

## Troubleshooting

**Pods not starting:**

```bash
kubectl describe pod -n fleetdm <pod-name>
```

**Migration issues:**

```bash
kubectl logs -n fleetdm -l app.kubernetes.io/component=server -c db-migration
```

**Reset installation:**

```bash
make uninstall && make install
```

## Architecture

```
┌────────────────────────────────────────────────┐
│              Minikube Cluster                  │
│  ┌──────────────────────────────────────────┐  │
│  │           fleetdm namespace              │  │
│  │                                          │  │
│  │  ┌──────────┐ ┌─────────┐ ┌──────────┐  │  │
│  │  │ FleetDM  │ │  MySQL  │ │  Redis   │  │  │
│  │  │  Server  │─│  (8.0)  │ │(7-alpine)│  │  │
│  │  └────┬─────┘ └─────────┘ └──────────┘  │  │
│  │       │                                  │  │
│  │  ┌────▼─────┐                           │  │
│  │  │ Service  │                           │  │
│  │  │ :30080   │                           │  │
│  │  └──────────┘                           │  │
│  └──────────────────────────────────────────┘  │
└────────────────────────────────────────────────┘
```

## Contributing

1. Fork repository
2. Create feature branch
3. Run `make lint`
4. Submit pull request

Use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` - Minor version bump
- `fix:` - Patch version bump
- `BREAKING CHANGE:` - Major version bump

## License

MIT License - See [LICENSE](LICENSE)

## Resources

- [FleetDM Docs](https://fleetdm.com/docs)
- [FleetDM GitHub](https://github.com/fleetdm/fleet)
- [Helm Docs](https://helm.sh/docs/)
- [Minikube Docs](https://minikube.sigs.k8s.io/docs/)
