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
TEMPLATES_DIR="${ROOT_DIR}/templates"
TEMPLATE_CONFIG_DIR="${ROOT_DIR}/.template.config"

echo -e "${CYAN}Script directory: ${GREEN}${SCRIPT_DIR}${RESET}"
echo ""

#############################
# Functions
#############################
restore_template() {
  local template_name="$1"

  if [ -z "$template_name" ]; then
    echo -e "${RED}The first argument must be a string${RESET}"
    return 1
  fi

  local template_path="${TEMPLATES_DIR}/${template_name}"

  if [ ! -d "$template_path" ]; then
    echo -e "${RED}Path does not exist: ${YELLOW}${template_path}${RESET}"
    return 2
  fi

  if [ ! -f "$template_path/.git" ] && ! git -C "$template_path" rev-parse --git-dir >/dev/null 2>&1; then
    echo -e "${RED}Not a valid git repo: ${YELLOW}${template_path}${RESET}"
    return 3
  fi

  (
    echo -e "${GREEN}Restoring ${YELLOW}${template_path}${RESET}"
    cd "$template_path"

    current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"

    if [ -z "$current_branch" ]; then
      # detached HEAD
      git reset --hard
    else
      git fetch origin
      git reset --hard "origin/${current_branch}"
    fi

    git clean -fdx

    # submodules
    if [ -f .gitmodules ]; then
      git submodule sync --recursive
      git submodule update --init --recursive --force
      git submodule foreach --recursive 'git reset --hard || true'
      git submodule foreach --recursive 'git clean -fdx || true'
    fi

    echo -e "${CYAN}Template ${YELLOW}${template_name} ${CYAN}has been restored${RESET}"
    return 0
  )
}

restore_templates() {
  for dir in "$TEMPLATES_DIR"/*; do
    if [ -d "$dir" ]; then
      template_name="$(basename "$dir")"
      restore_template "$template_name"
    fi
  done
}

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
source $ENV_FILE
set +a

#############################
# Preparing templates
#############################
for dir in "$TEMPLATES_DIR"/*; do
  if [ -d "$dir" ]; then
    template_name="$(basename "$dir")"
    echo ""

    restore_template "$template_name"

    echo -e "${GREEN}Patching LICENSE file for template ${YELLOW}${template_name}${RESET}"
    sed -i -E 's/(Copyright \(c\)( [0-9]{4})? )snowyyd/\1LICENSE_HOLDER/' "$dir/LICENSE"

    echo -e "${GREEN}Copying template config for template ${YELLOW}${template_name}${RESET}"
    mkdir -p "$dir/.template.config/"
    rsync -a "$TEMPLATE_CONFIG_DIR/${template_name}.json" "$dir/.template.config/template.json"
  fi
done

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

  NUPKG_PATH="$ROOT_DIR/bin/Release/$PACKAGE_ID.$VERSION.nupkg"
  if [[ -z "$NUPKG_PATH" ]]; then
    echo -e "${YELLOW}.nupkg not found in ${GREEN}${NUPKG_PATH}${RESET}"
    exit 5
  fi

  echo ""
  echo -e "${GREEN}Pushing NuGet package to GitLab: ${YELLOW}${NUPKG_PATH}${RESET}"
  dotnet nuget push "$NUPKG_PATH" --source gitlab

  echo ""
  restore_templates

  echo ""
  echo -e "${YELLOW}Done!${RESET}"
)
