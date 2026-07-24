# Notes

## Cachix

To pre-build and push to cachix:

```bash
CONTAINER=name
CACHE=salt-labs

nix build \
    --impure \
    --json \
    ".#${CONTAINER}"  \
    | jq -r '.[].outputs | to_entries[].value' \
    | cachix push "${CACHE}"
```

## Testing

To run the devenv tests in the impure Nix development shell environment:

```bash
nix develop --impure --command bash -c "devenv test"
```
