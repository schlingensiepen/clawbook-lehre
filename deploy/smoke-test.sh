#!/bin/bash
# Smoke test of a built clawbook-lehre image ("start the thing").
#
#   deploy/smoke-test.sh <image> [expected-commit]
#
# Starts the image with a fresh home volume and checks: healthcheck, all
# tools (clawbook-check), build stamp, SSH login as "student" with the key
# from the home volume, RDP port and XWayland display, Samba share
# (read/write with the shown password), and that keys survive recreating
# the container with the same home volume.
#
# Needs: docker, ssh, ssh-keygen. smbclient is used when installed,
# otherwise a throwaway Debian container provides it.
# Uses host ports 127.0.0.1:2222, :3390 and :4445; other ports via
# SMOKE_SSH_PORT, SMOKE_RDP_PORT, SMOKE_SMB_PORT.

set -euo pipefail

IMAGE=${1:?usage: smoke-test.sh <image> [expected-commit]}
EXPECTED_COMMIT=${2:-}
NAME=clawbook-smoke-$$
VOLUME=${NAME}-home
WORK=$(mktemp -d)
SSH_PORT=${SMOKE_SSH_PORT:-2222}
RDP_PORT=${SMOKE_RDP_PORT:-3390}
SMB_PORT=${SMOKE_SMB_PORT:-4445}

cleanup() {
  docker rm -f "${NAME}" >/dev/null 2>&1 || true
  docker volume rm "${VOLUME}" >/dev/null 2>&1 || true
  rm -rf "${WORK}"
}
trap cleanup EXIT

fail() {
  echo "::error::$1"
  docker logs "${NAME}" 2>&1 | tail -n 80 || true
  exit 1
}

run_container() {
  docker run -d --name "${NAME}" \
    -p "127.0.0.1:${SSH_PORT}:22" -p "127.0.0.1:${RDP_PORT}:3389" \
    -p "127.0.0.1:${SMB_PORT}:445" \
    -v "${VOLUME}:/home/student" "${IMAGE}" >/dev/null
}

wait_healthy() {
  local status=unknown
  for _ in $(seq 1 60); do
    status=$(docker inspect -f '{{.State.Health.Status}}' "${NAME}")
    [ "${status}" = healthy ] && return 0
    sleep 2
  done
  fail "container did not become healthy (status: ${status})"
}

ssh_run() {
  ssh -i "${WORK}/key" -p "${SSH_PORT}" -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o LogLevel=ERROR \
      student@127.0.0.1 "$@"
}

smb() {
  if command -v smbclient >/dev/null; then
    (cd "${WORK}" && smbclient "$@")
  else
    docker run --rm --network host -v "${WORK}:/work" -w /work debian:trixie-slim \
      bash -c 'apt-get update -qq >/dev/null && apt-get install -y -qq smbclient >/dev/null && smbclient "$@"' \
      smbclient "$@"
  fi
}

docker volume create "${VOLUME}" >/dev/null
run_container
wait_healthy
echo "healthy"

docker exec "${NAME}" clawbook-check || fail "clawbook-check reported missing tools"
if [ -n "${EXPECTED_COMMIT}" ]; then
  docker exec "${NAME}" grep -q "commit=${EXPECTED_COMMIT}" /etc/clawbook-build \
    || fail "build stamp does not match ${EXPECTED_COMMIT}"
fi

# SSH with the key the init step created.
docker cp "${NAME}:/home/student/.ssh/id_ed25519" "${WORK}/key" >/dev/null
chmod 600 "${WORK}/key"
first=$(ssh-keygen -lf "${WORK}/key")
# (capture first: "docker logs | grep -q" fails under pipefail when grep
# stops reading early)
logs=$(docker logs "${NAME}" 2>&1)
grep -q "BEGIN OPENSSH PRIVATE KEY" <<<"${logs}" \
  || fail "start script did not show the private key"
ssh_run 'whoami && clawbook-check --quiet && tmux -V' || fail "SSH login as student failed"
echo "ssh ok"

# RDP: Weston answers and XWayland provides display :0.
timeout 5 bash -c "exec 3<>/dev/tcp/127.0.0.1/${RDP_PORT}" \
  || fail "RDP port ${RDP_PORT} does not answer"
docker exec "${NAME}" pgrep -x weston >/dev/null || fail "weston is not running"
docker exec "${NAME}" bash -c \
  'for _ in $(seq 1 20); do DISPLAY=:0 xhost >/dev/null 2>&1 && exit 0; sleep 1; done; exit 1' \
  || fail "XWayland display :0 is not available"
echo "rdp ok"

# Samba: share "student" is writable with the password the start shows.
smb_pw=$(docker exec "${NAME}" cat /home/student/.clawbook/samba-password)
grep -qF "Passwort ${smb_pw}" <<<"${logs}" \
  || fail "start script did not show the Samba password"
echo smoke > "${WORK}/smoke.txt"
smb //127.0.0.1/student -p "${SMB_PORT}" -U "student%${smb_pw}" -c 'put smoke.txt; ls smoke.txt' \
  || fail "Samba share not usable"
docker exec "${NAME}" test -f /home/student/smoke.txt \
  || fail "file written via Samba is missing in the home directory"
echo "samba ok"

# Recreate the container from the same home: keys must survive.
docker rm -f "${NAME}" >/dev/null
run_container
wait_healthy
docker cp "${NAME}:/home/student/.ssh/id_ed25519" "${WORK}/key" >/dev/null
second=$(ssh-keygen -lf "${WORK}/key")
[ "${first}" = "${second}" ] || fail "SSH key changed after recreating the container"
ssh_run true || fail "SSH login failed after recreating the container"
echo "recreate ok"

echo "Smoke test passed."
