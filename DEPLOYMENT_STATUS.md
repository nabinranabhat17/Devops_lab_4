# Kubernetes Deployment - Fixed ✅

**Date:** May 13, 2026  
**Status:** All services operational

## Deployment Status

| Component | Status | Ready | Details |
|-----------|--------|-------|---------|
| **MySQL** | ✅ Running | 1/1 | StatefulSet, 5Gi PersistentVolume |
| **Backend** | ✅ Running | 2/2 | Flask API on port 5000, 2 replicas |
| **Frontend** | ✅ Running | 2/2 | Nginx reverse proxy on ports 80/443 |
| **Services** | ✅ Created | 3/3 | backend, frontend (ClusterIP), mysql (Headless) |

## Issues Fixed

### 1. MySQL CrashLoopBackOff (Root Cause: Readiness/Liveness Probe Timing)
**Problem:** 
- MySQL pod was crashing 200+ times due to failed health checks
- Readiness probe ran at `initialDelaySeconds: 10` - too early for MySQL initialization
- Probe was using socket connection `localhost` which failed intermittently

**Solution:**
- ✅ Increased `initialDelaySeconds` for readiness probe: `10s` → `40s`
- ✅ Increased `initialDelaySeconds` for liveness probe: `30s` → `60s`  
- ✅ Changed probe connection from `localhost` to `127.0.0.1` (TCP)
- ✅ Added `--protocol=TCP` flag to mysqladmin command
- **Result:** MySQL now starts cleanly, probes pass on first check ✅

**File Modified:** `k8s/database.yaml`

### 2. Backend DNS Resolution Failure (Root Cause: Stale Pod Replication)
**Problem:**
- Backend pods were 12 days old with 200+ crash attempts
- DNS resolution for `mysql` hostname kept failing
- Old pods had cached/stale service discovery info

**Solution:**
- ✅ Deleted stale backend Deployment
- ✅ Redeployed fresh backend pods
- ✅ Fresh pods immediately resolved `mysql` hostname
- **Result:** Backend connected to MySQL on first attempt ✅

**Evidence from logs:**
```
[DB] Connected on attempt 1
* Running on http://0.0.0.0:5000
GET /api/health HTTP/1.1" 200 -
GET /api/notes HTTP/1.1" 200 -
```

## Frontend Access

**Port-Forward Status:** ✅ Active

```bash
# HTTP (redirects to HTTPS)
http://localhost:8080

# HTTPS (final destination)  
https://localhost:8443
```

**Setup (if needed):**
```bash
kubectl port-forward -n lab2 svc/frontend 8080:8080 8443:443 &
```

**Browser Access:**
1. Navigate to `http://localhost:8080`
2. Will auto-redirect to `https://localhost:8443`
3. Accept self-signed certificate warning (normal)
4. Frontend loads and fetches notes from backend API

## Verification Commands

```bash
# Check all pods are running
kubectl get pods -n lab2

# View service endpoints  
kubectl get svc -n lab2

# Check MySQL health
kubectl logs -n lab2 mysql-0 --tail=10

# Check backend API
kubectl logs -n lab2 -l app=backend --tail=20

# Test API directly from pod
kubectl exec -n lab2 <backend-pod> -- curl -s http://localhost:5000/api/health

# Watch pod status
kubectl get pods -n lab2 -w
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│            Minikube Cluster (lab2)              │
├─────────────────────────────────────────────────┤
│                                                   │
│  ┌──────────────────┐       ┌────────────────┐  │
│  │  Frontend Pods   │       │  Backend Pods  │  │
│  │   (2 replicas)   │───┐   │  (2 replicas)  │  │
│  │   Port 80/443    │   │   │   Port 5000    │  │
│  └──────────────────┘   │   └────────────────┘  │
│           │             │            │          │
│           │             │            │          │
│    HTTP   │             │            │  DB      │
│    Redirect HTTPS       │            │  Queries │
│           │             │            │          │
│  ┌─────────────────────┴────────────────────┐  │
│  │  Services (ClusterIP/Headless)           │  │
│  ├─────────────────────────────────────────┤  │
│  │  frontend: 10.96.24.226:8080/443        │  │
│  │  backend:  10.104.104.245:5000          │  │
│  │  mysql:    mysql-0.mysql:3306           │  │
│  └─────────────────────────────────────────┘  │
│                       │                         │
│  ┌────────────────────┴──────────────────────┐ │
│  │      MySQL StatefulSet                    │ │
│  │  mysql-0 (1/1 Running)                    │ │
│  │  5Gi PersistentVolume                     │ │
│  │  Port 3306                                │ │
│  └───────────────────────────────────────────┘ │
│                                                   │
└─────────────────────────────────────────────────┘
         ↓
    Port-Forward Tunnel
         ↓
localhost:8080 ──→ localhost:8443 (HTTPS)
```

## Notes

- **SSL Certificate:** Self-signed, 365-day validity, generated during frontend container build
- **Database Persistence:** 5Gi PersistentVolume (stored in Minikube)
- **Namespace:** `lab2` (isolated from other workloads)
- **ImagePullPolicy:** Never (local images loaded via `minikube image load`)
- **Pod Restart Limit:** 3 consecutive failures before marking unhealthy

## Cleanup

To remove the deployment:
```bash
kubectl delete namespace lab2
```

---

**Deployment completed successfully!** All services are running and communicating properly.
