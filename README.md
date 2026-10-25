# Pepper package index

The package index that `pepper package search`, `pepper package info` and `pepper package add <name>` read. It holds one TOML file per package, under `packages/`, and the file's name is the package's name: the one `pepper package add <name>` takes and source code imports it by.

`pepper package` clones this repository into the Pepper home's cache, and fetches it again once its copy is an hour old. To read a different index, such as a mirror or a private one, set `PEPPER_PACKAGE_INDEX` to its Git URL. See [`pep-package`'s documentation](https://github.com/pep-lang/pepper/blob/main/docs/src/tools/pep-package.md#the-package-index). The packages are also listed on <https://pepper-lang.dev/packages.html>.

## A package

`packages/semver.toml`:

```toml
source = "github:pep-lang/pepper-semver"   # required: host:owner/name (github, gitlab or codeberg)
description = "Semantic Versioning 2.0.0: parse, compare and order versions, and match them against ranges"
keywords = ["semver", "version", "range"]
```

The name is a Pepper identifier: lowercase `snake_case`, as `import` takes it. The index lists no versions: they are the repository's version tags (`v1.2.0`), which `pepper package info` reads from the host, so publishing a release (`pepper package publish`) needs no change here.

## Listing a package

- Publish at least one version of it first, and give its `pep.toml` a `description`, `license` and `repository`.
- Open a pull request that adds its file. The first pull request for a name claims it; a maintainer reviews each one, and may ask for another name when one is too general or misleading.
- To change a package's description or keywords, or move it to another repository, open a pull request from its maintainers that edits its file.

Once merged, every `pepper package search` sees it within an hour.

## License

The index is dedicated to the public domain under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/), so any tool may use it.
