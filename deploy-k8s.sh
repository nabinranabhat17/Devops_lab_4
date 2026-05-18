#!/bin/bash
# Quick Kubernetes deployment script

set -e

echo "🚀 Lab2 Kubernetes Deployment Script"
echo "===================================="

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check cluster status
echo "✓ Checking Kubernetes cluster..."
kubectl cluster-info > /dev/null || { echo "❌ Kubernetes cluster not running"; exit 1; }

# Build Docker images
echo ""
echo "📦 Building Docker images..."
docker build -t lab2-backend:latest ./backend
docker build -t lab2-frontend:latest ./frontend

# Load images into Minikube if it's running
if command -v minikube &> /dev/null && minikube status > /dev/null 2>&1; then
    echo "🐳 Loading images into Minikube..."
    minikube image load lab2-backend:latest
    minikube image load lab2-frontend:latest
fi

# Deploy to Kubernetes
echo ""
echo "🚀 Deploying to Kubernetes..."
kubectl apply -k k8s/

# Wait for resources to be ready
echo ""
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/backend -n lab2 2>/dev/null || true
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n lab2 2>/dev/null || true
kubectl wait --for=condition=ready pod -l app=mysql -n lab2 --timeout=300s 2>/dev/null || true

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "📊 Status:"
kubectl get all -n lab2

echo ""
echo "🌐 Access your application:"
echo ""
echo "Option 1 - Port Forward (Linux/Mac):"
echo "  kubectl port-forward -n lab2 svc/frontend 8080:8080 8443:443"
echo "  Then visit: http://localhost:8080"
echo "  The HTTP page will redirect to: https://localhost:8443"
echo ""

if command -v minikube &> /dev/null; then
    echo "Option 2 - Minikube Service:"
    echo "  minikube service frontend -n lab2"
    echo ""
fi

echo "📝 Useful commands:"
echo "  kubectl get pods -n lab2"
echo "  kubectl logs -n lab2 -l app=backend -f"
echo "  kubectl describe pod -n lab2 <pod-name>"
echo "  kubectl exec -it -n lab2 <pod-name> -- /bin/bash"
echo ""
echo "🧹 To clean up:"
echo "  kubectl delete namespace lab2"
