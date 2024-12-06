
# lit.luvit.io Backup

This is a mostly complete backup of the lit.luvit.io database.

> [!NOTE]
> Last Updated: 2024-12-05

Because lit is not robust against crashing while uploading a package (an
unfortunately common occurrence), this backup cannot be complete.

Any packages that are corrupted (ie. missing files) are not included in this
backup. This currently affects:

- `Bilal2453/discordia-interactions v0.0.2`
- `Bilal2453/vips v1.1.18`
- `Bilal2453/vips v1.1.17`
- `Bilal2453/vips v1.1.16`
- `Bilal2453/vips v1.1.15`
- `Bilal2453/vips v1.1.14`
- `Bilal2453/vips v1.1.13`
- `Bilal2453/vips v1.1.12`
- `Bilal2453/vips v1.1.10`
- `Bilal2453/lit-vips v1.0.0`
- `Bilal2453/lua-vips v1.0.0`
- `shawwn/dax v0.0.1`

## Licensing

This repository contains code from packages on lit.luvit.io, and all code is
provided under their original license. The license for each package may be
attached to the package itself, or may be found on the package's homepage.

## Format

The lit repository format is git compatible, but exclusively uses tagged tree
and blobs, which the github interface does not support. Browsing the tags on
github is not possible, however the references exist and can be traversed
locally.

For ease of browsing a series of commits have been created for each package
that represent each version of a package.

## Compatibility

This repository can also be cloned bare and used as a litdb repository,
assuming you ensure all references are fetched.
