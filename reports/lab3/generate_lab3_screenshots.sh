#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IMG_DIR="$ROOT/reports/lab3/images"
mkdir -p "$IMG_DIR"

echo "1) Start Minikube"
minikube start --driver=docker 2>&1 | tee "$IMG_DIR/minikube_start.txt"

echo "2) Build images inside Minikube's Docker daemon"
eval "$(minikube docker-env)"
cd "$ROOT"
docker build -t lab2-backend:latest ./backend 2>&1 | tee "$IMG_DIR/docker_build_backend.txt"
docker build -t lab2-frontend:latest ./frontend 2>&1 | tee "$IMG_DIR/docker_build_frontend.txt"
docker images | grep lab2 > "$IMG_DIR/docker_images.txt" || true

echo "3) Deploy Kubernetes resources"
kubectl apply -k k8s/ 2>&1 | tee "$IMG_DIR/kubectl_apply.txt"

echo "4) Wait for pods to be ready (namespace: lab2)"
# Wait up to 3 minutes per app
kubectl wait --for=condition=Ready pod -l app=mysql -n lab2 --timeout=180s || true
kubectl wait --for=condition=Ready pod -l app=backend -n lab2 --timeout=180s || true
kubectl wait --for=condition=Ready pod -l app=frontend -n lab2 --timeout=180s || true

echo "5) Capture status and logs"
kubectl get pods -n lab2 -o wide > "$IMG_DIR/kubectl_get_pods.txt"
kubectl get svc -n lab2 > "$IMG_DIR/kubectl_get_services.txt"
kubectl logs -n lab2 -l app=backend --tail=200 > "$IMG_DIR/kubectl_logs.txt" || true

echo "6) Port-forward frontend over HTTP (background)"
kubectl port-forward -n lab2 svc/frontend 8080:80 >/dev/null 2>&1 &
PF=$!
sleep 3

echo "7) Capture frontend HTML and backend response over HTTP"
curl -s http://localhost:8080 > "$IMG_DIR/frontend_html.html" || true
curl -s http://localhost:8080/api/health > "$IMG_DIR/backend_response.txt" || true

echo "8) Convert outputs to PNG (requires ImageMagick 'convert')"
for f in "$IMG_DIR"/*.txt "$IMG_DIR"/*.html; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  # Use label:@file for text rendering
  convert -background white -fill black -font DejaVu-Sans-Mono -pointsize 10 label:@${f} "$IMG_DIR/${base%.*}.png" || true
done

echo "9) Stop port-forward"
kill "$PF" >/dev/null 2>&1 || true

echo "10) Rebuild PDF"
cd "$ROOT/reports/lab3"
pdflatex -interaction=nonstopmode lab3.tex >/dev/null 2>&1 || true
pdflatex -interaction=nonstopmode lab3.tex >/dev/null 2>&1 || true

echo "Done. PDF: $ROOT/reports/lab3/lab3.pdf"
