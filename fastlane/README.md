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

### ios print_testflight_build_number

```sh
[bundle exec] fastlane ios print_testflight_build_number
```

Print the latest build number from Testflight

### ios test

```sh
[bundle exec] fastlane ios test
```

Run tests

### ios build_debug

```sh
[bundle exec] fastlane ios build_debug
```

Run a debug build

### ios build_release

```sh
[bundle exec] fastlane ios build_release
```

Run a release build

### ios build_release_upload

```sh
[bundle exec] fastlane ios build_release_upload
```

Run a release build and upload to TestFlight

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
