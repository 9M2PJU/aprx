#!/usr/bin/env bash
# ==============================================================================
# 📡 APRX Interactive Automated Installer
# Project: https://github.com/9M2PJU/aprx-installer
# Supports: Debian, Ubuntu, Raspberry Pi OS, Fedora, Arch Linux, FreeBSD, macOS
# ==============================================================================

set -e

# Reconnect stdin to terminal if script is piped (e.g., curl ... | bash)
if [ ! -t 0 ] && [ -e /dev/tty ]; then
    exec < /dev/tty
fi

# Terminal colors
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REPO="9M2PJU/aprx-installer"
DEFAULT_VERSION="v2.9.1"

print_banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}"
    echo "================================================================="
    echo "       📡 APRX — Amateur Radio APRS IGate & Digipeater          "
    echo "                Automated Universal Installer                   "
    echo "================================================================="
    echo -e "${NC}"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Determine OS and Architecture
detect_system() {
    OS_TYPE="$(uname -s | tr '[:upper:]' '[:lower:]')"
    ARCH_RAW="$(uname -m)"

    case "$ARCH_RAW" in
        x86_64|amd64)
            ARCH="x86_64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l|armv7|armhf)
            ARCH="armhf"
            ;;
        armv6l)
            ARCH="armhf"
            ;;
        *)
            ARCH="$ARCH_RAW"
            ;;
    esac

    DISTRO="unknown"
    if [ "$OS_TYPE" = "linux" ]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO="$ID"
            DISTRO_LIKE="${ID_LIKE:-}"
        fi
    elif [ "$OS_TYPE" = "freebsd" ]; then
        DISTRO="freebsd"
    elif [ "$OS_TYPE" = "darwin" ]; then
        DISTRO="macos"
    fi

    log_info "Detected OS: ${BOLD}${OS_TYPE} (${DISTRO})${NC} | Architecture: ${BOLD}${ARCH}${NC}"
}

# Check for root/sudo privileges
check_privileges() {
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            SUDO="sudo"
        else
            log_error "This script requires root privileges to install system packages and services. Please run as root or install sudo."
            exit 1
        fi
    else
        SUDO=""
    fi
}

# Fetch latest release version from GitHub API
get_latest_version() {
    log_info "Fetching latest release information from GitHub..."
    LATEST_TAG=$(curl -sSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)
    if [ -z "$LATEST_TAG" ]; then
        LATEST_TAG="$DEFAULT_VERSION"
    fi
    VERSION_NUM="${LATEST_TAG#v}"
    log_info "Target Version: ${BOLD}${LATEST_TAG}${NC} (Aprx ${VERSION_NUM})"
}

# Select installation method
select_install_mode() {
    echo ""
    echo -e "${BOLD}Select Installation Method:${NC}"
    echo "  1) 🚀 Native System Package / Binary (Recommended for dedicated hardware & Linux services)"
    echo "  2) 🐳 Docker Container (GHCR Multi-Arch — Isolated, with Docker Compose)"
    echo "  3) ❌ Exit Installer"
    echo ""
    read -p "Enter choice [1-3] (default: 1): " INSTALL_CHOICE
    INSTALL_CHOICE="${INSTALL_CHOICE:-1}"
}

