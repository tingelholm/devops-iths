# Image decisions

## Why a container, and how it gets to Azure

In module 04 I shipped a zip file to App Service and Azure ran `npm install` on arrival.
That works, but I never decided exactly what the environment contained. I picked a version
from a list and Azure filled in the rest.

A container packages the app and everything it needs to run: the right version of Node, the
packages, the system programs. The same package runs the same way on my machine, in a
pipeline and in Azure. That is predictability, the quality criterion from module 01.

The flow has three steps:

```
Dockerfile  --docker build-->  image  --docker push-->  registry
```

The `Dockerfile` is the recipe and lives in the repo. `docker build` turns it into an image,
which is the finished package. `docker push` puts it in the registry, which is where other
machines can fetch it from. Azure pulls it from there in module 09.

```bash
az acr login --name "$REGISTRY_NAME"
TAG=$(git rev-parse --short HEAD)
docker build --platform linux/amd64 --build-arg COMMIT="$(git rev-parse HEAD)" \
  -t "$REGISTRY/waypoint:$TAG" .
docker push "$REGISTRY/waypoint:$TAG"
```

The registry itself is described in Bicep, `infra/modules/container-registry.bicep`, so it is
created by the pipeline like everything else.

## Base image

`node:24-slim`, a smaller version of Debian with Node 24 installed.

Picking a base image is a trade-off between size, security and whether everything still
works. Smaller is faster to pull and start, and fewer programs means fewer vulnerabilities.
But the smallest ones can break things: Alpine builds on a different standard library, and
some programs stop working on it.

`slim` is the middle ground. Much smaller than the full `node:24`, still Debian, no
surprises.

## What `.dockerignore` leaves out

`.git`, `.github`, `docs`, `infra`, `scripts`, `tests`, `node_modules`, `*.db`, `artifacts`.

None of it is needed to run the app, and the image is almost 100 MB smaller without it.
`node_modules` is installed during the build anyway, and `*.db` is my local Sqlite file,
which should never end up in an image.

Not the same list as `.gitignore`: that one decides what goes into the repo, this one what
goes into the image. `infra/` belongs in the repo but not in the image.

## Tagging

The short commit id, never `latest`.

`latest` is just a word people put on whatever they built last, so it points somewhere new
every time anyone builds. The commit id points at one version and never moves, and `/health`
shows the same id, which is what the smoke test checks.

## Other choices in the Dockerfile

**Packages before the code.** A changed layer rebuilds everything below it. My code changes
daily, the packages rarely, so `npm ci` stays cached when I only change code.

**`USER node` instead of root.** If someone gets into the app they get whatever the app has,
and as `node` that is only `/app`. Least privilege, same idea as the `AcrPush` role on the
registry instead of a shared password.

**`chown node:node /app`** because root creates the directory and the app writes its Sqlite
file there. Without it the container stops with `unable to open database file`.

**`--platform linux/amd64`** because Azure runs containers on amd64. The wrong architecture
gives an image that will not start, with an error that looks like a config problem.
