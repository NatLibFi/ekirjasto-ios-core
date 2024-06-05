# E-kirjasto iOS core

[![ios-main](https://github.com/NatLibFi/ekirjasto-ios-core/actions/workflows/ios-main.yml/badge.svg)](https://github.com/NatLibFi/ekirjasto-ios-core/actions/workflows/ios-main.yml)

The National Library of Finland's fork of the Palace Project iOS client,
which is itself the Lyrasis fork of the NYPL's Library Simplified iOS client.


## System requirements

- Install Xcode 15.4 in `/Applications`, open it and make sure to install additional components if it asks you.
- Install [Carthage](https://github.com/Carthage/Carthage) if you haven't already.
    - Using Homebrew is recommended, so run `brew install carthage`.


## Building

```bash
git clone git@github.com:NatLibFi/ekirjasto-ios-core.git
cd ekirjasto-ios-core

# Idempotent bootstrap script, can be run again to rebuild dependencies
./scripts/bootstrap.sh
```

The above bootstrap script also reveals secrets for production builds.
For more info, see `./scripts/reveal-secrets.sh --help`.

Open `Palace.xcodeproj` in Xcode and build the `Ekirjasto` target.

Alternatively, you can build the app by running `./scripts/build.sh`
(use `--help` to see build options).

At this point you may have seemingly random build errors especially if you are
not using an Intel chip (M1/M2/M3/etc.) but running this script might help:

```bash
# Requires sudo, because it also cleans ~/Library/Developer/Xcode/DerivedData/
./scripts/clean.sh
```

If you get `Missing package product '...'` errors,
closing and reopening the Xcode project should help.


### Build configurations

The app uses build configurations to switch the backend.
The configurations are of the form `<BuildType>-<configuration>`,
so for example `Debug-dev` is a debug build using the `dev` configuration/backend.

The available configurations are:

| Configuration      | Build type | Backend    |
|--------------------|------------|------------|
| Debug              | debug      | production |
| Debug-ellibs       | debug      | ellibs     |
| Debug-dev          | debug      | dev        |
| Debug-beta         | debug      | beta       |
| Debug-production   | debug      | production |
| Release            | release    | production |
| Release-ellibs     | release    | ellibs     |
| Release-dev        | release    | dev        |
| Release-beta       | release    | beta       |
| Release-production | release    | production |

The `Debug` and `Debug-production` are essentially identical,
and they both use the `production` backend.
The same is true for `Release` and `Release-production`.

The `Debug` and `Release` configurations are there only for "compatibility",
because some tools (like Carthage) appear to not work nicely if they don't exist,
but you shouldn't need to *use* them (just don't delete them).

To choose the build configuration to use in Xcode,
`Alt-click` the "Run" button and choose which one to use for running, profiling, etc.


## Branching

`main` is the main development branch, and is only updated through pull requests.

Release branch names follow the convention: `release/<version>` (e.g. `release/1.2.3`).


## Continuous integration (CI)

The repository uses continuous integration to aid development and to automate releases.

See [.github/workflows/README.md] for more information about the CI workflows.


## Releasing

Please see [RELEASING.md](RELEASING.md) for documentation on E-kirjasto's release process.


## License

Copyright © 2021 LYRASIS and The National Library of Finland (Kansalliskirjasto)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
