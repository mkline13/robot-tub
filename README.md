# robot-tub

The deployment of [Tub](https://github.com/mkline13/tub) on robot. Tub runs from the published image `ghcr.io/mkline13/tub:main`, is reachable only through robot-caddy at `https://<proxy>/tub/`, and publishes no ports.

| Path | What it is |
| --- | --- |
| `docker-compose.yml` | The `tub` container on the external `caddy` network, with its database on the `tub_tub-data` volume |
| `caddy/tub.path` | Site file for robot-caddy (`~/robot-caddy/sites/tub.path`) |
| `schemas/` | JSON Schemas for document `data`, one file per schema ID |
| `setup.sh` | Creates the scopes and registers the schemas with the running container |

Scope: `personal`. Schemas: `task.v1` (Task), `journal-entry.v1` (Journal entry) and `bookmark.v1` (Bookmark).

## Deploy

On robot, with robot-caddy already running (it creates the `caddy` network):

```sh
git clone https://github.com/mkline13/robot-tub ~/robot-tub   # first time only
cd ~/robot-tub && git pull && docker compose pull && docker compose up -d
./setup.sh
```

The first time, copy `caddy/tub.path` to `~/robot-caddy/sites/tub.path`, commit and push robot-caddy, then `cd ~/robot-caddy && git pull && make reload`.

If Tub was previously started from a checkout of the Tub repo, stop that one first (`docker compose -f deploy/docker-compose.yml down` in `~/tub`). Both use the container name `tub` and the same data volume, so the database carries over.

## Credentials

Create one per device and store the secret in that device's app config. It's printed once.

```sh
docker exec tub tub credentials create laptop --scope personal
docker exec tub tub credentials list
docker exec tub tub credentials revoke laptop
```

Clients connect to `https://<proxy>/tub` with scope `personal`.

## Schemas

Schemas can't change once registered. To change one, add a new file with a new ID (for example `schemas/task.v2.json`), run `./setup.sh`, and have apps write new documents with `schema: "task.v2"`. Existing documents keep their old schema ID. `setup.sh` refuses to continue if a file no longer matches the schema registered under its ID.

Apps can import the same files for the `data` part of their RxDB schema (`tubSchema({ data })` from `@mkline13/tub-client`).

## Backups

```sh
docker exec tub tub backup /data/tub-backup.db && docker cp tub:/data/tub-backup.db .
```

## Updating Tub

```sh
cd ~/robot-tub && docker compose pull && docker compose up -d
```
