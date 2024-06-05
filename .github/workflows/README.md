# GitHub Actions workflows

This directory contains E-kirjasto iOS CI workflows.


## Secrets

Secrets are stored in GitHub Actions and are available to the workflows as
environment variables.
The secrets are stored in the respective repository,
so secrets for the Android CI workflows are stored in ekirjasto-android-core,
while secrets for the iOS CI workflows are stored in ekirjasto-ios-core, etc.

GitHub Actions doesn't directly support storing files, so files are stored as
base64 encoded strings and decoded back into files (by `scripts/reveal-secrets.sh`).

[ekirjasto-ci-helper](https://github.com/NatLibFi/ekirjasto-ci-helper) is used
to manage the secrets.
It cannot read the secrets, but it can be used to set or delete secrets.
It requires a GitHub personal access token with rights to the repository.


### iOS secrets

The secrets in use for the iOS CI workflows are:

| Secret name                             | Environment variable                                     | Format | Description                                      |
|-----------------------------------------|----------------------------------------------------------|--------|--------------------------------------------------|
| FASTLANE_APP_STORE_CONNECT_API_KEY_JSON | EKIRJASTO_FASTLANE_APP_STORE_CONNECT_API_KEY_JSON_BASE64 | base64 | App Store Connect API key JSON (base64 encoded)  |
| LIBLCP_DEPENDECY_SECRET                 | EKIRJASTO_LIBLCP_DEPENDENCY_SECRET                       | text   | The secret part of the liblcp dependency path    |
| MATCH_PASSWORD                          | MATCH_PASSWORD                                           | text   | Password for Fastlane match (ekirjasto-ios-keys) |
| SSH_PRIVATE_KEY                         | N/A                                                      | text   | SSH private key (E-kirjasto CI machine account)  |
| TRANSIFEX_SECRET                        | EKIRJASTO_IOS_TRANSIFEX_SECRET                           | text   | The iOS Transifex secret                         |
| TRANSIFEX_TOKEN                         | EKIRJASTO_IOS_TRANSIFEX_TOKEN                            | text   | The iOS Transifex token                          |


### Log masking secrets

In addition to the above secrets, there are some additional values where the
name starts with `MASK_`. These secrets are not used at all in the build, and
their purpose just to mask the values from GitHub Actions logs (there are other
ways to achieve log masking, but this is the easiest method).

For example, the liblcp dependency path in `Cartfile` is a secret and should be
masked in logs, but the entire file is stored as one secret, so the individual
dependecy path would not be automatically masked without the `MASK_*` secrets.


## iOS CI workflows

### ios-pr.yml

This workflow is run for every commit pushed to a PR.

This workflow builds a debug build with the production configuration,
and release builds for the dev, beta, and productions configurations,
and runs tests.


### ios-main.yml

This workflow is run for every commit pushed to the main branch.
Direct commits to main are disabled, so essentially this is run for merged PRs.

This workflow does the same builds and runs the same tests as the PR workflow,
but in addition to those, the dev, beta and production release builds are uploaded to Testflight.
Before the uploads, some minimal release checks are run,
so that uploads wouldn't fail because of things like a version suffix.


### ios-release.yml

This workflow is run for commits on release/* branches (e.g. release/1.2.3).

This workflow is mostly the same as the main CI workflow,
meaning that all builds and tests are run,
and the same uploads are made, but some additional release checks are made.

Before the uploads some additional checks are run:
- there must not be any suffix in the version name (also checked in the main workflow)
    - while Xcode allows using a suffix for iOS apps, App Store Connect will not allow using any suffix
- the version number must be increased from the one currently in main
- all Transifex strings must be committed into the repository
    - i.e. `scripts/transifex.sh` must not find new strings to download

The main purpose of this workflow is to automate releasing a new version,
but not everything is automated (by design). See [RELEASING.md](/RELEASING.md)
for what to do after upload and more info about E-kirjasto's releasing process.