# Install native packages / binaries
install_native() {
    check_privileges
    TMP_DIR=$(mktemp -d /tmp/aprx-install-XXXXXX)
    cd "$TMP_DIR"

    log_info "Downloading and installing Aprx for ${DISTRO} (${ARCH})..."

    # 1. Debian / Ubuntu / Raspberry Pi OS
    if [[ "$DISTRO" =~ ^(debian|ubuntu|raspbian|pop|linuxmint)$ ]] || [[ "$DISTRO_LIKE" =~ (debian|ubuntu) ]]; then
        if [ "$ARCH" = "x86_64" ]; then
            DEB_FILE="aprx-${VERSION_NUM}-${DISTRO}-x86_64.deb"
            # Fallback to debian deb if specific distro deb isn't present
            DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/aprx-${VERSION_NUM}-ubuntu-x86_64.deb"
            if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "raspbian" ]; then
                DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/aprx-${VERSION_NUM}-debian-x86_64.deb"
            fi
            log_info "Fetching ${DOWNLOAD_URL}..."
            curl -sSL -o package.deb "$DOWNLOAD_URL"
            $SUDO apt-get update -y
            $SUDO apt-get install -y ./package.deb || $SUDO dpkg -i package.deb
        elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "armhf" ]; then
            ZIP_FILE="aprx-${VERSION_NUM}-raspberrypi-${ARCH}.zip"
            DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${ZIP_FILE}"
            log_info "Fetching Raspberry Pi binary archive (${DOWNLOAD_URL})..."
            curl -sSL -o archive.zip "$DOWNLOAD_URL"
            command -v unzip >/dev/null 2>&1 || { $SUDO apt-get update -y && $SUDO apt-get install -y unzip; }
            unzip -q archive.zip
            $SUDO cp aprx /usr/sbin/aprx
            $SUDO cp aprx-stat /usr/bin/aprx-stat 2>/dev/null || true
            $SUDO chmod +x /usr/sbin/aprx /usr/bin/aprx-stat
            [ ! -f /etc/aprx.conf ] && $SUDO cp aprx.conf.in /etc/aprx.conf
            # Create systemd unit
            create_systemd_unit
        fi

    # 2. Fedora / RHEL / Rocky / AlmaLinux
    elif [[ "$DISTRO" =~ ^(fedora|rhel|centos|rocky|almalinux)$ ]] || [[ "$DISTRO_LIKE" =~ (fedora|rhel) ]]; then
        RPM_FILE="aprx-${VERSION_NUM}-fedora-x86_64.rpm"
        DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${RPM_FILE}"
        log_info "Fetching RPM package (${DOWNLOAD_URL})..."
        curl -sSL -o package.rpm "$DOWNLOAD_URL"
        $SUDO dnf install -y ./package.rpm || $SUDO rpm -Uvh package.rpm

    # 3. Arch Linux / Manjaro
    elif [[ "$DISTRO" =~ ^(arch|manjaro|endeavouros)$ ]] || [[ "$DISTRO_LIKE" =~ (arch) ]]; then
        PKG_FILE="aprx-${VERSION_NUM}-archlinux-x86_64.pkg.tar.zst"
        DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${PKG_FILE}"
        log_info "Fetching Arch Linux package (${DOWNLOAD_URL})..."
        curl -sSL -o package.pkg.tar.zst "$DOWNLOAD_URL"
        $SUDO pacman -U --noconfirm package.pkg.tar.zst

    # 4. FreeBSD
    elif [ "$OS_TYPE" = "freebsd" ]; then
        PKG_FILE="aprx-${VERSION_NUM}-freebsd-x86_64.pkg"
        DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${PKG_FILE}"
        log_info "Fetching FreeBSD package (${DOWNLOAD_URL})..."
        curl -sSL -o package.pkg "$DOWNLOAD_URL"
        $SUDO pkg add package.pkg 2>/dev/null || {
            # Fallback to ZIP extract
            ZIP_FILE="aprx-${VERSION_NUM}-freebsd-x86_64.zip"
            curl -sSL -o archive.zip "https://github.com/${REPO}/releases/download/${LATEST_TAG}/${ZIP_FILE}"
            unzip -q archive.zip
            $SUDO cp aprx /usr/local/sbin/aprx
            $SUDO cp aprx-stat /usr/local/bin/aprx-stat
            $SUDO chmod +x /usr/local/sbin/aprx /usr/local/bin/aprx-stat
            [ ! -f /usr/local/etc/aprx.conf ] && $SUDO cp aprx.conf.in /usr/local/etc/aprx.conf
        }

    # 5. macOS
    elif [ "$OS_TYPE" = "darwin" ]; then
        ZIP_FILE="aprx-${VERSION_NUM}-macos-arm64.zip"
        DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${ZIP_FILE}"
        log_info "Fetching macOS binary archive (${DOWNLOAD_URL})..."
        curl -sSL -o archive.zip "$DOWNLOAD_URL"
        unzip -q archive.zip
        $SUDO mkdir -p /usr/local/bin /etc
        $SUDO cp aprx /usr/local/bin/aprx
        $SUDO cp aprx-stat /usr/local/bin/aprx-stat
        $SUDO chmod +x /usr/local/bin/aprx /usr/local/bin/aprx-stat
        [ ! -f /etc/aprx.conf ] && $SUDO cp aprx.conf.in /etc/aprx.conf

    # 6. Generic Fallback
    else
        log_warn "Unrecognized distribution. Installing universal binary archive..."
        ZIP_FILE="aprx-${VERSION_NUM}-ubuntu-x86_64.zip"
        DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${ZIP_FILE}"
        curl -sSL -o archive.zip "$DOWNLOAD_URL"
        unzip -q archive.zip
        $SUDO cp aprx /usr/sbin/aprx
        $SUDO cp aprx-stat /usr/bin/aprx-stat 2>/dev/null || true
        $SUDO chmod +x /usr/sbin/aprx /usr/bin/aprx-stat
        [ ! -f /etc/aprx.conf ] && $SUDO cp aprx.conf.in /etc/aprx.conf
        create_systemd_unit
    fi

    # Ensure log directories and default config exist
    $SUDO mkdir -p /var/log/aprx
    $SUDO chmod 755 /var/log/aprx

    CONFIG_PATH="/etc/aprx.conf"
    if [ "$OS_TYPE" = "freebsd" ]; then
        CONFIG_PATH="/usr/local/etc/aprx.conf"
    fi

    if [ ! -f "$CONFIG_PATH" ]; then
        curl -sSL "https://raw.githubusercontent.com/${REPO}/${LATEST_TAG}/aprx-rxigate.conf.in" | $SUDO tee "$CONFIG_PATH" >/dev/null
    fi

    rm -rf "$TMP_DIR"
    log_success "Native Aprx binaries and configuration installed successfully!"
}

