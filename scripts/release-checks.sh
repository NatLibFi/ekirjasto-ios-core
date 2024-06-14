#!/bin/bash

#
# Run release checks for the E-kirjasto iOS app.
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
  echo "-h   --help                     Show this help page."
  echo "     --minimal                  Only perform minimal checks, just for upload."
  echo "     --skip-transifex-download  Skip downloading new Transifex strings."
  # Wrap after 80 characters --> #######################################################
  echo
  echo "This script checks if a new E-kirjasto version is ready for release."
  echo "Release checks include:"
  echo "- the version number must be increased from the version in the main branch"
  echo "- the version can't contain any suffix (App Store Connect doesn't allow them)"
  echo "- Transifex cannot have any new strings that have not been committed to Git"
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

minimal=0
skipTransifexDownload=0
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_usage
      exit 0
    ;;
    --minimal)
      minimal=1
      shift
    ;;
    --skip-transifex-download)
      skipTransifexDownload=1
      shift
    ;;
    # Error on unrecognized parameters
    *)
      show_usage
      fatal "Unrecognized parameter: $1" 65
    ;;
  esac
done


#
# Get a string for comparing version.
#
# This takes a version string that follows the semantic versioning format
# (basically major.minor.patch, any suffix is ignored) and returns a comparison
# string. These comparison strings can be compared alphabetically to find which
# version is higher.
#
getVersionComparisonString() {
  version="$1"
  if grep -E '^[0-9]+\.[0-9]+\.[0-9]+' <<< "$version" > /dev/null 2>&1; then
    # The version has correct syntax (at least major.minor.patch, suffix is not checked)
    version="${version//[!0-9]/ }"
    read -ra version <<< "$version"
    major="${version[0]}"
    minor="${version[1]}"
    patch="${version[2]}"
    echo "$(printf %04d "$major")$(printf %04d "$minor")$(printf %04d "$patch")"
  else
    # Incorrect format, treat the same as 0.0.0
    echo "000000000000"
  fi
}


basename "$0"

# Check for a suffix in the version
info "Checking for suffix in version name..."
currentVersion="$(./scripts/version.sh --get-version)"
currentVersionWithoutSuffix="$(grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' <<< "$currentVersion")"
if [[ "$currentVersion" != "$currentVersionWithoutSuffix" ]]; then
  suffix="${currentVersion:${#currentVersionWithoutSuffix}}"
  fatal "The version in the current commit ($currentVersion) must not have any suffix, but has '$suffix'" 68
fi

if [ $minimal -eq 1 ]; then
  info "Minimal checks done, exiting..."
  exit 0
fi

info "Checking for version increment (comparing with the main branch)..."
# Find Git diff of the version change between the current commit and main
git fetch --no-recurse-submodules origin main
versionDiff="$(git diff -U0 origin/main -- Palace.xcodeproj/project.pbxproj | grep -E '^[+-].*MARKETING_VERSION ?=')"
if [ -z "$versionDiff" ]; then
  fatal "The version number must be increased compared to the main branch, but no changes were found" 66
fi

# Get the old version (main branch) and the new version (current commit)
oldVersion="$(grep '^-' <<< "$versionDiff")"
# Get only the first changed line (multiple lines contain the version)
oldVersion="$(echo "$oldVersion" | head -1)"
# Get only the version (strip everything else around it)
oldVersion="$(grep -Eo '[0-9]+\.[0-9]+\.[0-9]+[^"'\'';]*' <<< "$oldVersion")"
info "Old version: $oldVersion"
newVersion="$(grep '^+' <<< "$versionDiff")"
# Get only the first changed line (multiple lines contain the version)
newVersion="$(echo "$newVersion" | head -1)"
# Get only the version (strip everything else around it)
newVersion="$(grep -Eo '[0-9]+\.[0-9]+\.[0-9]+[^"'\'';]*' <<< "$newVersion")"
info "New version: $newVersion"

oldVersionComparison="$(getVersionComparisonString "$oldVersion")"
newVersionComparison="$(getVersionComparisonString "$newVersion")"
if [[ $oldVersionComparison < $newVersionComparison ]]; then
  info "The version in the current commit ($newVersion) is newer than the version in the main branch ($oldVersion), all good!"
else
  fatal "The version in the current commit ($newVersion) must be higher than the version in the main branch ($oldVersion)" 67
fi


if [ $skipTransifexDownload -eq 1 ]; then
  info "Skipping Transifex download because of flag..."
else
  info "Running Transifex download (skipping upload)..."
  ./scripts/transifex.sh --skip-upload || exit $?
fi

info "Checking that there are no new Transifex strings..."
changedTransifexFiles="$(git diff --name-only HEAD | grep txstrings.json)"
if [ -z "$changedTransifexFiles" ]; then
  info "Found no changes to Transifex strings, all good!"
else
  warn "Found changes to the following Transifex files:"
  echo "$changedTransifexFiles"
  message="Found unexpected changes to localizations on Transifex download, please commit any changes"
  if [ -n "$GITHUB_ACTIONS" ]; then
    # In GitHub Actions, show warnings, but don't fail the CI build
    while IFS= read -r filepath; do
      echo "::error file=$filepath::$message"
    done <<< "$changedTransifexFiles"
  else
    # Locally, exit with an error code
    fatal "$message" 69
  fi
fi
