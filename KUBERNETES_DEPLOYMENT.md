  # Kubernetes Deployment Guide

## Prerequisites

Before deploying to Kubernetes, ensure you have:
- **kubectl** installed (`curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"`)
- **A Kubernetes cluster** running locally:
  - **Minikube** (`curl -Lo minikube https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64 && chmod +x minikube`)
  - **OR Docker Desktop** with Kubernetes enabled
  - **OR** `kind` (`go install sigs.k8s.io/kind@latest`)

## Setup Steps

### 1. Start Your Local Kubernetes Cluster

**Option A: Using Minikube**
```bash
minikube start
# Enable local image loading
eval $(minikube docker-env)
```

**Option B: Docker Desktop**
- Open Docker Desktop → Settings → Kubernetes → Enable Kubernetes

**Option C: Using Kind**
```bash
kind create cluster --name lab2
```

### 2. Build Docker Images

Navigate to the project root and build your Docker images:

```bash
# Build backend image
docker build -t lab2-backend:latest ./backend

# Build frontend image  
docker build -t lab2-frontend:latest ./frontend
```

**For Minikube only:** Load images into Minikube
```bash
minikube image load lab2-backend:latest
minikube image load lab2-frontend:latest
```

### 3. Deploy to Kubernetes

From the project root, deploy all resources:

```bash
# Using kubectl apply (individual files)
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/database-init-configmap.yaml
kubectl apply -f k8s/database.yaml
kubectl apply -f k8s/database-service.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend.yaml
kubectl apply -f k8s/frontend-service.yaml

# OR using kustomize (all at once)
kubectl apply -k k8s/
```

### 4. Verify Deployment

```bash
# Check all resources in lab2 namespace
kubectl get all -n lab2

# Check pod status
kubectl get pods -n lab2

# Check services
kubectl get svc -n lab2

# View logs from a specific pod
kubectl logs -n lab2 <pod-name>

# Stream logs from all backend pods
kubectl logs -n lab2 -l app=backend -f

# Describe a pod for debugging
kubectl describe pod -n lab2 <pod-name>
```

### 5. Access Your Application

**Option A: Using port-forward (simplest)**
```bash
kubectl port-forward -n lab2 svc/frontend 8080:8080
# Access at http://localhost:8080
```

**Option B: For Minikube with LoadBalancer**
```bash
minikube service frontend -n lab2
# This opens the service URL automatically
```

**Option C: Get the LoadBalancer IP (cloud environments)**
```bash
kubectl get svc -n lab2 frontend
# Wait until EXTERNAL-IP is assigned (may be <pending> locally)
```

## Useful Commands

### View Resources
```bash
# List pods
kubectl get pods -n lab2

# List services
kubectl get svc -n lab2

# List deployments
kubectl get deployments -n lab2

# List StatefulSets
kubectl get statefulsets -n lab2

# List PersistentVolumeClaims
kubectl get pvc -n lab2
```

### Debugging
```bash
# Exec into a pod
kubectl exec -it -n lab2 <pod-name> -- /bin/bash

# View pod events
kubectl describe pod -n lab2 <pod-name>

# View logs
kubectl logs -n lab2 <pod-name>
kubectl logs -n lab2 <pod-name> --tail=50 -f

# Check events
kubectl get events -n lab2 --sort-by='.lastTimestamp'
```

### Database Access
```bash
# Connect to MySQL pod
kubectl exec -it -n lab2 mysql-0 -- mysql -u lab2user -p lab2pass -D lab2db

# Run a query directly
kubectl exec -it -n lab2 mysql-0 -- mysql -u lab2user -p lab2pass -D lab2db -e "SELECT * FROM notes;"
```

### Scaling
```bash
# Scale backend to 3 replicas
kubectl scale deployment -n lab2 backend --replicas=3

# Scale frontend to 3 replicas
kubectl scale deployment -n lab2 frontend --replicas=3

# Check current replicas
kubectl get deployments -n lab2
```

### Cleanup

```bash
# Delete all resources in lab2 namespace
kubectl delete namespace lab2

# Or delete individual resources
kubectl delete -k k8s/
```

## Architecture Overview

The deployment consists of:

- **Database (MySQL)** - StatefulSet with persistent storage
  - 1 replica (stateful)
  - PersistentVolumeClaim for data persistence
  - Headless Service for StatefulSet networking

- **Backend (Flask)** - Deployment
  - 2 replicas for high availability
  - Connected to database via DNS name `mysql`
  - ClusterIP Service for internal networking

- **Frontend (Nginx)** - Deployment
  - 2 replicas for high availability
  - Reverse-proxies to backend via `backend` service DNS
  - LoadBalancer Service for external access

## Key Features

✅ **Database Persistence** - Data survives pod restarts via PVC
✅ **Configuration Management** - ConfigMaps for non-sensitive config
✅ **Secrets Management** - Kubernetes Secrets for credentials
✅ **Health Checks** - Liveness and readiness probes
✅ **Resource Limits** - CPU and memory requests/limits
✅ **Auto-restart** - Automatic pod restart on failure
✅ **Service Discovery** - Internal DNS-based service discovery
✅ **Scalability** - Easy horizontal scaling with kubectl

## Troubleshooting

### Pods not starting?
```bash
kubectl describe pod -n lab2 <pod-name>
kubectl logs -n lab2 <pod-name>
```

### Database connection errors?
- Wait for MySQL pod to be ready: `kubectl get pods -n lab2 -w`
- Check MySQL logs: `kubectl logs -n lab2 mysql-0`
- Verify environment variables in backend deployment

### Cannot access frontend?
```bash
kubectl port-forward -n lab2 svc/frontend 8080:8080
# Then visit http://localhost:8080
```

### Local images not found?
- For Minikube: Use `minikube image load <image-name>`
- Check imagePullPolicy in deployments (should be `Never` for local images)

## Next Steps

1. **Ingress** - Replace LoadBalancer with Ingress for production
2. **Monitoring** - Add Prometheus + Grafana for observability
3. **Logging** - Integrate ELK stack or Loki for centralized logging
4. **Auto-scaling** - Add HorizontalPodAutoscaler (HPA) for dynamic scaling
5. **Registry** - Push images to Docker Hub or container registry
