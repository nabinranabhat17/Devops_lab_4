# 📦 Kubernetes Deployment Complete!

I've successfully created a complete Kubernetes deployment setup for your multi-container app.

## What Was Created

### 📁 Kubernetes Manifests (`k8s/` directory)

**Database Layer:**
- `namespace.yaml` - lab2 namespace
- `configmap.yaml` - Database config (non-sensitive)
- `secret.yaml` - Database credentials (sensitive)
- `database-init-configmap.yaml` - MySQL init script (SQL)
- `database.yaml` - MySQL StatefulSet (1 replica)
- `database-service.yaml` - MySQL headless service
- `database-pvc.yaml` - Persistent volume claim

**Backend Layer:**
- `backend.yaml` - Flask API Deployment (2 replicas)
- `backend-service.yaml` - Backend service (ClusterIP)

**Frontend Layer:**
- `frontend.yaml` - Nginx Deployment (2 replicas)
- `frontend-service.yaml` - Frontend service (LoadBalancer)
- `nginx-configmap.yaml` - Nginx proxy configuration

**Orchestration:**
- `kustomization.yaml` - All resources bundled together

### 📚 Documentation

- **[KUBERNETES_DEPLOYMENT.md](KUBERNETES_DEPLOYMENT.md)** - Full setup guide with detailed instructions
- **[KUBERNETES_QUICK_REFERENCE.md](KUBERNETES_QUICK_REFERENCE.md)** - Common commands cheat sheet
- **[DOCKER_COMPOSE_TO_K8S_MAPPING.md](DOCKER_COMPOSE_TO_K8S_MAPPING.md)** - How your Docker Compose setup maps to Kubernetes

### 🚀 Deployment Script

- **deploy-k8s.sh** - Automated one-script deployment

## Quick Start

### Option 1: Automated Script (Recommended)
```bash
chmod +x deploy-k8s.sh
./deploy-k8s.sh
```

### Option 2: Manual Deployment

**1. Start Kubernetes**
```bash
# Minikube
minikube start

# OR Docker Desktop
# Enable Kubernetes in Settings

# OR Kind
kind create cluster --name lab2
```

**2. Build Docker Images**
```bash
docker build -t lab2-backend:latest ./backend
docker build -t lab2-frontend:latest ./frontend

# For Minikube, load images
minikube image load lab2-backend:latest
minikube image load lab2-frontend:latest
```

**3. Deploy**
```bash
kubectl apply -k k8s/
```

**4. Access Application**
```bash
# Option A: Port forward
kubectl port-forward -n lab2 svc/frontend 8080:8080
# Visit http://localhost:8080

# Option B: Minikube
minikube service frontend -n lab2
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Kubernetes Lab2 Namespace                      │
├─────────────────────────────────────────────────┤
│                                                  │
│  Frontend (Nginx × 2)                           │
│  └─ Service: LoadBalancer (8080:80, 443:443)   │
│     └─ Proxy to Backend                         │
│                                                  │
│  Backend (Flask × 2)                            │
│  └─ Service: ClusterIP (5000)                   │
│     └─ Connected to MySQL                       │
│                                                  │
│  Database (MySQL × 1 StatefulSet)               │
│  └─ Service: Headless (3306)                    │
│  └─ PersistentVolumeClaim: 5Gi                  │
│                                                  │
└─────────────────────────────────────────────────┘
```

## Key Features ✅

- ✅ **2 replicas** of backend and frontend for high availability
- ✅ **Persistent storage** for database (survives pod restarts)
- ✅ **Health checks** (liveness and readiness probes)
- ✅ **Resource limits** for efficient cluster usage
- ✅ **Auto-restart** on failure
- ✅ **Service discovery** via DNS
- ✅ **ConfigMaps & Secrets** for secure configuration
- ✅ **StatefulSet** for database ordering and identity

## Useful Commands

```bash
# View all resources
kubectl get all -n lab2

# View pods
kubectl get pods -n lab2

# Stream logs
kubectl logs -n lab2 -l app=backend -f

# Access pod
kubectl exec -it -n lab2 <pod-name> -- bash

# Scale deployments
kubectl scale deployment backend -n lab2 --replicas=3

# Cleanup
kubectl delete namespace lab2
```

## Troubleshooting

### Pods not starting?
```bash
kubectl describe pod -n lab2 <pod-name>
```

### Can't access frontend?
```bash
kubectl port-forward -n lab2 svc/frontend 8080:8080
# Visit http://localhost:8080
```

### Database connection issues?
```bash
kubectl logs -n lab2 mysql-0
kubectl logs -n lab2 -l app=backend
```

### Need to run SQL commands?
```bash
kubectl exec -it -n lab2 mysql-0 -- mysql -u lab2user -p lab2pass -D lab2db -e "SELECT * FROM notes;"
```

## File Structure

```
multi-container/
├── docker-compose.yml
├── backend/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── index.html
│   ├── nginx.conf
│   └── Dockerfile
├── db/
│   └── init.sql
├── k8s/                           ← NEW: Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── database*.yaml
│   ├── backend*.yaml
│   ├── frontend*.yaml
│   ├── nginx-configmap.yaml
│   └── kustomization.yaml
├── deploy-k8s.sh                  ← NEW: Deployment script
├── KUBERNETES_DEPLOYMENT.md       ← NEW: Full guide
├── KUBERNETES_QUICK_REFERENCE.md  ← NEW: Cheat sheet
└── DOCKER_COMPOSE_TO_K8S_MAPPING.md ← NEW: Mapping guide
```

## Next Steps

1. **Deploy to your cluster** using the quick start commands
2. **Test the application** via http://localhost:8080
3. **Scale services** as needed with kubectl scale
4. **Add monitoring** with Prometheus + Grafana
5. **Set up CI/CD** with automated image builds and deployments

## Learn More

- [Kubernetes Documentation](https://kubernetes.io/docs)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [StatefulSets vs Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)

---

**Questions?** Check the docs:
- 📖 For setup steps → `KUBERNETES_DEPLOYMENT.md`
- 🔍 For quick commands → `KUBERNETES_QUICK_REFERENCE.md`
- 🔄 For Docker Compose comparison → `DOCKER_COMPOSE_TO_K8S_MAPPING.md`
