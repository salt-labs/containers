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
