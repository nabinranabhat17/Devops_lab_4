# Kubernetes Quick Reference

## One-Liner Deployment

```bash
# Build images and deploy everything
docker build -t lab2-backend:latest ./backend && \
docker build -t lab2-frontend:latest ./frontend && \
kubectl apply -k k8s/
```

## Start to Finish (Minikube)

```bash
# 1. Start Minikube
minikube start

# 2. Load environment
eval $(minikube docker-env)

# 3. Build images (directly into Minikube)
docker build -t lab2-backend:latest ./backend
docker build -t lab2-frontend:latest ./frontend

# 4. Deploy
kubectl apply -k k8s/

# 5. Open in browser
minikube service frontend -n lab2
```

## Start to Finish (Docker Desktop)

```bash
# 1. Build images
docker build -t lab2-backend:latest ./backend
docker build -t lab2-frontend:latest ./frontend

# 2. Deploy
kubectl apply -k k8s/

# 3. Access via port-forward
kubectl port-forward -n lab2 svc/frontend 8080:8080
# Visit: http://localhost:8080
```

## Common Operations

### View Status
```bash
kubectl get all -n lab2              # All resources
kubectl get pods -n lab2             # Just pods
kubectl get svc -n lab2              # Just services
kubectl get pvc -n lab2              # Persistent volumes
kubectl get events -n lab2 -w        # Watch events
```

### Access Application
```bash
kubectl port-forward -n lab2 svc/frontend 8080:8080
# Visit: http://localhost:8080
```

### View Logs
```bash
kubectl logs -n lab2 <pod-name>                    # One pod
kubectl logs -n lab2 -l app=backend -f             # Stream backend
kubectl logs -n lab2 -l app=frontend --tail=50    # Last 50 lines
```

### Execute Commands in Pods
```bash
kubectl exec -it -n lab2 <pod-name> -- bash       # Shell
kubectl exec -n lab2 mysql-0 -- mysql -u lab2user -p lab2pass -e "SELECT * FROM notes;"
```

### Scale Deployments
```bash
kubectl scale deployment backend -n lab2 --replicas=3
kubectl scale deployment frontend -n lab2 --replicas=3
```

### Update Deployments
```bash
# Edit a deployment
kubectl edit deployment backend -n lab2

# Restart a deployment
kubectl rollout restart deployment/backend -n lab2

# Rollback to previous version
kubectl rollout undo deployment/backend -n lab2
```

### Debugging
```bash
kubectl describe pod -n lab2 <pod-name>    # Full details
kubectl get pod -n lab2 <pod-name> -o yaml # YAML spec
kubectl logs -n lab2 <pod-name> --previous # Previous container logs
```

### Cleanup
```bash
kubectl delete namespace lab2              # Delete everything
kubectl delete -k k8s/                     # Delete via kustomize
```

## Pod Status Reference

| Status | Meaning |
|--------|---------|
| **Pending** | Pod created, waiting to be scheduled |
| **Running** | Pod is running |
| **Succeeded** | Pod completed successfully (Jobs) |
| **Failed** | Pod encountered an error |
| **CrashLoopBackOff** | Pod keeps crashing and restarting |
| **ImagePullBackOff** | Can't pull container image |
| **ErrImagePull** | Error pulling image |

## Troubleshooting Checklist

- [ ] Kubernetes cluster running? `kubectl cluster-info`
- [ ] Images built? `docker images | grep lab2`
- [ ] Images loaded (Minikube)? `minikube image ls | grep lab2`
- [ ] Pods running? `kubectl get pods -n lab2`
- [ ] Services created? `kubectl get svc -n lab2`
- [ ] Database ready? `kubectl logs -n lab2 mysql-0`
- [ ] Backend connecting to DB? `kubectl logs -n lab2 -l app=backend`
- [ ] Frontend proxying correctly? `kubectl logs -n lab2 -l app=frontend`

## File Structure

```
k8s/
├── namespace.yaml              # lab2 namespace
├── configmap.yaml              # Database config
├── secret.yaml                 # DB credentials
├── database-init-configmap.yaml # SQL init script
├── database.yaml               # MySQL StatefulSet
├── database-service.yaml       # MySQL Service (headless)
├── database-pvc.yaml           # Database storage
├── backend.yaml                # Flask Deployment
├── backend-service.yaml        # Backend Service (ClusterIP)
├── nginx-configmap.yaml        # Nginx configuration
├── frontend.yaml               # Nginx Deployment
├── frontend-service.yaml       # Frontend Service (LoadBalancer)
└── kustomization.yaml          # Kustomize manifest
```

## Key Differences: Docker Compose vs Kubernetes

| Feature | Docker Compose | Kubernetes |
|---------|----------------|-----------|
| **Scale** | Limited | Production-ready |
| **Auto-restart** | Basic | Advanced with probes |
| **Secrets** | env files | Kubernetes Secrets |
| **Storage** | Named volumes | PersistentVolumeClaims |
| **Networking** | Internal bridge | Service discovery + DNS |
| **Configuration** | docker-compose.yml | Multiple YAML files |
| **Orchestration** | Single host | Multi-node clusters |

## Network Names

Inside Kubernetes, services are accessible via DNS:

- MySQL: `mysql.lab2.svc.cluster.local` or just `mysql`
- Backend: `backend.lab2.svc.cluster.local` or just `backend`
- Frontend: `frontend.lab2.svc.cluster.local` or just `frontend`

(The namespace `lab2` is implicit when in the same namespace)
