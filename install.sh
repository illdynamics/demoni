#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────────
# Demoni Installer — curl | bash oneliner
# ───────────────────────────────────────────────────────────────────
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/illdynamics/demoni/main/install.sh | bash
#
# Downloads the latest release zip, extracts it, and runs ./demoni install.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

REPO="illdynamics/demoni"
GITHUB_API="https://api.github.com/repos/${REPO}"
TMP_DIR=""

# ── Cleanup on exit ──────────────────────────────────────────────

cleanup() {
  if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
    rm -rf "${TMP_DIR}"
  fi
}
trap cleanup EXIT

# ── Colors ───────────────────────────────────────────────────────

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

info()  { echo -e "${GREEN}→${RESET} ${BOLD}$*${RESET}"; }
warn()  { echo -e "${YELLOW}⚠${RESET} $*"; }
error() { echo -e "${RED}✗${RESET} $*" >&2; exit 1; }

# ── Detect platform ──────────────────────────────────────────────

detect_platform() {
  case "$(uname -s)" in
    Linux)  echo "linux" ;;
    Darwin) echo "macos" ;;
    *)      error "Unsupported platform: $(uname -s). Demoni supports Linux and macOS." ;;
  esac
}

# ── Check prerequisites ──────────────────────────────────────────

check_prereqs() {
  local missing=()

  if ! command -v curl &>/dev/null; then
    missing+=("curl")
  fi
  if ! command -v unzip &>/dev/null; then
    missing+=("unzip")
  fi
  if ! command -v podman &>/dev/null && ! command -v docker &>/dev/null; then
    warn "Neither podman nor docker found. You'll need one to build the image."
    warn "  Install: brew install podman (macOS) or apt install podman (Linux)"
    echo ""
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing required tools: ${missing[*]}. Install them and try again."
  fi
}

# ── Get latest release tag ───────────────────────────────────────

get_latest_tag() {
  local tag
  tag=$(curl -fsSL "${GITHUB_API}/releases/latest" 2>/dev/null | \
    grep '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')

  if [[ -z "${tag}" ]]; then
    # Fallback: try git tags
    tag=$(curl -fsSL "${GITHUB_API}/git/refs/tags" 2>/dev/null | \
      grep '"ref":' | tail -1 | sed -E 's/.*"ref": *"refs\/tags\/([^"]+)".*/\1/')
  fi

  if [[ -z "${tag}" ]]; then
    error "Could not determine latest release tag. Please install manually:"
    echo "  git clone https://github.com/${REPO}.git"
    echo "  cd demoni && ./demoni install"
  fi

  echo "${tag}"
}

# ── Main ─────────────────────────────────────────────────────────

main() {
  local platform
  platform=$(detect_platform)

  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║       Demoni Installer (${platform})        ║${RESET}"
  echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
  echo ""

  check_prereqs

  # Get latest tag
  info "Fetching latest release..."
  local tag
  tag=$(get_latest_tag)
  info "Latest release: ${tag}"

  # Download and extract
  TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t demoni-install)
  local archive_url="https://github.com/${REPO}/releases/download/${tag}/demoni-${tag}.zip"
  local archive="${TMP_DIR}/demoni-${tag}.zip"

  info "Downloading demoni-${tag}.zip..."
  curl -fsSL "${archive_url}" -o "${archive}" || \
    error "Failed to download ${archive_url}"

  info "Extracting..."
  unzip -q "${archive}" -d "${TMP_DIR}" || \
    error "Failed to extract archive"

  # Run ./demoni install
  local extract_dir="${TMP_DIR}/demoni-${tag}"
  if [[ ! -d "${extract_dir}" ]]; then
    # Try to find the extracted directory
    extract_dir=$(find "${TMP_DIR}" -maxdepth 2 -name "demoni" -type f | head -1)
    if [[ -z "${extract_dir}" ]]; then
      error "Could not find ./demoni in extracted archive"
    fi
    extract_dir=$(dirname "${extract_dir}")
  fi

  info "Installing Demoni..."
  cd "${extract_dir}"
  chmod +x demoni
  ./demoni install
}

main "$@"
