#!/bin/bash

#
# Bootstrap the repository.
#
# Version 1.0.0
#

trap 'trap - INT; exit $((128 + $(kill -l INT)))' INT

# cd into the project root directory (or fail)
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.." || exit 64

# Show command usage
show_usage() {
  echo "Usage: $(basename "$0") [-h|--help]"
  echo
  # Wrap after 80 characters --> #######################################################
  echo "Options:"
  echo "-h   --help               Show this help page."
  echo "     --overwrite-secrets  Overwrite secret files."
  # Wrap after 80 characters --> #######################################################
  echo
  echo "This script boostraps the repository and makes it ready to build."
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

overwriteSecrets=0
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_usage
      exit 0
    ;;
    --overwrite-secrets)
      overwriteSecrets=1
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

info "Bootstrapping the repo..."

#git submodule deinit adept-ios
#git rm -rf adept-ios
#git submodule deinit adobe-content-filter
#git rm -rf adobe-content-filter
#git submodule deinit ios-drm-audioengine
#git rm -rf ios-drm-audioengine
#git submodule deinit ios-audiobook-overdrive
#git rm -rf ios-audiobook-overdrive

if [ "$BUILD_CONTEXT" != "ci" ]; then
  git submodule update --init --recursive
fi

# Copy in Carthage files, if not there already
if [ ! -f "Cartfile" ]; then
  cp Cartfile.example Cartfile
fi
if [ ! -f "Cartfile.resolved" ]; then
  cp Cartfile.resolved.example Cartfile.resolved
fi

if [ ! -f "APIKeys.swift" ]; then
  cp Palace/AppInfrastructure/APIKeys.swift.example Palace/AppInfrastructure/APIKeys.swift
fi

if [ ! -f "PalaceConfig/ReaderClientCert.sig" ]; then
  cp PalaceConfig/ReaderClientCert.sig.example PalaceConfig/ReaderClientCert.sig
fi

# Reveal secrets
if [ $overwriteSecrets -eq 0 ]; then
  ./scripts/reveal-secrets.sh || exit $?
else
  ./scripts/reveal-secrets.sh --overwrite || exit $?
fi

# Build 3rd party dependencies
./scripts/build-3rd-party-dependencies.sh

# Reset the build number
./scripts/version.sh --reset-build-number || exit $?