create_systemd_unit() {
    if command -v systemctl >/dev/null 2>&1; then
        if [ ! -f /etc/systemd/system/aprx.service ] && [ ! -f /lib/systemd/system/aprx.service ]; then
            log_info "Creating systemd service file (/etc/systemd/system/aprx.service)..."
            $SUDO tee /etc/systemd/system/aprx.service << 'EOF' >/dev/null
[Unit]
Description=Amateur Radio APRS Gateway & Digipeater
Documentation=man:aprx(8)
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/aprx -f /etc/aprx.conf
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
            $SUDO systemctl daemon-reload
        fi
    fi
}

# Install Docker container & compose setup
install_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log_warn "Docker is not installed on this system."
        read -p "Would you like to install Docker using the official get.docker.com script? [Y/n] " INSTALL_DOCKER_NOW
        INSTALL_DOCKER_NOW="${INSTALL_DOCKER_NOW:-Y}"
        if [[ "$INSTALL_DOCKER_NOW" =~ ^[Yy]$ ]]; then
            check_privileges
            curl -fsSL https://get.docker.com | $SUDO sh
            $SUDO usermod -aG docker "$USER" 2>/dev/null || true
            log_success "Docker installed successfully!"
        else
            log_error "Docker is required for container installation. Please install Docker and retry."
            exit 1
        fi
    fi

    DOCKER_DIR="$HOME/aprx-docker"
    mkdir -p "$DOCKER_DIR"
    cd "$DOCKER_DIR"

    CONFIG_PATH="${DOCKER_DIR}/aprx.conf"

    log_info "Setting up Aprx Docker container files in ${BOLD}${DOCKER_DIR}${NC}..."

    # Pull image from GHCR
    IMAGE_NAME="ghcr.io/${REPO,,}:latest"
    # Convert uppercase callsign in repo to lowercase for docker image
    IMAGE_NAME=$(echo "$IMAGE_NAME" | tr '[:upper:]' '[:lower:]')

    log_info "Pulling container image ${IMAGE_NAME}..."
    docker pull "$IMAGE_NAME" || true

    # Extract default configuration
    if [ ! -f "$CONFIG_PATH" ]; then
        docker run --rm --entrypoint cat "$IMAGE_NAME" /etc/aprx.conf.default > "$CONFIG_PATH" 2>/dev/null || \
        curl -sSL "https://raw.githubusercontent.com/${REPO}/${LATEST_TAG}/aprx-rxigate.conf.in" > "$CONFIG_PATH"
    fi

    # Create docker-compose.yml
    cat << EOF > "${DOCKER_DIR}/docker-compose.yml"
services:
  aprx:
    image: ${IMAGE_NAME}
    container_name: aprx
    restart: unless-stopped
    volumes:
      - ./aprx.conf:/etc/aprx.conf:ro
      - aprx-logs:/var/log/aprx
    # If connecting to a physical USB TNC:
    # devices:
    #   - /dev/ttyUSB0:/dev/ttyUSB0
    # If using host networking (e.g. Direwolf on host):
    # network_mode: host

volumes:
  aprx-logs:
EOF

    log_success "Docker Compose environment prepared at ${BOLD}${DOCKER_DIR}${NC}."
}

# Interactive configuration editing
configure_aprx() {
    echo ""
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}⚙️  Aprx Configuration Setup${NC}"
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "Configuration File: ${BOLD}${CONFIG_PATH}${NC}"
    echo ""
    echo "Key parameters to configure:"
    echo "  1. 'mycall'   - Your station callsign with SSID (e.g., 9M2PJU-10)"
    echo "  2. '<aprsis>' - APRS-IS server passcode (e.g., passcode 12345)"
    echo "  3. '<interface>' - Serial TNC port (/dev/ttyUSB0) or Direwolf TCP (127.0.0.1 8001)"
    echo "  4. '<beacon>' - Station coordinates (lat/lon) and beacon text"
    echo ""

    read -p "Would you like to open and edit the configuration file now? [Y/n] " EDIT_CONFIG
    EDIT_CONFIG="${EDIT_CONFIG:-Y}"

    if [[ "$EDIT_CONFIG" =~ ^[Yy]$ ]]; then
        EDITOR_CMD="${EDITOR:-nano}"
        if ! command -v "$EDITOR_CMD" >/dev/null 2>&1; then
            if command -v nano >/dev/null 2>&1; then
                EDITOR_CMD="nano"
            elif command -v vim >/dev/null 2>&1; then
                EDITOR_CMD="vim"
            else
                EDITOR_CMD="vi"
            fi
        fi

        if [ "$INSTALL_CHOICE" = "1" ]; then
            $SUDO "$EDITOR_CMD" "$CONFIG_PATH"
        else
            "$EDITOR_CMD" "$CONFIG_PATH"
        fi
        log_success "Configuration file saved."
    else
        log_info "Skipping configuration edit. You can edit it manually later at ${BOLD}${CONFIG_PATH}${NC}."
    fi
}

