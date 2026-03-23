# Deploying To Contabo

This repo now includes a host-native deployment flow for the Contabo VPS. T3 Code runs directly on the host under `systemd`, so Codex still has normal VPS-level access to the filesystem, installed tools, and services.

## Goals

- Keep deployment human-readable and repo-owned.
- Avoid global `npm -g` / `/usr/bin/t3` drift.
- Keep server and web in sync by building the same repo snapshot on the VPS.
- Preserve host-level flexibility for Codex.

## Layout On The VPS

The deploy scripts assume this layout:

- `/opt/t3code/releases/<timestamp>-<sha>`: immutable release directories copied from your local repo.
- `/opt/t3code/current`: symlink to the active release.
- `/opt/t3code/shared/t3code.env`: runtime secrets and overrides.
- `/opt/t3code/shared/data`: persistent T3 Code data, passed as `T3CODE_HOME`.

## Files In This Repo

- `scripts/deploy-contabo.sh`: local one-command deploy wrapper.
- `deploy/contabo/install-host.sh`: one-time VPS bootstrap.
- `deploy/contabo/deploy-remote.sh`: build + activate a release on the VPS.
- `deploy/contabo/start-t3.sh`: runtime entrypoint used by `systemd`.
- `deploy/contabo/t3code.service`: checked-in `systemd` unit.
- `deploy/contabo/t3code.env.example`: checked-in env template.

## One-Time VPS Bootstrap

1. Copy or clone this repo to the VPS once.
2. Run:

```bash
cd /path/to/t3code
sudo APP_ROOT=/opt/t3code bash deploy/contabo/install-host.sh
```

3. Edit `/opt/t3code/shared/t3code.env` and set at least:

```bash
T3CODE_AUTH_TOKEN=<your-secret-token>
```

4. Make sure the VPS has:

```bash
bun --version
node --version
tailscale status
```

## Deploying A New Version

From your local machine, after you have tested the repo state you want to ship:

```bash
./scripts/deploy-contabo.sh
```

That script:

1. Verifies your local working tree is clean.
2. Copies the current repo snapshot to a new release directory on the VPS.
3. Runs `bun install --frozen-lockfile`.
4. Runs `bun run build`.
5. Points `/opt/t3code/current` at the new release.
6. Restarts `t3code.service`.

To deploy to a different SSH host alias:

```bash
./scripts/deploy-contabo.sh my-vps-host
```

## Runtime Commands

These are the only commands you should need on the VPS:

```bash
systemctl status t3code.service
systemctl restart t3code.service
journalctl -u t3code.service -f
ls -la /opt/t3code/releases
readlink -f /opt/t3code/current
```

## Migration From The Current VPS Setup

The current Contabo host is still using a global install at `/usr/bin/t3` plus `/opt/t3code/start-t3.sh`. Migrate in this order:

1. Bootstrap the new host-native layout from this repo.
2. Set `T3CODE_AUTH_TOKEN` in `/opt/t3code/shared/t3code.env`.
3. Deploy once with `./scripts/deploy-contabo.sh`.
4. Confirm the new service is healthy with `systemctl status t3code.service`.
5. Remove the legacy global install and old wrapper only after the new service is stable.

## Notes

- The runtime now uses `--home-dir` / `T3CODE_HOME`, not `--state-dir`.
- By default the checked-in start script binds to the Tailscale IPv4. Set `T3CODE_HOST` in the env file if you want a fixed non-Tailscale bind address.
- Because the service runs directly on the host, Codex inside T3 Code can still operate on host repos, files, and tools without Docker sandboxing getting in the way.
