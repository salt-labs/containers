# CI Demo

## Containers

- [x] brakeman
- [x] buildah
- [x] clair
- [x] cosign
- [x] flawfinder
- [x] gitleaks
- [x] gosec
- [x] govc
- [x] grype
- [x] hadolint
- [x] helm
- [x] kics
- [x] kube-linter
- [x] kubectl
- [x] kubesec
- [x] license_finder
- [x] packer
- [x] secretscanner
- [x] shellcheck
- [x] skopeo
- [x] synk
- [x] tflint
- [x] tfsec
- [x] trivy

## STAGES

### LINT

- [ ] hadolint
- [ ] license_finder
- [ ] shellcheck

### SAST

- [ ] brakeman
- [ ] grype
- [ ] secretscanner
- [ ] synk

### BUILD & PUBLISH (latest)

- [ ] buildah
- [ ] skopeo

### SCAN

### RELEASE (semver/calver)

- [ ] skopeo

### VERIFY (sbom/sign)

- [ ] cosign
- [ ] syft

### DEPLOY

- [ ] helm
- [ ] kubectl
- [ ] carvel

### PROMOTE

- [ ] Auto approvals
- [ ] Manual approvals

### OTHER

- [ ] Demo cartographer?
- [ ] Demo TBS

## DUMP

```bash
# Loop
clear ; git add --all && nix build --impure .#ci && docker load < result && docker run --name temp --rm --entrypoint /bin/bash -it --volume $SRC:/workdir/src ci:latest

pushd src
buildah images
buildah build --storage-driver vfs --format oci --isolation=rootless --squash --tag ci:latest --userns=auto --uts=container --file Dockerfile
buildah images
popd
```

capsh --print

- [URL](https://github.com/containers/buildah/blob/main/docs/tutorials/05-openshift-rootless-build.md)
- [URL](https://github.com/ES-Nix/podman-rootless/issues/2)
- [URL](https://github.com/ES-Nix/podman-rootless)
- [URL](https://docs-bigbang.dso.mil/1.41.0/packages/gitlab-runner/docs/rootless-podman/)
- [URL](https://stackoverflow.com/questions/75239810/podman-rootless-no-privileged-in-openshift)
- [URL](https://developers.redhat.com/blog/2019/08/14/best-practices-for-running-buildah-in-a-container)
- [URL](https://github.com/containers/buildah/issues/4049)
- [URL](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Go.gitlab-ci.yml)
- [URL](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)

  The container needs ability to run as the standard anyuid
  oc adm policy add-scc-to-user anyuid -z buildah-sa

```yaml
securityContext:
  capabilities:
    add:
      - CAP_SETGID
      - CAP_SETUID
```

## Steps

- Create project (cloudassemblyuy/infrastruct)
- Create registry token secret
- Create registry endpoint (codestream/endpoints)
-