# Enable and start service
manage_service() {
    echo ""
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🚀 Service Activation${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    read -p "Do you want to enable and start the Aprx service immediately? [Y/n] " START_SERVICE
    START_SERVICE="${START_SERVICE:-Y}"

    if [[ "$START_SERVICE" =~ ^[Yy]$ ]]; then
        if [ "$INSTALL_CHOICE" = "1" ]; then
            # Native service startup
            if command -v systemctl >/dev/null 2>&1; then
                log_info "Enabling and starting systemd service (aprx)..."
                $SUDO systemctl enable --now aprx
                sleep 1
                $SUDO systemctl status aprx --no-pager || true
            elif [ "$OS_TYPE" = "freebsd" ]; then
                log_info "Enabling and starting FreeBSD rc service..."
                $SUDO sysrc aprx_enable="YES"
                $SUDO service aprx start || true
                $SUDO service aprx status || true
            elif [ "$OS_TYPE" = "darwin" ]; then
                log_info "Running Aprx in background on macOS..."
                $SUDO aprx -f /etc/aprx.conf
            else
                log_info "Starting Aprx daemon directly..."
                $SUDO aprx -f "$CONFIG_PATH"
            fi
            log_success "Aprx service started!"
        else
            # Docker service startup
            log_info "Starting Aprx Docker container with Docker Compose..."
            cd "$DOCKER_DIR"
            if command -v docker-compose >/dev/null 2>&1; then
                docker-compose up -d
                docker-compose ps
            else
                docker compose up -d
                docker compose ps
            fi
            log_success "Aprx container started successfully!"
        fi
    else
        log_info "Service start skipped."
    fi
}

print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}=================================================================${NC}"
    echo -e "${GREEN}${BOLD}             🎉 APRX Installation Complete!                     ${NC}"
    echo -e "${GREEN}${BOLD}=================================================================${NC}"
    echo ""
    echo -e "📄 Configuration: ${BOLD}${CONFIG_PATH}${NC}"
    echo ""
    echo -e "${BOLD}Helpful Management Commands:${NC}"
    if [ "$INSTALL_CHOICE" = "1" ]; then
        if command -v systemctl >/dev/null 2>&1; then
            echo "  • Check Status:    sudo systemctl status aprx"
            echo "  • View Live Logs:  sudo journalctl -u aprx -f"
            echo "  • Restart Service: sudo systemctl restart aprx"
            echo "  • Run Diagnostics: aprx-stat -S"
        elif [ "$OS_TYPE" = "freebsd" ]; then
            echo "  • Check Status:    sudo service aprx status"
            echo "  • Restart Service: sudo service aprx restart"
            echo "  • Run Diagnostics: aprx-stat -S"
        elif [ "$OS_TYPE" = "darwin" ]; then
            echo "  • Test Foreground: sudo aprx -dd -v -f /etc/aprx.conf"
            echo "  • Run Diagnostics: aprx-stat -S"
        fi
    else
        echo "  • View Logs:       cd ~/aprx-docker && docker compose logs -f"
        echo "  • Restart:         cd ~/aprx-docker && docker compose restart"
        echo "  • Run Diagnostics: docker exec -it aprx aprx-stat -S"
        echo "  • Update Image:    cd ~/aprx-docker && docker compose up -d --pull always"
    fi
    echo ""
    echo -e "⭐ GitHub Repository: ${CYAN}https://github.com/${REPO}${NC}"
    echo "================================================================="
}

# Main Execution Flow
main() {
    print_banner
    detect_system
    get_latest_version
    select_install_mode

    case "$INSTALL_CHOICE" in
        1)
            install_native
            configure_aprx
            manage_service
            print_summary
            ;;
        2)
            install_docker
            configure_aprx
            manage_service
            print_summary
            ;;
        3)
            log_info "Installation aborted by user."
            exit 0
            ;;
        *)
            log_error "Invalid selection."
            exit 1
            ;;
    esac
}

main "$@"
