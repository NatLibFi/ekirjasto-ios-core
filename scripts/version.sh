#!/bin/bash

#
# Manage the version of the E-kirjasto iOS app.
#
# Version 1.0.0
#

trap 'trap - INT; exit $((128 + $(kill -l INT)))' INT

# cd into the project root directory (or fail)
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.." || exit 64

# Show command usage
show_usage() {
  echo "Usage: $(basename "$0") [-h|--help] [OPTIONS]"
  echo
  # Wrap after 80 characters --> #######################################################
  echo "Options:"
  echo "-h   --help                     Show this help page."
  echo "     --check                    Check for inconsistencies in version and build"
  echo "                                numbers (does *NOT* check the formatting)."
  echo "     --get-version              Get the current version."
  echo "     --set-version=VERSION      Set the version to VERSION."
  echo "     --get-build-number         Get the current build number."
  echo "     --set-build-number=BUILD   Set the build number to BUILD."
  echo "     --increment-build-number [AMOUNT]"
  echo "                                Automatically* increment the build number."
  echo "                                AMOUNT is optional and defaults to 1."
  echo "     --increment-build-number-last-digit DIGIT"
  echo "                                Automatically* increment the build number's"
  echo "                                last digit to DIGIT."
  echo "     --increment-build-number-next-10"
  echo "                                Automatically* increment the build number,"
  echo "                                rounded to the nearest 10."
  # Wrap after 80 characters --> #######################################################
  echo
  echo " *) Automatic build number incrementation is based on the maxium build number"
  echo "    found locally or in App Store Connect (requires API key for Fastlane)."
  echo
  echo "This script manages the version of the E-kirjasto iOS app."
  echo
  echo "Note that the script doesn't really check the format of the version"
  echo "at all, but it should follow the Semantic Versioning format."
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

command="--get-version"
versionToSet=""
buildNumberToSet=""
buildNumberIncrementAmount=1
buildNumberTargetLastDigit=0
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_usage
      exit 0
    ;;
    --check)
      command="$1"
      shift
    ;;
    --get-version)
      command="$1"
      shift
    ;;
    --set-version)
      command="$1"
      shift
      versionToSet="$1"
      if [ -z "$versionToSet" ]; then
        fatal "--set-version requires a version to set" 65
      fi
      shift
    ;;
    --get-build-number)
      command="$1"
      shift
    ;;
    --set-build-number)
      command="$1"
      shift
      buildNumberToSet="$1"
      if [ -z "$buildNumberToSet" ]; then
        fatal "--set-build requires a build number to set" 66
      fi
      shift
    ;;
    --reset-build-number)
      command="$1"
      shift
      buildNumberToSet=10000
    ;;
    --increment-build-number)
      command="$1"
      shift
      if [[ $1 =~ ^[0-9]+$ ]] ; then
        buildNumberIncrementAmount=$1
        shift
      fi
    ;;
    --increment-build-number-last-digit)
      command="$1"
      shift
      if ! [[ $1 =~ ^[0-9]+$ ]] ; then
        fatal "--increment-build-number-last-digit requires DIGIT argument" 67
      fi
      buildNumberTargetLastDigit=$1
      shift
    ;;
    --increment-build-number-next-10)
      command="$1"
      shift
    ;;
    # Error on unrecognized parameters
    *)
      show_usage
      fatal "Unrecognized parameter: $1" 68
    ;;
  esac
done


projectFile="Palace.xcodeproj/project.pbxproj"

get_build_number() {
  buildNumberLines="$(grep -oE "CURRENT_PROJECT_VERSION = [\"']?[0-9]+\.?[0-9]*[^;\"']*" "$projectFile" | grep -oE "[0-9]+\.?[0-9]*")"
  buildNumber="$(echo "$buildNumberLines" | head -1)"
  while IFS= read -r line; do
    [[ "$line" == "$buildNumber" ]] || return 1
  done <<< "$buildNumberLines"
  echo "$buildNumber"
}


get_testflight_build_number() {
  fastlaneOutput="$(./scripts/fastlane.sh print_testflight_build_number)" \
    || return 1
  testflightBuildNumber="$(echo "$fastlaneOutput" | grep "TESTFLIGHT_BUILD_NUMBER_MAX=" | grep -Eo '[0-9]+')"
  echo "$testflightBuildNumber"
}

set_build_number() {
  buildNumberToSet="$1"
  sed -i '' 's/CURRENT_PROJECT_VERSION = .*;/CURRENT_PROJECT_VERSION = "'"$buildNumberToSet"'";/g' "$projectFile"
}

