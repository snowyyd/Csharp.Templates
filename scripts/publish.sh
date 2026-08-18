#!/bin/bash
set -e

#############################
# Colors
#############################
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

#############################
# Configs
#############################
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ROOT_DIR="$(realpath "${SCRIPT_DIR}/../")"

echo -e "${CYAN}Script directory: ${GREEN}${SCRIPT_DIR}${RESET}"
echo ""

#############################
# Validate .env
#############################
ENV_FILE="${ROOT_DIR}/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo -e "${YELLOW}.env file not found in ${GREEN}${ENV_FILE}${RESET}"
  exit 1
fi

echo -e "${GREEN}Loading ${YELLOW}${ENV_FILE}${RESET}"
set -a
source "$ENV_FILE"
set +a

#############################
# Pack
#############################
(
  echo ""
  echo -e "${GREEN}Fetching package info...${RESET}"

  CSPROJ_FILE=$(find "$ROOT_DIR" -maxdepth 1 -name "*.csproj" | head -n 1)
  if [[ -z "$CSPROJ_FILE" ]]; then
    echo -e "${YELLOW}No .csproj file found in ${GREEN}${ROOT_DIR}${RESET}"
    exit 2
  fi
  echo -e "${CYAN}Found .csproj file: ${GREEN}${CSPROJ_FILE}${RESET}"

  VERSION=$(grep -oP '(?<=<Version>)(.*)(?=</Version>)' "$CSPROJ_FILE")
  if [[ -z "$VERSION" ]]; then
    echo -e "${YELLOW}Version not found in .csproj file!${RESET}"
    exit 3
  fi
  echo -e "${CYAN}Found version: ${GREEN}${VERSION}${RESET}"

  PACKAGE_ID=$(grep -oP '(?<=<PackageId>)(.*)(?=</PackageId>)' "$CSPROJ_FILE")
  if [[ -z "$PACKAGE_ID" ]]; then
    echo -e "${YELLOW}PackageId not found in .csproj file!${RESET}"
    exit 4
  fi
  echo -e "${CYAN}Found PackageId: ${GREEN}${PACKAGE_ID}${RESET}"

  echo ""
  echo -e "${GREEN}Packing NuGet...${RESET}"
  dotnet pack -c Release

  NUPKG_PATH="$ROOT_DIR/artifacts/package/release/$PACKAGE_ID.$VERSION.nupkg"
  if [[ -z "$NUPKG_PATH" ]]; then
    echo -e "${YELLOW}.nupkg not found in ${GREEN}${NUPKG_PATH}${RESET}"
    exit 5
  fi

  echo ""
  echo -e "${GREEN}Pushing NuGet package to GitLab: ${YELLOW}${NUPKG_PATH}${RESET}"
  dotnet nuget push "$NUPKG_PATH" --source gitlab

  echo ""
  echo -e "${YELLOW}Done!${RESET}"
)
