# Tasks Frontend (NGINX, non-root)

A minimal frontend served by NGINX that proxies `/api/*` to a backend service.
Designed to run as **non-root** using the `nginxinc/nginx-unprivileged` image.

## Build & Run (Docker)

```bash
# Build the image
docker build -t tasks-frontend:latest .

# Run it (exposes 8080)
docker run --rm -p 8080:8080 --name tasks-frontend tasks-frontend:latest
```

Open **http://localhost:8080**

> The frontend expects a backend reachable at `http://backend:8000` when used
> within Docker Compose (service name `backend`). If you run the backend directly
> on your host as `http://localhost:8000`, either:
> - run the frontend container with `--add-host=backend:host-gateway` (Docker 20.10+),
> - or adjust `proxy_pass` in `nginx.conf` to point to `http://host.docker.internal:8000/` on Mac/Windows
>   (or `http://172.17.0.1:8000/` on Linux, depending on your Docker bridge IP).
