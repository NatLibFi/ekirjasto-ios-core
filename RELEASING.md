# Releasing

Releasing of the E-kirjasto Android app is mostly automated through a CI workflow.


## The short version (TL;DR)

- Create a release branch, for example `release/1.2.3`
    - Update the version by running e.g. `./scripts/release.sh --set-version 1.2.3`
    - Fill in the changelogs at `metadata/<language>/changelog.txt`
- In GitHub Actions, check that the build and all checks will pass
    - If something fails, the build will not be uploaded to App Store Connect
- Once the build is uploaded to App Store Connect
    - Promote the build to production
    - Send the release for app review
    - After the app passes review, it can be published


## Version numbers

The script at `scripts/version.sh` should be used to manage the version number.
See the script's `--help` option for mode information.

The version number should follow the [Semantic Versioning](https://semver.org/) format.
Basically, the version number is of the form `major.minor.patch`.
App Store Connect doesn't allow any suffix in the version, so they can't be used.

The version number should be incremented as follows:
- the `major` component should increase for any major new functionality
    - the `major` component should also increase for any non-backward-compatible changes
    - if the `major` component increases, both `minor` and `patch` are "reset" to zero
        - for example, `1.2.3` becomes `2.0.0` when increasing the `major` component
- the `minor` component should increase for any new features
    - if the `minor` component increases, `patch` is "reset" to zero
        - for example, `1.2.3` becomes `1.3.0` when increasing the `minor` component
- the patch version should increase for bugfixes and other minor changes
- the version components should not have any leading zeroes
- the version components can have multiple digits (e.g. 1.0.9 can increase to 1.0.10)


## Build numbers

The script at `scripts/version.sh` should be used to manage the build number.
See the script's `--help` option for mode information.

That said, you shouldn't have to modify the build number at all,
since it is automatically increased on every upload to App Store Connect / Testflight.

Based on the build configuration, the last digit of the build number is set to:

| Configuration | Last digit in version code |
|---------------|----------------------------|
| production    | 1                          |
| beta          | 2                          |
| dev           | 3                          |
| ellibs        | 4                          |

This way all different build configurations of the same build/commit can be uploaded to App Store Connect.
But note that the different configurations should be uploaded in the above order, so that the other digits apart from the last will match for the same build/commit.


## Creating a new release

### Building and uploading to App Store Connect

#### Automated CI workflow (recommended)

To create a new release, create a branch of the form `release/<version>`.
For example, the release branch name could be `release/1.2.3` or `release/3.20.1-suffix`.

Increase the version number by running something like:
- `./scripts/version.sh --set-version 1.2.3`

Edit these files for the changelog (will be visible to users in App Store / Testflight):
- `metadata/<language>/changelog.txt`

When a release branch is created, the `ios-release` workflow:
- performs release checks
    - the version number must increase from the main branch
    - there must not be any uncommitted Transifex strings
        - these should be downloaded using `./scripts/transifex.sh`
            - see `--help` for setting the Transifex token and secret
- builds both debug and release builds for all flavors
- uploads the release build to App Store Connect / Testflight

If the release checks and everything else in the CI workflow goes okay,
the release build will be uploaded to App Store Connect / Testflight.


#### Manual build and upload

Alternatively, the release process can be done manually.

In order to perform a release build, you need:
- run `./scripts/bootstrap.sh` with the secret environment variables set
    - run `./scripts/reveal-secrets.sh --help` for a list of the environemnt variables
- the certificates and provisioning profiles for signing the build
    - these are stored in the `ekirjasto-ios-keys` repository, so you need access there
    - the keys are managed by Fastlane, and you will need the encryption password to use them
    - to get the keys from the repo, run `fastlane match` and follow the instructions

First, update the version number using `./scripts/version.sh --set-version x.y.z`.

Then, build the release version of the production flavor:
- either by running `./scripts/build.sh release`
- or manually in Xcode (via `Product` > `Archive`)

Once you've built the release archive, you can upload it to App Store Connect:
- either by running `./scripts/build.sh release_upload`
    - this also builds the release archive, so you don't have to run `build.sh release` separately
    - this defaults to the `production` config, but you can add e.g. `configuration:beta` to the command to use another backend
- or create a new version and upload it manually in App Store Connect


### Publishing an uploaded build

Once a release build archive is uploaded to App Store Connect,
you can promote it to a production version and send it for app review.

Assuming review passes, the app can be published to production!
