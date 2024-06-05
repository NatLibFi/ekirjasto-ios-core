#!/bin/bash

#
# Reveal E-kirjasto iOS secrets.
#
# Version 1.0.0
#

trap 'trap - INT; exit $((128 + $(kill -l INT)))' INT

# cd into the project root directory (or fail)
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.." || exit 64

# Show command usage
show_usage() {
  echo "Usage: $(basename "$0") [-h|--help] [--overwrite]"
  echo
  # Wrap after 80 characters --> #######################################################
  echo "Options:"
  echo "-h   --help           Show this help page."
  echo "     --overwrite      Ovewrite existing secret files."
  # Wrap after 80 characters --> #######################################################
  echo
  echo "This script reveals E-kirjasto build secrets from environment variables."
  echo
  echo "List of secret environment variables:"
  echo "- EKIRJASTO_FASTLANE_APP_STORE_CONNECT_API_KEY_JSON_BASE64"
  echo "    - Fastlane JSON file with the App Store Connect API key (base64 encoded)"
  echo "- EKIRJASTO_LIBLCP_DEPENDENCY_SECRET"
  echo "    - the liblcp secret dependency (only the secret part, not the full path)"
  echo "- EKIRJASTO_IOS_TRANSIFEX_TOKEN"
  echo "    - Transifex token (for localizations)"
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

overwrite=0
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_usage
      exit 0
    ;;
    # Overwrite existing secret files
    --overwrite)
        overwrite=1
        shift
    ;;
    # Error on unrecognized parameters
    *)
      show_usage
      fatal "Unrecognized parameter: $1" 65
    ;;
  esac
done


base64_to_file() {
  base64Input="$1"
  outputFile="$2"
  info "Revealing secret file: $outputFile"
  echo "$base64Input" | base64 --decode > "$outputFile"
}

reveal_file() {
  filepath="$1"
  envVariableName="$2"
  envVariableValue="${!envVariableName}"
  if [ "$overwrite" -ne 1 ] && [ -f "$filepath" ]; then
    info "File already exists, not overwriting: $filepath"
  else
    if [ -z "$envVariableValue" ]; then
      warn "Not revealing $filepath, because $envVariableName is not set"
    else
      base64_to_file "$envVariableValue" "$filepath"
    fi
  fi
}


basename "$0"

reveal_file fastlane/app-store-connect-api-key.json EKIRJASTO_FASTLANE_APP_STORE_CONNECT_API_KEY_JSON_BASE64

# macOS has an ancient version of sed, so find the correct arguments to use
sedArgs=(-i)
# Use the ancient invocation, if even using `--version` gives an error
if ! sed --version &> /dev/null; then
  sedArgs=(-i '')
fi


if [ -z "$EKIRJASTO_LIBLCP_DEPENDENCY_SECRET" ]; then
  info "Not revealing liblcp dependency secret, EKIRJASTO_LIBLCP_DEPENDENCY_SECRET is not set"
else
  info "Revealing revealing liblcp dependency secret"
  sed "${sedArgs[@]}" 's#/test/liblcp.json" ~> 3.0.0#/'"$EKIRJASTO_LIBLCP_DEPENDENCY_SECRET"'/liblcp.json" ~> 3.1.1#' \
    ./Cartfile
  sed "${sedArgs[@]}" 's#/test/liblcp.json" "3.0.0"#/'"$EKIRJASTO_LIBLCP_DEPENDENCY_SECRET"'/liblcp.json" "3.1.1"#' \
    ./Cartfile.resolved
fi

if [ -z "$EKIRJASTO_IOS_TRANSIFEX_TOKEN" ]; then
  info "Not revealing Transifex token, EKIRJASTO_IOS_TRANSIFEX_TOKEN is not set"
else
  info "Revealing Transifex token"
  # TODO:SAMI: Move the Transifex token to a config file, having it in the code feels *dirty*
  sed "${sedArgs[@]}" 's#token: ""#token: "'"$EKIRJASTO_IOS_TRANSIFEX_TOKEN"'"#' \
    ./Palace/Utilities/Localization/Transifex/TransifexManager.swift
  
  warn "To avoid accidentally committing the Transifex token, Git will ignore changes to TransifexManager.swift"
  git update-index --assume-unchanged ./Palace/Utilities/Localization/Transifex/TransifexManager.swift
  warn "To continue tracking changes to the file, run the following command:"
  echo "    git update-index --no-assume-unchanged ./Palace/Utilities/Localization/Transifex/TransifexManager.swift"
  echo
fi
