
# Dev Container Features Reference

**Development Container Features** are self-contained, shareable units of installation code and Development Container configuration. The name comes from the idea that referencing one of them allows one to quickly and easily add more tooling, runtime, or library *“features”* into a Development Container for a user and/or their collaborators to use.

Feature metadata is captured by a `devcontainer-feature.json` file in the root folder of the feature.

> *NOTE:* While Features may be installed on top of any base image, the implementation of a Feature might restrict it to a subset of possible base images. For example, some Features may be authored to work with a certain Linux distro (e.g. debian-based images that use the `apt` package manager).

## Documentation

### Specifications
- [Dev Container Features - Reference](https://containers.dev/implementors/features/)
- [Dev Container Features - Contribution & Discovery](https://containers.dev/implementors/features-distribution/)

### Best Practices

- [Authoring a Dev Container Feature](https://containers.dev/guide/feature-authoring-best-practices)

### Reference implementation

- [A bootstrap repo for self-authoring Dev Container Features](https://github.com/devcontainers/feature-starter)

## Feature Folder Structure

A Feature is a self contained entity in a folder with at least a `devcontainer-feature.json` and `install.sh` entrypoint script. Additional files are permitted and are packaged along side the required files. For example:

```text
📂 src
└── 📂 my-feature
    ├── 📄 devcontainer-feature.json   // "id": "my-tool", "version": "1.2.0"
    ├── 📄 install.sh
    └── 📄 (other files)   
```

## Feature Properties

The `devcontainer-feature.json` file defines metadata about a given Feature.

All Dev Container Feature [properties](https://containers.dev/implementors/features/#devcontainer-feature-json-properties) are optional **except for `id`, `version`, and `name`**.

[devContainerFeature.schema.json](https://github.com/devcontainers/spec/blob/main/schemas/devContainerFeature.schema.json) defines the schema for the `devcontainer-feature.json` file.

### Examples
#### Property: `mount` 
The `mount` property allows you to mount [volumes](https://docs.docker.com/engine/storage/volumes/), [host-directories](https://docs.docker.com/engine/storage/bind-mounts/), and [tmpfs](https://docs.docker.com/engine/storage/tmpfs/) mounts in a container. For example:

```json
"mounts": [
	{
	    "source": "docker-volume-name",
        "target": "/path/on/container",
        "type": "volume"
	}
]
```

The [Dev Container variable](https://containers.dev/implementors/json_reference/#variables-in-devcontainerjson) `${devcontainerId}` may be referenced in the `source` value. For example:

```json
"mounts": [
	{
	    "source": "docker-volume-name-${devcontainerId}",
        "target": "/path/on/container",
        "type": "volume"
	}
]
```

#### Property: `containerEnv` 
The `containerEnv` property is a set of name-value pairs that sets or overrides environment variables for the Dev Container. Environment and [pre-defined variables](https://containers.dev/implementors/json_reference/#variables-in-devcontainerjson) may be referenced in the values. For example:

```json
"containerEnv": {
	"MY_VARIABLE": "${localEnv:MY_VARIABLE}"
}
```

## Feature Lifecycle Hooks

The following [lifecycle hooks](https://containers.dev/implementors/features/#lifecycle-hooks) may be declared as properties of `devcontainer-feature.json`.

| Property               | Type                                                                                                              |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `onCreateCommand`      | [string, array, object](https://containers.dev/implementors/json_reference#formatting-string-vs-array-properties) |
| `updateContentCommand` | [string, array, object](https://containers.dev/implementors/json_reference#formatting-string-vs-array-properties) |
| `postCreateCommand`    | [string, array, object](https://containers.dev/implementors/json_reference#formatting-string-vs-array-properties) |
| `postStartCommand`     | [string, array, object](https://containers.dev/implementors/json_reference#formatting-string-vs-array-properties) |
| `postAttachCommand`    | [string, array, object](https://containers.dev/implementors/json_reference#formatting-string-vs-array-properties) |
### Behavior
Each [property](https://containers.dev/implementors/features/#behavior) mirrors the behavior of the [matching property](https://containers.dev/implementors/json_reference/#lifecycle-scripts) in `devcontainer.json`, including the behavior that commands are executed from the context of the [project workspace folder](https://containers.dev/implementors/spec/#project-workspace-folder).

For each lifecycle hook (in [Feature installation order](https://containers.dev/implementors/features/#installation-order)), each command contributed by a Feature is executed in sequence (blocking the next command from executing). Commands provided by Features are always executed _before_ any user-provided lifecycle commands (i.e.: in the `devcontainer.json` file).

If a Feature provides a given command with the [object syntax](https://containers.dev/implementors/json_reference#formatting-string-vs-array-properties), all commands within that group are executed in parallel, but still blocking commands from subsequent Features and/or the `devcontainer.json` file.

> [!NOTE]
> These properties are stored within [image metadata](https://containers.dev/implementors/spec/#merge-logic).

#### Writing scripts to known container path
It may be helpful for a Feature to write scripts to a known, persistent path within the container (i.e. for later use in a given lifecycle hook).

Take for instance the `git-lfs` Feature, which [writes a script](https://github.com/devcontainers/features/blob/4fca96b5e8a4bfc93679098cb19d73c65ce571eb/src/git-lfs/install.sh#L190-L216) to `/usr/local/share/pull-git-lfs-artifacts.sh` during installation.
##### install.sh
```sh
PULL_GIT_LFS_SCRIPT_PATH="/usr/local/share/pull-git-lfs-artifacts.sh"

tee "$PULL_GIT_LFS_SCRIPT_PATH" > /dev/null \
<< EOF
#!/bin/sh
set -e
<...truncated...>
EOF
```

This script is then executed during the [`postCreateCommand` lifecycle hook](https://github.com/devcontainers/features/blob/4fca96b5e8a4bfc93679098cb19d73c65ce571eb/src/git-lfs/devcontainer-feature.json#L23).
##### devcontainer-feature.json
```json
{
    "id": "git-lfs",
    "version": "1.1.0",
    "name": "Git Large File Support (LFS)",
    // <...truncated...>
    "postCreateCommand": "/usr/local/share/pull-git-lfs-artifacts.sh",
    "installsAfter": [
        "ghcr.io/devcontainers/features/common-utils"
    ]
}
```

## Feature Options

The Dev Container Feature [options property](https://containers.dev/implementors/features/#options-property) contains a map of option IDs and their related configuration settings. The ID becomes the name of the environment variable in all caps. See [option resolution](https://containers.dev/implementors/features/#option-resolution) for more details. For example:

```json
"options": {
	"optionIdGoesHere": {
		"type": "string",
		"description": "Description of the option",
		"enum": ["value1", "value2"],
		"default": "value1"
	}
}
```

## User environment variables

Feature scripts run as the `root` user and sometimes need to know which user account the dev container will be used with.

`_REMOTE_USER` and `_CONTAINER_USER` environment variables are passed to the Features scripts with `_CONTAINER_USER` being the container’s user and `_REMOTE_USER` being the configured `remoteUser`. If no `remoteUser` is configured, `_REMOTE_USER` is set to the same value as `_CONTAINER_USER`.

Additionally, the home folders of the two users are passed to the Feature scripts as `_REMOTE_USER_HOME` and `_CONTAINER_USER_HOME` environment variables.

The container user can be set with `containerUser` in the `devcontainer.json` and image metadata, and can be passed down from the base image.

## Dev Container ID

An identifier will be referred to as `${devcontainerId}` in the `devcontainer.json` and the Feature metadata and that will be replaced with the dev container’s id. It should only be used in parts of the configuration and metadata that is not used for building the image because that would otherwise prevent pre-building the image at a time when the dev container’s id is not known yet. Excluding boolean, numbers and enum properties the properties supporting `${devcontainerId}` in the Feature metadata are: `entrypoint`, `mounts`, `customizations`.

> [!NOTE]
> Implementations can choose how to compute this identifier. They must ensure that it is unique among other dev containers on the same Docker host and that it is stable across rebuilds of dev containers. The identifier must only contain alphanumeric characters. We describe a way to do this below.

## Dev Container Properties

Features are referenced in a user’s [`devcontainer.json`](https://containers.dev/implementors/json_reference) under the top level `features` object.

A user can specify an arbitrary number of Features. At build time, these Features will be installed in an order defined by a combination of the [installation order rules and implementation](https://containers.dev/implementors/features/#Installation-Order).

A single Feature is provided as a key/value pair, where the key is the Feature identifier, and the value is an object containing *“options”* (or empty for *“default”*). Each key in the feature object must be unique.

These options are sourced as environment variables at build-time, as specified in [Option Resolution](https://containers.dev/implementors/features/#option-resolution)).

Below is a valid `features` object provided as an example.

```json
"features": {
  "ghcr.io/user/repo/go": {},
  "ghcr.io/user/repo1/go:1": {},
  "ghcr.io/user/repo2/go:latest": {},
  "https://github.com/user/repo/releases/devcontainer-feature-go.tgz": { 
        "optionA": "value" 
  },
  "./myGoFeature": { 
        "optionA": true,
        "optionB": "hello",
        "version" : "1.0.0"
  }
}
```

> [!NOTE]
> The `:latest` version annotation is added implicitly if omitted. To pin to a specific package version ([example](https://github.com/devcontainers/features/pkgs/container/features/go/versions)), append it to the end of the Feature.

An option’s value can be provided as either a `string` or `boolean`, and should match what is expected by the feature in the `devcontainer-feature.json` file.

As a shorthand, the value of the `features` property can be provided as a single string. This string is mapped to an option called `version`. In the example below, both examples are equivalent.

```json
"features": {
  "ghcr.io/owner/repo/go": "1.18"
}
```

```json
"features": {
  "ghcr.io/owner/repo/go": {
    "version": "1.18"
  }
}
```

## Referencing a Feature

The `id` format specified dictates how a supporting tool will locate and download a given feature. `id` is one of the following:

| Type                                                        | Description                                                                | Example                                                                                 |
| ----------------------------------------------------------- | -------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `<oci-registry>/<namespace>/<feature>[:<semantic-version>]` | Reference to feature in OCI registry[^1]                                   | `ghcr.io/user/repo/go`  <br>`ghcr.io/user/repo/go:1`  <br>`ghcr.io/user/repo/go:latest` |
| `https://<uri-to-feature-tgz>`                              | Direct HTTPS URI to a tarball.                                             | `https://github.com/user/repo/releases/devcontainer-feature-go.tgz`                     |
| `./<path-to-feature-dir>`                                   | A relative directory[^2] to folder containing a devcontainer-feature.json. | `./myGoFeature`                                                                         |

## Versioning

Each Feature is individually [versioned according to the SemVer specification](https://semver.org/). The `version` property in the respective `devcontainer-feature.json` file is updated to increment the Feature’s version.

Tooling that handles releasing Features will not republish Features if that exact version has already been published; however, tooling must republish major and minor versions in accordance with the SemVer specification.

## Authoring

Features can be authored in a number of languages, the most straightforward being bash scripts. If a Feature is authored in a different language, information about it should be included in the metadata so that users can make an informed choice about it.

Reference information about the application required to execute the Feature should be included in `devcontainer-feature.json` in the metadata section.

Applications should default to `/bin/sh` for Features that do not include this information.

If the Feature is included in a folder as part of the repository that contains `devcontainer.json`, no other steps are necessary.

## Release

[Publishing a Dev Container Feature](https://containers.dev/implementors/features-distribution) means packaging its files and pushing them to an OCI-compatible container registry, such as GitHub Container Registry (GHCR). Other projects can then reference the feature by its ID. Consumers never clone the feature's source repository. They point to a published version in their `devcontainer.json`.

### Before you publish
Publishing makes your Feature visible to others and hard to take back, and small mistakes such as broken links, missing details or leftover drafts are easy to miss once you're done developing. A quick check now saves you from fixing them in public later. Check these items first:

#### Feature metadata
Each feature directory must contain a `devcontainer-feature.json` with an `id` and a `version`. The `id` must match the folder name, and the `version` must be a valid semantic version, such as `1.0.0`. Also give the feature a `name` and a `description`, so it reads clearly in tooling and in the registry.
#### Version bump
Increase the `version` for every release that changes the published files. Registries treat a version as immutable, so a changed feature published under an existing version can break consumers who depend on it.
#### Install script
The feature's `install.sh` runs as root inside the container. Test it against every base image you intend to support, such as Debian, Ubuntu and Alpine, because package managers and paths differ between them. Make the script fail fast with `set -e`, and make it safe to run more than once.
#### Architectures
Check that the script works on every CPU architecture you claim to support, such as `amd64` and `arm64`. Download URLs and binaries often differ per architecture, so a script that works on one may fail on another.
#### Options
Every option declared in `devcontainer-feature.json` should have a default and a description, so consumers can use the feature without reading the source. Options are passed to `install.sh` as environment variables with upper-case names, so confirm that the script reads each one under the same name.
#### Dependencies
List any other features or packages the feature needs. Install them in the script, or declare them with `dependsOn`, rather than assuming they are already present in the base image.
#### Documentation
Include a `README.md` in the feature directory that shows a minimal `devcontainer.json` example and lists every option. Consumers see this page in the registry.
#### Local test
Run the feature through the Dev Container CLI, for example with `devcontainer features test`, before you package and publish it. Fix any failures first, so the registry never receives a broken version.

### Publishing with the CLI

The `devcontainer` CLI publishes each feature in the `src/` directory as an OCI artifact:

```bash
devcontainer features publish \
  --registry ghcr.io \
  --namespace <owner>/<repo> \
  ./src
```

The command pushes one artifact per feature, for example `ghcr.io/<owner>/<repo>/my-tool:1.2.0`. It also creates the tags derived from the version, such as `1`, `1.2` and `latest`, so consumers can pin to a broad or a narrow range.

### Versioning rules

| Change                                                         | Version bump | Example           |
| -------------------------------------------------------------- | ------------ | ----------------- |
| Fix a bug in `install.sh` without changing options             | Patch        | `1.2.0` → `1.2.1` |
| Add a new option with a default                                | Minor        | `1.2.1` → `1.3.0` |
| Remove or rename an option, or change behavior users depend on | Major        | `1.3.0` → `2.0.0` |
Bump the `version` field before every publish. Republishing the same version does not update consumers who already pinned it.

### Referencing a published release
Users reference the release in their `devcontainer.json`:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/<owner>/<repo>/my-tool:1": {
      "someOption": "value"
    }
  }
}
```

Using the major tag (`:1`) receives compatible patch and minor updates. Using the full version (`:1.2.0`) freezes the feature at that release.

### Automating releases
Running publish from CI avoids manual pushes. The [`devcontainers/action` GitHub Action](https://github.com/devcontainers/action) can publish features on each tagged commit, after the workflow has checked out the repository and set the registry credentials.

## Execution
### Invoking `install.sh`
The `install.sh` script for each Feature should be executed as `root` during a container image build. This allows the script to add needed OS dependencies or settings that could not otherwise be modified. This also allows the script to switch into another user’s context using the `su` command (e.g., `su ${USERNAME} -c "command-goes-here"`). In combination, this allows both root and non-root image modifications to occur even if `sudo` is not present in the base image for security reasons.

To ensure that the appropriate shell is used, the execute bit should be set on `install.sh` and the file invoked directly (e.g. `chmod +x install.sh && ./install.sh`).

> [!NOTE]
> It is recommended that Feature authors write `install.sh` using a shell available by default in their supported distributions (e.g., `bash` in Debian/Ubuntu or Fedora, `sh` in Alpine). In the event a different shell is required (e.g., `fish`), `install.sh` can be used to bootstrap by checking for the presence of the desired shell, installing it if needed, and then invoking a secondary script using the shell.

The `install.sh` file can similarly be used to bootstrap something written in a compiled language like Go. Given the increasing likelihood that a Feature needs to work on both x86_64 and arm64-based devices (e.g., Apple Silicon Macs), `install.sh` can detect the current architecture (e.g., using something like `uname -m` or `dpkg --print-architecture`), and then invoke the right executable for that architecture.

### Installation order
By default, Features are installed on top of a base image in an order determined as optimal by the implementing tool.

If any of the following properties are provided in the Feature’s `devcontainer-feature.json`, or the user’s `devcontainer.json`, the order indicated by these properties are respected.

- The `dependsOn` property defined as a part of a Feature’s `devcontainer-feature.json`.
- The `installsAfter` property defined as part of a Feature’s `devcontainer-feature.json`.
- The `overrideFeatureInstallOrder` property in user’s `devcontainer.json`. Allows users to control the order of execution of their Features.

### The `installsAfter` Property
The `installsAfter` property indicates a “soft dependency” that influences the installation order of Features that are already queued to be installed. The effective behavior of this property is the same as `dependsOn`, with the following differences:

- `installsAfter` is **not** evaluated recursively.
- `installsAfter` only influences the installation order of Features that are **already set to be installed**. Any Feature not set to be installed after (1) resolving the `dependsOn` dependency tree or (2) indicated by the user’s `devcontainer.json` should not be added to the installation list.
- The Feature indicated by `installsAfter` can **not** provide options, nor are they able to be pinned to a specific version tag or digest. Resolution to the canonical name should still be performed (eg: If the Feature has been [renamed](https://containers.dev/implementors/features/#steps-to-rename-a-feature)).

```json
{
    "name": "My Feature",
    "id": "myFeature",
    "version": "1.0.0",
    "installsAfter": [
        "foo",
        "bar"
    ]
}
```

In the snippet above, `myfeature` must be installed after `foo` and `bar` **if** the Feature is already queued to be installed. If `second` and `third` are not already queued to be installed, this dependency relationship should be ignored.

### The `overrideFeatureInstallOrder` Property
The `overrideFeatureInstallOrder` property of `devcontainer.json` is an array of Feature IDs that are to be installed in descending priority order as soon as its dependencies outlined above are installed.

> This property may not indicate an installation order that is inconsistent with the resolved dependency graph (see [dependency algorithm](https://containers.dev/implementors/features/#dependency-installation-order-algorithm)). If the `overrideFeatureInstallOrder` property is inconsistent with the dependency graph, the implementing tool should fail the dependency resolution step.

This evaluation is performed by assigning a [`roundPriority`](https://containers.dev/implementors/features/#2-assigning-round-priority) to all nodes that match match the Feature identifier (version omitted) present in the property.

For example, given `n` Features in the `overrideFeatureInstallOrder` array, the orchestrating tool should assign a `roundPriority` of `n - idx` to each Feature, where `idx` is the zero-based index of the Feature in the array. For example:

```json
overrideFeatureInstallOrder = [
  "foo",
  "bar",
  "baz"
]
```

would result in the following `roundPriority` assignments:

```js
const roundPriority = {
  "foo": 3,
  "bar": 2,
  "baz": 1
}
```

This property must not influence the dependency relationship as defined by the dependency graph (see [dependency graph](https://containers.dev/implementors/features/#1-build-a-dependency-graph)) and shall only be evaulated at the round-based sorting step (see [round sort](https://containers.dev/implementors/features/#3-round-based-sorting)). Put another way, this property cannot “pull forward” a Feature until all of its dependencies (both soft and hard) have been installed. After a Feature’s dependencies have been installed in other rounds, this property should “pull forward” each Feature as early as possible (given the order of identifiers in the array).

Similar to `installsAfter`, this property’s members may not provide options, nor are they able to be pinned to a specific version tag or digest.

If a Feature is indicated in `overrideFeatureInstallOrder` but not a member of the dependency graph (it is not queued to be installed), the orchestrating tool may fail the dependency resolution step.

## Definitions
### Feature Equality
This specification defines two Features as equal if both Features point to the same exact contents and are executed with  the same options.

 **For Features published to an OCI registry**, two Feature are identical if their manifest digests are equal, and the > options executed against the Feature are equal (compared value by value). Identical manifest digests implies that the tgz contents of the Feature and its entire `devcontainer-feature.json` are identical. If any of these conditions are not met, the Features are considered not equal.
 
 **For Features fetched by HTTPS URI**, two Features are identical if the contents of the tgz are identical (hash to the > same value), and the options executed against the Feature are equal (compared value by value). If any of these conditions are not met, the Features are considered not equal.
 
**For local Features**, each Feature is considered unique and not equal to any other local Feature.

### Round Stable Sort
To prevent non-deterministic behavior, the algorithm will sort each **round** according to the following rules:
 
 - Compare and sort each Feature lexicographically by their fully qualified resource name (For OCI-published Features, that means the ID without version or digest.). If the comparison is equal:
 - Compare and sort each Feature from oldest to newest tag (`latest` being the “most new”). If the comparison is equal:
 - Compare and sort each Feature by their options by:
	 - Greatest number of user-defined options (note omitting an option will default that value to the Feature’s default value and is not considered a user-defined option). If the comparison is equal:
	 - Sort the provided option keys lexicographically. If the comparison is equal:
	 - Sort the provided option values lexicographically. If the comparision is equal:
 - Sort Features by their canonical name (For OCI-published Features, the Feature ID resolved to the digest hash).
 
If there is no difference based on these comparator rules, the Features are considered equal.

## Dependency installation order algorithm
 
An implementing tool is responsible for calculating the Feature installation order (or providing an error if no valid installation order can be resolved). The set of Features to be installed is the union of user-defined Features (those directly indicated in the user’s `devcontainer.json` and their dependencies (those indicated by the `dependsOn` or `installsAfter` property, taking into account the user dev container’s `overrideFeatureInstallOrder` property). The implementing tool will perform the following steps:

### (1) Build a dependency graph
 From the user-defined Features, the orchestrating tool will build a dependency graph. The graph will be built by traversing the `dependsOn` and `installsAfter` properties of each Feature. The metadata for each dependency is then fetched and the node added as an edge to to the dependent Feature. For `dependsOn` dependencies, the dependency will be fed back into the worklist to be recursively resolved.
 
An accumulator is maintained with all uniquely discovered and user-provided Features, each with a reference to its dependencies. If the exact Feature (see **[[#Feature Equality]]**) has already been added to the accumulator, it will not be added again. The accumulator will be fed into (B3) after the Feature tree has been resolved.
 
The graph may be stored as an adjacency list with two kinds of edges (1) `dependsOn` edges or “hard dependencies” and (2) `installsAfter` edges or *“soft dependencies”*.

### (2) Assigning round priority
Each node in the graph has an implicit, default `roundPriority` of 0.

To influence installation order globally while still honoring the dependency graph of built in **(1)**, `roundPriority` values may be tweaks for each Feature. When each round is calculated in **(3)**, only the Features equal to the max `roundPriority` of that set will be committed (the remaining will be uncommitted and reevaluated in subsequent rounds).

The `roundPriority` is set to a non-zero value in the following instances:

- If the [`devcontainer.json` contains an `overrideFeatureInstallOrder`](https://containers.dev/implementors/features/#overrideFeatureInstallOrder).

### (3) Round-based sorting
Perform a sort on the result of **(1)** in rounds. This sort will rearrange Features, producing a sorted list of Features to install. The sort will be performed as follows:

Start with all the elements from **(2)** in a `worklist` and an empty list `installationOrder`. While the `worklist` is not empty, iterate through each element in the `worklist` and check if all its dependencies (if any) are already members of `installationOrder`. If the check is true, add it to an intermediate list `round` If not, skip it. Equality is determined in (see **[[#Feature Equality]]**).

Then for each intermediate `round` list, commit to `installationOrder` only those nodes who share the maximum `roundPriority`. Return all nodes in `round` with a strictly lower `roundPriority` to the `worklist` to be reprocessed in subsequent iterations. If there are multiple nodes with the same `roundPriority`, commit them to `installationOrder` with a final sort according to **Round Stable Sort**.

Repeat for as many rounds as necessary until `worklist` is empty. If there is ever a round where no elements are added to `installationOrder`, the algorithm should terminate and return an error. This indicates a circular dependency or other fatal error in the dependency graph. Implementations should attempt to provide the user with information about the error and possible mitigation strategies.

> [!NOTE]
> From an implementation point of view, `installsAfter` nodes may be added as a separate set of directed edges, just as `dependsOn` nodes are added as directed edges (see **(1)**). Before round-based installation and sorting **(3)**, an orchestrating tool should remove all `installsAfter` directed edges that do not correspond with a Feature in the `worklist` that is set to be installed. In each round, a Feature can then be installed if all its requirements (both `dependsOn` and `installsAfter` dependencies) have been fulfilled in previous rounds.
> 
> An implementation should fail the dependency resolution step if the evaluation of the `installsAfter` property results in an inconsistent state (e.g.: a circular dependency).

## Option Resolution

A Feature’s `options` - specified as the value of a single Feature key/value pair in the user’s `devcontainer.json` - are passed to the Feature as environment variables.

A supporting tool will parse the `options` object provided by the user. If a value is provided for a Feature, it will be emitted to a file named `devcontainer-features.env` following the format `<OPTION_NAME>=<value>`.

To ensure a option that is valid as an environment variable, the follow substitutions are performed:

```js
(str: string) => str
	.replace(/[^\w_]/g, '_')
	.replace(/^[\d_]+/g, '_')
	.toUpperCase();
```

This file is sourced at build-time for the feature `install.sh` entrypoint script to handle.

Any options defined by a feature’s `devcontainer-feature.json` that are omitted in the user’s `devcontainer.json` will be implicitly exported as its default value.

### Option resolution example
Suppose a `python` Feature has the following `options` parameters declared in the `devcontainer-feature.json` file:

```json
// ...
"options": {
    "version": {
        "type": "string",
        "enum": ["latest", "3.10", "3.9", "3.8", "3.7", "3.6"],
        "default": "latest",
        "description": "Select a Python version to install."
    },
    "pip": {
        "type": "boolean",
        "default": true,
        "description": "Installs pip"
    },
    "optimize": {
        "type": "boolean",
        "default": true,
        "description": "Optimize python installation"
    }
}
```

The user’s `devcontainer.json` declared the python Feature like so:

```json
"features": {
    "ghcr.io/devcontainers/features/python:1": {
        "version": "3.10",
        "pip": false
    }
}
```

The emitted environment variables will be:

```sh
VERSION="3.10"
PIP="false"
OPTIMIZE="true"
```

These will be sourced and visible to the `install.sh` entrypoint script. The following `install.sh`…

```sh
#!/usr/bin/env bash

echo "Version is $VERSION"
echo "Pip? $PIP"
echo "Optimize? $OPTIMIZE"
```

… outputs the following:

```text
Version is 3.10
Pip? false
Optimize? true
```

## Implementation notes

There are several things to keep in mind for an application that implements Features:

- The order of execution of Features is determined by the application, based on the `installsAfter` property used by Feature authors. It can be overridden by users if necessary with the `overrideFeatureInstallOrder` in `devcontainer.json`.
- Features are used to create an image that can be used to create a container or not.
- Parameters like `privileged`, `init` are included if just 1 feature requires them.
- Parameters like `capAdd`, `securityOp` are concatenated.
- `containerEnv` is added before the feature is executed as `ENV` commands in the Dockerfile.
- Each Feature script executes as its own layer to aid in caching and rebuilding.


---

[^1]: OCI registry must implement the [OCI Artifact Distribution Specification](https://github.com/opencontainers/distribution-spec). Some implementors can be [found here](https://oras.land/implementors/).
[^2]: The provided path is always relative to the folder containing the `devcontainer.json`. Further requirements are outlined in the [Locally Referenced Addendum](https://containers.dev/implementors/features-distribution#addendum-locally-referenced).

---

