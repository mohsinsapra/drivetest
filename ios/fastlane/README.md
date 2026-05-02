fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

Build IPA only (no upload)

### ios upload

```sh
[bundle exec] fastlane ios upload
```

Upload last built IPA to TestFlight

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build + upload to TestFlight

### ios deploy_all

```sh
[bundle exec] fastlane ios deploy_all
```

Deploy to both iOS TestFlight and Android Play Store alpha

### ios production

```sh
[bundle exec] fastlane ios production
```

Deploy Production

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