get_version() {
  versionLines="$(grep -oE "MARKETING_VERSION = [\"']?[0-9]+\.[0-9]+\.[0-9]+[^;\"']*" "$projectFile" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+.*")"
  version="$(echo "$versionLines" | head -1)"
  while IFS= read -r line; do
    [[ "$line" == "$version" ]] \
      || return 1
  done <<< "$versionLines"
  echo "$version"
}

set_version() {
  versionToSet="$1"
  sed -i '' 's/MARKETING_VERSION = .*;/MARKETING_VERSION = "'"$versionToSet"'";/g' "$projectFile"
}


case $command in
  --check)
    version="$(get_version)" \
      || fatal "All version numbers in '$projectFile' should match, but some of them are different" 69
    info "Version number: $version"
    build_number="$(get_build_number)" \
      || fatal "All build numbers in '$projectFile' should match, but some of them are different" 70
    info "Build number:   $build_number"
  ;;
  --get-version)
    version="$(get_version)" \
      || fatal "All version numbers in '$projectFile' should match, but some of them are different" 71
    echo "$version"
  ;;
  --set-version)
    info "NOTE: This script will not verify the format of the version string."
    info "Project file:        $projectFile"
    info "Version before:      $(get_version)"
    info "Setting version to:  $versionToSet"
    set_version "$versionToSet"
    info "Version was set to:  $(get_version)"
  ;;
  --get-build-number)
    build_number="$(get_build_number)" \
      || fatal "All build numbers in '$projectFile' should match, but some of them are different" 72
    echo "$build_number"
  ;;
  --set-build-number)
    info "Setting build number..."
    info "NOTE: This script will not verify the format of the build number string."
    info "Project file:             $projectFile"
    info "Build number before:      $(get_build_number)"
    info "Setting build number to:  $buildNumberToSet"
    set_build_number "$buildNumberToSet"
    info "Build number was set to:  $(get_build_number)"
  ;;
  --reset-build-number)
    info "Resetting build number..."
    info "Project file:             $projectFile"
    info "Build number before:      $(get_build_number)"
    info "Setting build number to:  $buildNumberToSet"
    set_build_number "$buildNumberToSet"
    info "Build number was set to:  $(get_build_number)"
  ;;
  --increment-build-number)
    info "Incrementing build number by 1, based on the maximum locally and in App Store Connect / Testflight..."
    testflightBuildNumber="$(get_testflight_build_number)" \
      || fatal "Failed to get build number from Testflight via Fastlane (missing App Store Connect API key?)" 73
    currentBuildNumber="$(get_build_number)"
    buildNumberMax=$((currentBuildNumber > testflightBuildNumber ? currentBuildNumber : testflightBuildNumber))
    buildNumberToSet=$((buildNumberMax + buildNumberIncrementAmount))
    info "Build number before:            $currentBuildNumber"
    info "Build number in Testflight:     $testflightBuildNumber"
    info "Incrementing build number by:   $buildNumberIncrementAmount"
    info "Setting build number to:        $buildNumberToSet"
    set_build_number "$buildNumberToSet"
    info "Build number was set to:        $(get_build_number)"
  ;;
  --increment-build-number-last-digit)
    info "Incrementing the build number's last digit (to $buildNumberTargetLastDigit), based on the maximum locally and in App Store Connect / Testflight..."
    testflightBuildNumber="$(get_testflight_build_number)" \
      || fatal "Failed to get build number from Testflight via Fastlane (missing App Store Connect API key?)" 74
    currentBuildNumber="$(get_build_number)"
    buildNumberMax=$((currentBuildNumber > testflightBuildNumber ? currentBuildNumber : testflightBuildNumber))
    buildNumberMaxLastDigit=$((buildNumberMax % 10))
    buildNumberIncrementAmount=$(( (buildNumberTargetLastDigit + 10 - buildNumberMaxLastDigit) % 10 ))
    # If the last digit is already correct, increment by 10
    [[ $buildNumberIncrementAmount == 0 ]] && buildNumberIncrementAmount=10
    buildNumberToSet=$((buildNumberMax + buildNumberIncrementAmount))
    info "Build number before:            $currentBuildNumber"
    info "Build number in Testflight:     $testflightBuildNumber"
    info "Incrementing build number by:   $buildNumberIncrementAmount"
    info "Setting build number to:        $buildNumberToSet"
    set_build_number "$buildNumberToSet"
    info "Build number was set to:        $(get_build_number)"
  ;;
  --increment-build-number-next-10)
    info "Incrementing build number to the next 10, based on the maximum locally and in App Store Connect / Testflight..."
    testflightBuildNumber="$(get_testflight_build_number)" \
      || fatal "Failed to get build number from Testflight via Fastlane (missing App Store Connect API key?)" 75
    currentBuildNumber="$(get_build_number)"
    buildNumberMax=$((currentBuildNumber > testflightBuildNumber ? currentBuildNumber : testflightBuildNumber))
    buildNumberToSet=$(( (buildNumberMax / 10 + 1) * 10 ))
    info "Build number before:                  $currentBuildNumber"
    info "Build number in Testflight:           $testflightBuildNumber"
    info "Setting build number to (nearest 10): $buildNumberToSet"
    set_build_number "$buildNumberToSet"
    info "Build number was set to:              $(get_build_number)"
  ;;
esac
