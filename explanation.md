Objective explanations for Docker implementation

1) Choice of base images
- Backend: `node:16-alpine` — small, secure Alpine variant with Node 16 LTS suitable for running the Express server and installing native modules if needed.
- Client: multistage build using `node:16-alpine` (build stage) and `nginx:stable-alpine` (runtime) — builds optimized static files and serves them with nginx for production performance.
- Database: `mongo:5.0` official image — stable MongoDB image with wide compatibility.

2) Dockerfile directives used
- `FROM` to select base images (node and nginx).
- `WORKDIR` to set the working directory inside the container.
- `COPY package*.json ./` then `RUN npm install` to leverage Docker layer caching for dependencies.
- `COPY . .` to copy source artifacts into the image.
- `RUN npm run build` (client) to produce production static assets.
- `EXPOSE` to document ports used (`5000` backend, `80` client).
- `CMD` to define the container entrypoint (`node server.js` and `nginx -g 'daemon off;'`).

3) Docker-compose networking and port allocation
- A custom bridge network `yolo-network` is declared and all services are attached to it. This provides service name DNS resolution inside the network (e.g. `mongo` hostname resolvable by `backend`).
- Ports are mapped to the host for external access: backend `5000:5000` and client `3000:80` (so the React app is available at `http://localhost:3000`).

4) Volumes and persistence
- A named volume `mongo-data` is attached to the `mongo` service at `/data/db` to persist MongoDB data between container restarts and re-creations. This guarantees persistence of added products across container recreation.

5) Git workflow used
- Create a feature branch from `master` (e.g., `feature/dockerize`) and add the Dockerfiles and `docker-compose.yml`.
- Commit small, focused commits (e.g., `add backend Dockerfile`, `add client Dockerfile`, `add docker-compose and explanation`).
- Push the branch and open a PR for review before merging to `master`.

6) Running & debugging
- To build and run: `docker-compose up --build`.
- If the backend cannot connect to MongoDB, verify `MONGODB_URI` environment variable; inside compose it's set to `mongodb://mongo:27017/yolomy` which uses the service name `mongo` DNS.
- Logs: `docker-compose logs -f backend` and `docker-compose logs -f mongo` to trace connection issues.
- If container fails to build due to node version or npm errors, check `engines` in `client/package.json` and adapt the Node base image to match (e.g., use `node:14` or `node:18` if necessary).

7) Image tagging & good practices
- Use explicit image tags (no `latest`) when publishing to DockerHub, e.g., `rmwangi3/yolo-backend:1.0.0` and `rmwangi3/yolo-client:1.0.0`.
- For CI/CD builds, attach build metadata and semantic version tags.

8) DockerHub screenshot
- After building and pushing images to DockerHub, take a screenshot showing the repository and tag versions (e.g., `1.0.0`) and include it with your submission.

Notes / next steps
- Optional: Add `healthcheck` entries to services for more robust orchestration.
- Optional: Add `.dockerignore` files to reduce build context and speed up builds.
