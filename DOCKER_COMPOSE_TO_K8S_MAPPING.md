# Docker Compose to Kubernetes Mapping

This guide shows how your `docker-compose.yml` translates to Kubernetes manifests.

## Overview

| Docker Compose | Kubernetes | Purpose |
|---|---|---|
| services | Deployments/StatefulSets | Workloads |
| depends_on | Init containers / pod scheduling | Dependencies |
| networks | Namespace + Services | Networking |
| volumes | PersistentVolumes/PersistentVolumeClaims | Storage |
| environment | ConfigMaps + Secrets | Configuration |
| ports | Services | Port exposure |
| image | Container spec | Container image |

## Detailed Mapping

### 1. Database Service → MySQL StatefulSet

**Docker Compose:**
```yaml
db:
  image: mysql:8.0
  environment:
    MYSQL_ROOT_PASSWORD: rootpassword
    MYSQL_DATABASE: lab2db
  volumes:
    - db_data:/var/lib/mysql
    - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql
```

**Kubernetes Equivalents:**
- `database.yaml` - StatefulSet for MySQL
- `database-service.yaml` - Headless Service
- `secret.yaml` - Stores credentials (MYSQL_ROOT_PASSWORD)
- `configmap.yaml` - Stores MYSQL_DATABASE
- `database-init-configmap.yaml` - Stores init.sql script
- `database-pvc.yaml` - Persistent storage

**Key Differences:**
- Kubernetes uses StatefulSet for ordered, stable identity
- Secrets store sensitive data separately
- ConfigMaps for non-sensitive data
- PersistentVolumeClaim for storage persistence

---

### 2. Backend Service → Flask Deployment

**Docker Compose:**
```yaml
backend:
  build:
    context: ./backend
    dockerfile: Dockerfile
  environment:
    DB_HOST: db
    DB_USER: lab2user
    DB_PASSWORD: lab2pass
  depends_on:
    db:
      condition: service_healthy
  networks:
    - app_network
```

**Kubernetes Equivalents:**
- `backend.yaml` - Deployment with 2 replicas
- `backend-service.yaml` - ClusterIP Service for internal DNS
- `configmap.yaml` & `secret.yaml` - Environment variables
- Replicas handle redundancy (equivalent to compose scale)

**Key Differences:**
- Deployment allows multiple replicas
- Service provides stable DNS name
- Environment variables from ConfigMap/Secrets
- healthcheck becomes livenessProbe/readinessProbe

---

### 3. Frontend Service → Nginx Deployment

**Docker Compose:**
```yaml
frontend:
  build:
    context: ./frontend
    dockerfile: Dockerfile
  ports:
    - "8080:80"
    - "443:443"
  depends_on:
    - backend
  networks:
    - app_network
```

**Kubernetes Equivalents:**
- `frontend.yaml` - Deployment with 2 replicas
- `frontend-service.yaml` - LoadBalancer Service
- `nginx-configmap.yaml` - Nginx configuration

**Key Differences:**
- Deployment replaces build + scaling
- LoadBalancer exposes to external traffic
- No direct port mapping (Services manage it)

---

## Configuration Management

### Environment Variables

**Docker Compose:**
```yaml
environment:
  DB_HOST: db
  DB_PASSWORD: secret123
```

**Kubernetes:**
```yaml
# Non-sensitive → ConfigMap (k8s/configmap.yaml)
env:
- name: DB_HOST
  valueFrom:
    configMapKeyRef:
      name: db-config
      key: DB_HOST

# Sensitive → Secret (k8s/secret.yaml)
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-credentials
      key: DB_PASSWORD
```

### Network Connectivity

**Docker Compose:**
- Internal bridge network `app_network`
- Services resolve by name: `db`, `backend`, `frontend`

**Kubernetes:**
- All pods in same namespace can reach each other by service name
- DNS: `<service-name>.<namespace>.svc.cluster.local`
- Within namespace: just `<service-name>`

### Storage

**Docker Compose:**
```yaml
volumes:
  db_data:
    driver: local
services:
  db:
    volumes:
      - db_data:/var/lib/mysql
```

**Kubernetes:**
- StatefulSet uses volumeClaimTemplates (automatic)
- Data persists even if pod is deleted
- PVC survives StatefulSet deletion

---

## Deployment Process

### Docker Compose
```bash
docker compose build
docker compose up
```

### Kubernetes
```bash
# 1. Build images
docker build -t lab2-backend:latest ./backend
docker build -t lab2-frontend:latest ./frontend

# 2. Deploy
kubectl apply -k k8s/

# 3. Verify
kubectl get all -n lab2

# 4. Access
kubectl port-forward svc/frontend 8080:8080
```

---

## Scaling

### Docker Compose
```bash
docker compose scale backend=3
# Limited to single host
```

### Kubernetes
```bash
kubectl scale deployment backend -n lab2 --replicas=3
# Can scale across multiple nodes
```

---

## Health Checks

### Docker Compose
```yaml
healthcheck:
  test: ["CMD", "mysqladmin", "ping"]
  interval: 10s
  timeout: 5s
  retries: 5
```

### Kubernetes
```yaml
livenessProbe:
  exec:
    command: [mysqladmin, ping]
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /api/health
  initialDelaySeconds: 10
  periodSeconds: 5
```

- **livenessProbe**: Is the container alive? (restart if not)
- **readinessProbe**: Ready to receive traffic? (exclude from load balancing if not)

---

## Service Exposure

### Docker Compose
```yaml
ports:
  - "8080:80"  # Host port to container port
```

### Kubernetes
- **ClusterIP** (default) - Internal only (backend, db)
- **LoadBalancer** - External access (frontend)
- **NodePort** - Access via node IP + port
- **Ingress** - HTTP/HTTPS routing (production)

---

## Key Kubernetes Benefits

1. **Multi-host scaling** - Run across multiple servers
2. **Auto-healing** - Restart failed pods
3. **Rolling updates** - Zero-downtime deployments
4. **Resource management** - Requests and limits
5. **Service discovery** - Automatic DNS
6. **Secret management** - Encrypted configuration
7. **Persistent storage** - Data survives restarts
8. **Monitoring** - Built-in observability hooks

---

## Next Steps

1. **Custom Domain** - Add Ingress resource for custom hostname
2. **TLS/SSL** - Use cert-manager for automatic certificates
3. **Auto-scaling** - Add HorizontalPodAutoscaler (HPA)
4. **Monitoring** - Install Prometheus + Grafana
5. **Container Registry** - Push images to registry (instead of local)
6. **GitOps** - Use ArgoCD or Flux for declarative deployments
