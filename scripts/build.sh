#!/bin/bash

#
# Build the E-kirjasto iOS app.
#
# Version 1.0.0
#

trap 'trap - INT; exit $((128 + $(kill -l INT)))' INT

# cd into the project root directory (or fail)
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.." || exit 64

# Show command usage
show_usage() {
  echo "Usage: $(basename "$0") [-h|--help] [BUILD_TYPE] [config:CONFIG]"
  echo
  # Wrap after 80 characters --> #######################################################
  echo "Options:"
  echo "-h   --help     Show this help page."
  echo "BUILD_TYPE      Build type to use. Available build types:"
  echo "                - debug (default):  debug build"
  echo "                - release:          release build (requires signing keys)"
  echo "                - release_upload:   release build and upload to Testflight"
  echo "                    - requires signing keys and App Store Connect API key"
  echo "CONFIG          Configuration flavor to use. Available configurations:"
  echo "                - ellibs:         Uses backend: circulation-beta.ellibs.com"
  echo "                - dev (default):  Uses backend: lib-dev.e-kirjasto.fi"
  echo "                - beta:           Uses backend: lib-beta.e-kirjasto.fi"
  echo "                - production:     Uses backend: lib.e-kirjasto.fi"
  # Wrap after 80 characters --> #######################################################
  echo
  echo "This script builds the E-kirjasto iOS app. This is mostly used for"
  echo "CI builds, but can be used locally as well."
  echo
}

fatal() {
  echo "$(basename "$0"): FATAL: $1" 1>&2
  exit "${2:-1}"
}

warn() {
  echo "$(basename "$0"): WARNING: $1" 1>&2
}

info() {
  echo "$(basename "$0"): INFO: $1" 1>&2
}

buildType="debug"
config="config:production"
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_usage
      exit 0
    ;;
    # Build type
    debug|release|release_upload)
        buildType="$1"
        shift
    ;;
    # Build configuration
    config:ellibs|config:dev|config:beta|config:production)
        config="$1"
        shift
    ;;
    # Error on unrecognized parameters
    *)
      show_usage
      fatal "Unrecognized parameter: $1" 65
    ;;
  esac
done


basename "$0"

info "Executing '$buildType' build ($config)"

if [[ "$buildType" == *"upload"* ]]; then
  # Increment the last digit of the build number based on build configuration
  targetLastDigit=0
  [[ "$config" == *"production"* ]] && targetLastDigit=1
  [[ "$config" == *"beta"*       ]] && targetLastDigit=2
  [[ "$config" == *"dev"*        ]] && targetLastDigit=3
  [[ "$config" == *"ellibs"*     ]] && targetLastDigit=4
  ./scripts/version.sh --increment-build-number-last-digit $targetLastDigit || exit $?
fi

./scripts/fastlane.sh ios "build_$buildType" "$config" || exit $?
