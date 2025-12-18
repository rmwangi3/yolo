# Yolo (Containerized E-commerce)

This repository contains a containerized MERN-style e-commerce demo using Docker and docker-compose.

Quick start

1. Clone the repo:

```bash
git clone https://github.com/rmwangi3/yolo.git
cd yolo
```

2. Build and run the stack:

```bash
docker-compose up --build
```

3. Access the app in your browser:

- Frontend: http://localhost:3000
- Backend API: http://localhost:5000/api/products

Persistence

- MongoDB data is persisted to a named Docker volume `mongo-data` (configured in `docker-compose.yml` at `/data/db`). Added products will persist across container restarts.
- Uploaded product images are stored in `backend/public/images`. The `docker-compose.yml` includes a bind mount so uploaded images persist on the host at `./backend/public/images`.

Important files

- `docker-compose.yml` — defines `mongo`, `backend`, and `client` services and the `mongo-data` volume.
- `backend/Dockerfile` — Node-based backend image.
- `client/Dockerfile` — multistage build (Node => nginx) to serve the frontend.
- `explanation.md` — rationale for base images, Dockerfile directives, networking, volumes, git workflow and more.

Notes and troubleshooting

- If the backend fails to connect to MongoDB, ensure `.env` contains `MONGODB_URI=mongodb://mongo:27017/yolomy` and that you started the compose stack.
- To inspect backend logs:

```bash
docker-compose logs -f backend
```

- To test persistence manually:
	1. Add a product through the UI.
	2. Stop containers: `docker-compose down`.
	3. Start containers: `docker-compose up`.
	4. Verify the product still exists via the UI or `curl http://localhost:5000/api/products`.

Publishing images & DockerHub

- When publishing images to DockerHub, use semantic tags (e.g., `rmwangi3/yolo-backend:1.0.0`) so versions are easy to identify.
- Add a DockerHub screenshot showing the image and tag in the repo as required by the assignment.

Contact / Next steps

If you want, I can:
- Push built images to DockerHub (requires Docker credentials).
- Create an `archive` branch containing the previous `yolo_backup` snapshot (if you prefer it preserved in git). 

