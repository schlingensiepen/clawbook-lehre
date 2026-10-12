# WorkspaceManager (`wsm`)

Vendored wheel of the WorkspaceManager, installed into the image as the
command `wsm` (see `deploy/Containerfile`).

- File: `wsm-1.1.1-py3-none-any.whl` (release v1.1.1)
- SHA-256: `7cdd9836a6f303a3ff2f440a8ff334e69aa1f5d1e58823bd0efe497fb89c74da`
  (checked during the image build, value in `deploy/versions.env`)
- License: Apache-2.0 (see the license file inside the wheel)

To update: replace the wheel, then set `WSM_VERSION` and `WSM_SHA256` in
`deploy/versions.env`.
