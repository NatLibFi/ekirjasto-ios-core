#!/bin/bash

#
# Clean the E-kirjasto iOS app build.
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
  echo "-h   --help     Show this help page."
  # Wrap after 80 characters --> #######################################################
  echo
  echo "This script (agressively) cleans the E-kirjasto iOS app build."
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

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_usage
      exit 0
    ;;
    # Error on unrecognized parameters
    *)
      show_usage
      fatal "Unrecognized parameter: $1" 65
    ;;
  esac
done


basename "$0"

info "Cleaning..."

# xcodebuild's clean fails way too easily, which isn't great for a "clean" command
#xcodebuild -project Palace.xcodeproj clean || exit $?

rm -fr Carthage 2> /dev/null
sudo rm -fr "$HOME/Library/Developer/Xcode/DerivedData/"* || exit $?

echo
info "Remember to bootstrap again:"
echo "    ./scripts/bootstrap.sh"
echo
