# vg

- upstream: https://github.com/vgteam/vg 
- ngi-nix: https://github.com/ngi-nix/ngi/issues/101

vg, tools for working with genome variation graphs.

> :warning: Currently vg requires an ugly hacky patch to build, which when upstream merges [PR#3341](https://github.com/vgteam/vg/pull/3341) will no longer be needed.

## Using

In order to use this [flake](https://nixos.wiki/wiki/Flakes) you need to have the
[Nix](https://nixos.org/) package manager installed on your system. Then you can simply run this
with:

```
$ nix run github:ngi-nix/magicrb_vg
```

You can also enter a development shell with:

```
$ nix develop github:ngi-nix/magicrb_vg
```

For information on how to automate this process, please take a look at [direnv](https://direnv.net/).
