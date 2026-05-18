pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    skipDefaultCheckout(true)
  }

  parameters {
    string(name: 'REPO_URL', defaultValue: 'https://github.com/<your-username>/<your-repo>.git', description: 'GitHub repository URL for this project')
    string(name: 'BRANCH', defaultValue: 'main', description: 'Branch to build')
    string(name: 'COMPOSE_FILE', defaultValue: 'docker-compose.yml', description: 'Docker Compose file to use')
  }

  environment {
    COMPOSE_PROJECT_NAME = 'lab2-multi-container'
  }

  stages {
    stage('Checkout Source') {
      steps {
        deleteDir()
        git branch: params.BRANCH, url: params.REPO_URL
      }
    }

    stage('Verify Docker') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail
docker version
docker compose version
'''
      }
    }

    stage('Build Images') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail
docker compose -f "$COMPOSE_FILE" build
'''
      }
    }

    stage('Start Containers') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail
docker compose -f "$COMPOSE_FILE" up -d
'''
      }
    }

    stage('Verify Backend and Database') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

# Wait for the backend container to become ready.
for attempt in $(seq 1 30); do
  if docker compose -f "$COMPOSE_FILE" exec -T backend python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:5000/api/health', timeout=5).read().decode())"; then
    break
  fi
  sleep 2
  if [ "$attempt" -eq 30 ]; then
    echo "Backend did not become ready in time"
    docker compose -f "$COMPOSE_FILE" logs --no-color backend db frontend
    exit 1
  fi
done

# Validate that the backend can reach MySQL by querying the API and the database driver.
docker compose -f "$COMPOSE_FILE" exec -T backend python -c "import os, pymysql; conn = pymysql.connect(host=os.getenv('DB_HOST', 'db'), port=int(os.getenv('DB_PORT', '3306')), user=os.getenv('DB_USER', 'lab2user'), password=os.getenv('DB_PASSWORD', 'lab2pass'), database=os.getenv('DB_NAME', 'lab2db')); cursor = conn.cursor(); cursor.execute('SELECT COUNT(*) AS count FROM notes'); row = cursor.fetchone(); print(f\"notes={row['count']}\"); cursor.close(); conn.close()"
'''
      }
    }

    stage('Verify Frontend') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

# Frontend nginx redirects HTTP to HTTPS; validate the app from inside the container.
docker compose -f "$COMPOSE_FILE" exec -T frontend sh -c '
  wget -qO- --no-check-certificate https://localhost/ | grep -q "Lab 2" && \
  wget -qO- --no-check-certificate https://localhost/api/health | grep -q "ok"
'
'''
      }
    }

    stage('Show Status') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail
docker compose -f "$COMPOSE_FILE" ps
'''
      }
    }
  }

  post {
    success {
      echo 'Application ran successfully in Docker containers.'
    }
    always {
      sh '''#!/usr/bin/env bash
set +e
# Tear everything down so the next Jenkins run starts cleanly.
docker compose -f "$COMPOSE_FILE" down -v
'''
    }
  }
}
