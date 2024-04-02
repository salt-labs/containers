# Notes

## devenv

The repository has now moved from using a Nix flake with `devenv` to using straight `devenv`.

- To build a container, the new process is;

```bash
devenv container build <container>
```

- To build and copy a container

```bash
devenv container --registry <registry> --copy-args="<copy-args>" copy <container>
```
