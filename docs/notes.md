# Notes

## Cachix

To pre-build and push to cachix:

```bash
CONTAINER=name
CACHE=salt-labs

nix build --impure --json ".#${CONTAINER}"  \
    | jq -r '.[].outputs | to_entries[].value' \
    | cachix push "${CACHE}"
```
