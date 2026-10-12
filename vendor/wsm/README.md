# WorkspaceManager (`wsm`)

Vendored wheel of the WorkspaceManager, installed into the image as the
command `wsm` (see `deploy/Containerfile`).

- File: `wsm-1.1.0-py3-none-any.whl` (release v1.1.0)
- SHA-256: `4644a6ae521879196092bd737f67f615a1bb4e90c4b76186e7626baa2794e8d5`
  (checked during the image build, value in `deploy/versions.env`)
- License: Apache-2.0 (see the license file inside the wheel)

To update: replace the wheel, then set `WSM_VERSION` and `WSM_SHA256` in
`deploy/versions.env`.
