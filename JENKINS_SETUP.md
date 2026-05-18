# Jenkins CI/CD Setup for Lab 2

This project now includes a `Jenkinsfile` that builds and runs the Docker Compose stack locally from a GitHub repository.

## What the pipeline does

1. Clones the repository from GitHub.
2. Verifies Docker and Docker Compose are available.
3. Builds the backend and frontend images.
4. Starts the MySQL, Flask backend, and Nginx frontend containers.
5. Verifies the backend can answer `/api/health`.
6. Verifies the backend can query MySQL and read rows from `notes`.
7. Verifies the frontend serves the app and proxies API requests.
8. Stops and removes the containers at the end of the run.

## Jenkins job setup

1. Run Jenkins locally in Docker with access to the host Docker daemon.
   The container must have the Docker CLI installed and `/var/run/docker.sock` mounted.
2. Create a new Pipeline job in Jenkins.
3. Choose `Pipeline script from SCM`.
4. Set the repository URL to your GitHub repo.
5. Set the branch to `main` or your active branch.
6. Jenkins will read the root `Jenkinsfile` from the repository.

## Parameters used by the pipeline

- `REPO_URL`: GitHub repository URL.
- `BRANCH`: Git branch to build.
- `COMPOSE_FILE`: defaults to `docker-compose.yml`.

## Notes

- The pipeline uses Docker Compose because the application already has a working multi-container setup from Lab 2.
- The frontend is validated from inside the container, so the self-signed HTTPS certificate does not block the build.
- The `post { always { ... } }` section removes containers and volumes so the next build starts cleanly.

## Local run command

If you want to run the stack manually outside Jenkins:

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f
```

To stop it:

```bash
docker compose down -v
```
