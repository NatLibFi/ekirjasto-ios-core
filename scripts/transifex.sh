#!/bin/bash

#
# Transifex iOS wrapper.
#
# Version 1.0.0
#

basename "$0"

trap 'trap - INT; exit $((128 + $(kill -l INT)))' INT

# cd into the project root directory (or fail)
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.." || exit 64

# Show command usage
show_usage() {
  echo "Usage: $(basename "$0") [-h|--help]"
  echo
  # Wrap after 80 characters --> #######################################################
  echo "Options:"
  echo "-h   --help           Show this help page."
  echo "     --append-tags    Append the listed tags to all strings (comma-separated)."
  echo "     --dry-run        Perform a dry-run of an upload."
  echo "     --purge          Purge any deleted source strings."
  echo "     --skip-upload    Skip upload even if the Transifex secret is given."
  # Wrap after 80 characters --> #######################################################
  echo
  echo "This script uploads and downloads Transifex strings."
  echo
  echo "The Transifex token (required) and secret (optional) should be set by using the"
  echo "EKIRJASTO_IOS_TRANSIFEX_TOKEN and EKIRJASTO_IOS_TRANSIFEX_SECRET environment"
  echo "variables."
  echo
  echo "The script always downloads/pulls strings from Transifex, so the token"
  echo "is required. The Transifex secret is optional, and if not given, then"
  echo "upload/push will be skipped."
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

appendTags=""
dryRun=0
purge=0
skipUpload=0
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_usage
      exit 0
    ;;
    --append-tags=*)
      appendTags="${1#*=}"
      shift
    ;;
    --dry-run)
      dryRun=1
      shift
    ;;
    --purge)
      purge=1
      shift
    ;;
    --skip-upload)
      skipUpload=1
      shift
    ;;
    # Error on unrecognized parameters
    *)
      show_usage
      fatal "Unrecognized parameter: $1" 65
    ;;
  esac
done

if [[ "$appendTags" == *" "* ]]; then
  fatal "No spaces allowed in --appendTags"
fi

if [ $skipUpload -eq 1 ] && [ -n "$appendTags" ]; then
  fatal "Cannot use --skip-upload and --append-tags together (cannot upload tags without uploading strings)" 66
fi

if [ $skipUpload -eq 1 ] && [ $dryRun -eq 1 ]; then
  fatal "Cannot use --skip-upload and --dry-run together (dry-runs are only for uploads, not downloads)" 67
fi

if [ $skipUpload -eq 1 ] && [ $purge -eq 1 ]; then
  fatal "Cannot use --skip-upload and --purge together (purge is only effective when uploading)" 68
fi

# Path to app's Transifex assets directory
assetsPath="Palace/Utilities/Localization/Transifex"

if [ -z "${EKIRJASTO_IOS_TRANSIFEX_TOKEN}" ]; then
  fatal "EKIRJASTO_IOS_TRANSIFEX_TOKEN is not defined" 69
fi

#------------------------------------------------------------------------
# Download and verify Transifex.
#

info "Downloading txios-cli (transifex-swift-cli)"

mkdir -p temp
(cd temp && rm -rf txios-cli*)
curl -sLo temp/txios-cli.tar.gz https://github.com/transifex/transifex-swift-cli/archive/refs/tags/2.1.6.tar.gz \
  || fatal "Could not download Transifex" 70

# Extract
(cd temp && tar xf txios-cli.tar.gz && mv transifex-swift-cli* txios-cli)

# Build
(cd temp/txios-cli && swift build -c release && cp .build/release/txios-cli ../../)
echo

# NOTE: This would be nice, but the SHA256 sum changes on every build...
# When updating, generate this file with: sha256sum txios-cli > txios-cli.sha256
#sha256sum -c txios-cli.sha256 \
#  || fatal "Could not verify txios-cli" 71

#------------------------------------------------------------------------
# Apply Transifex to the project's string resources.
#

if [ $skipUpload -eq 1 ]; then
  info "Skipping Transifex upload because of flag..."
elif [ -z "${EKIRJASTO_IOS_TRANSIFEX_SECRET}" ]; then
  echo
  warn "EKIRJASTO_IOS_TRANSIFEX_SECRET is not defined, UPLOAD WILL BE SKIPPED"
  echo
else
  TRANSIFEX_PUSH_ARGS="--verbose"

  if [ $dryRun -eq 1 ]; then
    TRANSIFEX_PUSH_ARGS="${TRANSIFEX_PUSH_ARGS} --dry-run"
  fi

  if [ $purge -eq 1 ]; then
    TRANSIFEX_PUSH_ARGS="${TRANSIFEX_PUSH_ARGS} --purge"
  fi

  if [ -n "$appendTags" ]; then
    TRANSIFEX_PUSH_ARGS="${TRANSIFEX_PUSH_ARGS} --append-tags=$appendTags"
  fi

  TRANSIFEX_PUSH_ARGS="${TRANSIFEX_PUSH_ARGS} --project=Palace.xcodeproj"

  TRANSIFEX_PUSH_ARGS="${TRANSIFEX_PUSH_ARGS} --token=${EKIRJASTO_IOS_TRANSIFEX_TOKEN}"
  TRANSIFEX_PUSH_ARGS="${TRANSIFEX_PUSH_ARGS} --secret=${EKIRJASTO_IOS_TRANSIFEX_SECRET}"

  info "Uploading Transifex strings"

  ./txios-cli push ${TRANSIFEX_PUSH_ARGS} \
    || fatal "Could not upload Transifex strings" 73

  info "Upload done!"
  echo
fi

TRANSIFEX_PULL_ARGS="--token=${EKIRJASTO_IOS_TRANSIFEX_TOKEN}"

TRANSIFEX_PULL_ARGS="${TRANSIFEX_PULL_ARGS} --output=$assetsPath"

# Find the list of langauges from the code
languages="$(grep 'let appLanguages' Palace/Utilities/Localization/Transifex/TransifexManager.swift | grep -Eo '".*"' | grep -Eo '[^"]+')"
IFS="," read -r -a languages <<< "$languages"
info "Languages: ${languages[*]}"
for language in "${languages[@]}"; do
  TRANSIFEX_PULL_ARGS="${TRANSIFEX_PULL_ARGS} --translated-locales=$language"
done

info "Downloading Transifex strings"

./txios-cli pull ${TRANSIFEX_PULL_ARGS} \
  || fatal "Could not download Transifex strings" 74

info "Download done!"
echo

#------------------------------------------------------------------------
# Prettify Transifex JSON file.
#

transifexFile="$assetsPath/txstrings.json"
info "Prettifying JSON file: $transifexFile"
# jq might be nicer than json_pp, but it's usually available on macOS and Linux
{ json_pp > "$transifexFile~"; } < "$transifexFile"
mv "$transifexFile~" "$transifexFile"
