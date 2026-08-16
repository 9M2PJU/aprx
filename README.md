<div align="center">

# 📡 APRX

**Advanced Amateur Radio APRS IGate & Digipeater**

[![License](https://img.shields.io/badge/license-BSD-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-v2.9.1-brightgreen.svg)](https://github.com/9M2PJU/aprx/releases)
[![Build & Release](https://github.com/9M2PJU/aprx/actions/workflows/release.yml/badge.svg)](https://github.com/9M2PJU/aprx/actions/workflows/release.yml)
[![Docker](https://img.shields.io/badge/docker-GHCR-blue.svg)](https://github.com/9M2PJU/aprx/pkgs/container/aprx)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20FreeBSD%20%7C%20macOS-lightgrey.svg)](https://github.com/9M2PJU/aprx/releases)

*A high-performance, ultra-lightweight gateway and digipeater bridging RF amateur radio networks with the global APRS-IS backbone.*

---
</div>

## 📑 Table of Contents

1. [Overview & Features](#-overview--features)
2. [Supported Platforms & Packages](#-supported-platforms--packages)
3. [🐳 Docker & Container Deployment](#-docker--container-deployment)
   - [Pulling Image from GHCR](#pulling-the-image)
   - [Running with Docker CLI](#running-with-docker-cli)
   - [Running with Docker Compose](#running-with-docker-compose)
4. [Installation Guide (By Operating System)](#-installation-guide)
   - [Debian & Ubuntu](#1-debian--ubuntu)
   - [Raspberry Pi OS (arm64 & armhf)](#2-raspberry-pi-os-32-bit--64-bit)
   - [Fedora, RHEL & Rocky Linux](#3-fedora-rhel--rocky-linux)
   - [Arch Linux & Manjaro](#4-arch-linux--manjaro)
   - [FreeBSD](#5-freebsd)
   - [macOS (Apple Silicon & Intel)](#6-macos-apple-silicon--intel)
   - [Building from Source (Universal)](#7-building-from-source-universal)
5. [Configuration Guide](#-configuration-guide)
   - [Configuration File Locations](#configuration-file-locations)
   - [Scenario A: Simple Rx-Only IGate (Serial TNC or TCP KISS)](#scenario-a-simple-rx-only-igate)
   - [Scenario B: Full 2-Way IGate with Viscous Digipeater](#scenario-b-full-2-way-igate--viscous-digipeater)
   - [Scenario C: Direwolf Software Modem over TCP](#scenario-c-direwolf-soundcard-modem-via-tcp-kiss)
   - [Scenario D: Linux Kernel AX.25 Interface](#scenario-d-linux-kernel-ax25-interface)
6. [Running & Service Management](#-running--service-management)
   - [Testing & Foreground Debug Mode](#testing--foreground-debug-mode)
   - [Linux (systemd)](#linux-systemd-service)
   - [FreeBSD (rc.d)](#freebsd-rcd-service)
   - [macOS (launchd)](#macos-launchd-service)
7. [Statistics & Telemetry (`aprx-stat`)](#-statistics--telemetry-aprx-stat)
8. [Troubleshooting & Best Practices](#-troubleshooting--best-practices)
9. [Maintainers & Credits](#-maintainers--credits)

---

## 🌟 Overview & Features

**Aprx** is a dedicated, ultra-low-footprint APRS (Automatic Packet Reporting System) gateway and digipeater daemon designed for Unix-like operating systems. It is optimized for embedded devices (Raspberry Pi, OpenWrt, thin clients) as well as mission-critical mountaintop repeater sites.

### Key Capabilities:
- **Rx-IGate (RF ➡️ APRS-IS):** Listens to RF packets via serial TNCs, soundmodems (Direwolf), or AX.25 devices and forwards valid APRS traffic to APRS-IS.
- **Tx-IGate (APRS-IS ➡️ RF):** Intelligently routes messages from the internet backbone back onto local RF frequencies only for stations recently heard locally.
- **Viscous Digipeater:** Prevents RF channel congestion by buffering packets momentarily. If an adjacent digipeater transmits the same packet first, Aprx drops duplicate transmission.
- **Multi-Interface & Cross-Band Routing:** Connect multiple TNCs, Direwolf instances, D-STAR D-PRS streams, and AX.25 ports with independent filter rules.
- **Erlang Telemetry & Channel Monitoring:** Measures real-time RF channel occupancy and reports statistics to APRS-IS and local diagnostics.

---

## 📦 Supported Platforms & Packages

Automated release packages and binaries are generated directly by GitHub Actions for every release:

| Operating System | Arch / Format | Package Type | Package / Archive Name |
| :--- | :--- | :--- | :--- |
| **Ubuntu Linux** | `x86_64` | Native DEB | `aprx-2.9.1-ubuntu-x86_64.deb` |
| **Debian Linux** | `x86_64` | Native DEB | `aprx-2.9.1-debian-x86_64.deb` |
| **Fedora / RHEL** | `x86_64` | Native RPM | `aprx-2.9.1-fedora-x86_64.rpm` |
| **Arch Linux** | `x86_64` | Native Arch Package | `aprx-2.9.1-archlinux-x86_64.pkg.tar.zst` |
| **FreeBSD** | `amd64` | Native FreeBSD PKG | `aprx-2.9.1-freebsd-x86_64.pkg` |
| **Raspberry Pi (64-bit)** | `arm64` / `aarch64` | Standalone ZIP | `aprx-2.9.1-raspberrypi-arm64.zip` |
| **Raspberry Pi (32-bit)** | `armhf` / `armv7l` | Standalone ZIP | `aprx-2.9.1-raspberrypi-armhf.zip` |
| **macOS** | `arm64` (Apple Silicon) | Standalone ZIP | `aprx-2.9.1-macos-arm64.zip` |

👉 Download pre-built assets from the **[Releases Page](https://github.com/9M2PJU/aprx/releases)**.

---

## 🐳 Docker & Container Deployment

Multi-architecture container images (`linux/amd64`, `linux/arm64`, `linux/arm/v7`) are automatically built and published to **GitHub Container Registry (GHCR)**.

### Step 1: Prepare Directory & Configuration

Create a dedicated directory for Aprx and extract the sample configuration file directly from the image:

```bash
mkdir -p ~/aprx-docker && cd ~/aprx-docker

# Extract the default configuration template from the image
docker run --rm --entrypoint cat ghcr.io/9m2pju/aprx:latest /etc/aprx.conf.default > aprx.conf

# Edit aprx.conf with your callsign, passcode, and interface settings
nano aprx.conf
```

---

### Step 2: Run with Docker CLI

#### Option A: Network / Software Modem Mode (e.g., Direwolf via TCP KISS)
```bash
docker run -d \
  --name aprx \
  --restart unless-stopped \
  -v $(pwd)/aprx.conf:/etc/aprx.conf:ro \
  -v aprx-logs:/var/log/aprx \
  ghcr.io/9m2pju/aprx:latest
```

#### Option B: USB Hardware TNC / Serial Mode (`/dev/ttyUSB0`)
When using a physical USB radio modem or TNC, pass the device into the container:
```bash
docker run -d \
  --name aprx \
  --restart unless-stopped \
  --device /dev/ttyUSB0:/dev/ttyUSB0 \
  -v $(pwd)/aprx.conf:/etc/aprx.conf:ro \
  -v aprx-logs:/var/log/aprx \
  ghcr.io/9m2pju/aprx:latest
```

---

### Step 3: Run with Docker Compose (Recommended)

Create a `docker-compose.yml` file:
```yaml
services:
  aprx:
    image: ghcr.io/9m2pju/aprx:latest
    container_name: aprx
    restart: unless-stopped
    volumes:
      - ./aprx.conf:/etc/aprx.conf:ro
      - aprx-logs:/var/log/aprx
    # If using a physical USB TNC:
    # devices:
    #   - /dev/ttyUSB0:/dev/ttyUSB0
    # If using host network (e.g., Direwolf running on host machine):
    # network_mode: host

volumes:
  aprx-logs:
```

Start the service:
```bash
# Launch container in background
docker compose up -d

# View live container logs
docker compose logs -f
```

---

### Step 4: Container Management & Diagnostics

```bash
# View live Aprx log output
docker logs -f aprx

# Run aprx-stat real-time statistics directly inside the running container
docker exec -it aprx aprx-stat -S

# View channel Erlang load metrics
docker exec -it aprx aprx-stat -x

# Reload / Restart after editing aprx.conf
docker restart aprx

# Update to latest Aprx container release
docker pull ghcr.io/9m2pju/aprx:latest
docker compose up -d --pull always
```

---

## 💻 Installation Guide

### 1. Debian & Ubuntu

#### Option A: Native `.deb` Package (Recommended)
```bash
# Download the package for your distribution
wget https://github.com/9M2PJU/aprx/releases/download/v2.9.1/aprx-2.9.1-ubuntu-x86_64.deb

# Install using apt (automatically handles dependencies)
sudo apt update
sudo apt install ./aprx-2.9.1-ubuntu-x86_64.deb
```

#### Option B: Standalone Archive
```bash
wget https://github.com/9M2PJU/aprx/releases/download/v2.9.1/aprx-2.9.1-ubuntu-x86_64.zip
unzip aprx-2.9.1-ubuntu-x86_64.zip -d aprx-dist
sudo cp aprx-dist/aprx /usr/sbin/aprx
sudo cp aprx-dist/aprx-stat /usr/bin/aprx-stat
sudo cp aprx-dist/aprx.conf.in /etc/aprx.conf
```

---

### 2. Raspberry Pi OS (32-bit & 64-bit)

Pre-compiled binary archives are provided for Raspberry Pi (Raspberry Pi OS / DietPi / Ubuntu ARM).

```bash
# For 64-bit OS (Raspberry Pi 3/4/5 / Zero 2W on 64-bit kernel):
wget https://github.com/9M2PJU/aprx/releases/download/v2.9.1/aprx-2.9.1-raspberrypi-arm64.zip
unzip aprx-2.9.1-raspberrypi-arm64.zip -d aprx-rpi

# For 32-bit OS (Raspberry Pi 1/2/Zero or 32-bit OS):
wget https://github.com/9M2PJU/aprx/releases/download/v2.9.1/aprx-2.9.1-raspberrypi-armhf.zip
unzip aprx-2.9.1-raspberrypi-armhf.zip -d aprx-rpi

# Install binaries and configuration
sudo cp aprx-rpi/aprx /usr/sbin/aprx
sudo cp aprx-rpi/aprx-stat /usr/bin/aprx-stat
sudo chmod +x /usr/sbin/aprx /usr/bin/aprx-stat
[ ! -f /etc/aprx.conf ] && sudo cp aprx-rpi/aprx.conf.in /etc/aprx.conf
```

To create the systemd service file on Raspberry Pi:
```bash
sudo tee /etc/systemd/system/aprx.service << 'EOF'
[Unit]
Description=Amateur Radio APRS Gateway & Digipeater
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/aprx -f /etc/aprx.conf
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
```

---

### 3. Fedora, RHEL & Rocky Linux

#### Option A: Native RPM Package (Recommended)
```bash
# Download and install with DNF
wget https://github.com/9M2PJU/aprx/releases/download/v2.9.1/aprx-2.9.1-fedora-x86_64.rpm
sudo dnf install ./aprx-2.9.1-fedora-x86_64.rpm
```

#### Option B: Standalone Archive
```bash
wget https://github.com/9M2PJU/aprx/releases/download/v2.9.1/aprx-2.9.1-fedora-x86_64.zip
unzip aprx-2.9.1-fedora-x86_64.zip -d aprx-fedora
sudo cp aprx-fedora/aprx /usr/sbin/aprx
sudo cp aprx-fedora/aprx-stat /usr/bin/aprx-stat
sudo cp aprx-fedora/aprx.conf.in /etc/aprx.conf
```

---

### 4. Arch Linux & Manjaro

```bash
# Download and install with Pacman
wget https://github.com/9M2PJU/aprx/releases/download/v2.9.1/aprx-2.9.1-archlinux-x86_64.pkg.tar.zst
sudo pacman -U aprx-2.9.1-archlinux-x86_64.pkg.tar.zst
```

---

### 5. FreeBSD

#### Option A: Native FreeBSD Package
```bash
wget https://github.com/9M2PJU/aprx/releases/download/v2.9.1/aprx-2.9.1-freebsd-x86_64.pkg
sudo pkg add aprx-2.9.1-freebsd-x86_64.pkg
```

#### Option B: Standalone Archive
```bash
fetch https://github.com/9M2PJU/aprx/releases/download/v2.9.1/aprx-2.9.1-freebsd-x86_64.zip
unzip aprx-2.9.1-freebsd-x86_64.zip -d aprx-freebsd
sudo cp aprx-freebsd/aprx /usr/local/sbin/aprx
sudo cp aprx-freebsd/aprx-stat /usr/local/bin/aprx-stat
sudo cp aprx-freebsd/aprx.conf.in /usr/local/etc/aprx.conf
```

---

### 6. macOS (Apple Silicon & Intel)

```bash
# Download the macOS archive
curl -LO https://github.com/9M2PJU/aprx/releases/download/v2.9.1/aprx-2.9.1-macos-arm64.zip
unzip aprx-2.9.1-macos-arm64.zip -d aprx-macos

# Copy binaries into your executable path
sudo cp aprx-macos/aprx /usr/local/bin/aprx
sudo cp aprx-macos/aprx-stat /usr/local/bin/aprx-stat
sudo chmod +x /usr/local/bin/aprx /usr/local/bin/aprx-stat

# Setup configuration
sudo mkdir -p /etc
[ ! -f /etc/aprx.conf ] && sudo cp aprx-macos/aprx.conf.in /etc/aprx.conf
```

---

### 7. Building from Source (Universal)

If you wish to compile Aprx from source for custom optimization or unlisted operating systems:

#### Prerequisites
- **Debian / Ubuntu / Raspberry Pi OS:** `sudo apt install -y build-essential libssl-dev git perl`
- **Fedora / RHEL:** `sudo dnf install -y gcc make openssl-devel git perl`
- **Arch Linux:** `sudo pacman -S --needed base-devel openssl perl git`
- **FreeBSD:** `sudo pkg install gmake perl5 git openssl`
- **macOS:** `xcode-select --install` (and `brew install openssl` if SSL is desired)

#### Build Commands
```bash
git clone https://github.com/9M2PJU/aprx.git
cd aprx
./configure --prefix=/usr --sysconfdir=/etc
make
sudo make install
```

*(On FreeBSD, use `./configure --prefix=/usr/local --sysconfdir=/usr/local/etc && gmake && sudo gmake install`)*

---

## ⚙️ Configuration Guide

### Configuration File Locations

| Operating System | Default Configuration Path |
| :--- | :--- |
| **Linux (All distributions)** | `/etc/aprx.conf` |
| **Docker Container** | `/etc/aprx.conf` |
| **macOS** | `/etc/aprx.conf` (or `/usr/local/etc/aprx.conf`) |
| **FreeBSD** | `/usr/local/etc/aprx.conf` |

---

### Scenario A: Simple Rx-Only IGate

A minimal configuration that receives APRS packets from a USB hardware TNC (or KISS modem) and forwards them to the global APRS-IS network.

```ini
# /etc/aprx.conf
mycall  9M2PJU-10

<aprsis>
    server    rotate.aprs2.net  14580
    passcode  12345
</aprsis>

<logging>
    aprxlog   /var/log/aprx/aprx.log
    rflog     /var/log/aprx/aprx-rf.log
</logging>

<interface>
    # Serial KISS TNC interface
    serial-device /dev/ttyUSB0  9600 8n1 KISS
    callsign      $mycall
    tx-ok         false
</interface>

<beacon>
    beaconmode both
    cycle-size 20m
    beacon symbol "I#" lat "0308.50N" lon "10141.50E" comment "Aprx RX-Only IGate"
</beacon>
```

---

### Scenario B: Full 2-Way IGate & Viscous Digipeater

A complete setup for a bi-directional gateway (Rx & Tx IGate) with smart viscous digipeating on VHF:

```ini
# /etc/aprx.conf
mycall  9M2PJU-1

<aprsis>
    server    rotate.aprs2.net  14580
    passcode  12345
</aprsis>

<logging>
    aprxlog   /var/log/aprx/aprx.log
    rflog     /var/log/aprx/aprx-rf.log
</logging>

<interface>
    serial-device /dev/ttyUSB0  9600 8n1 KISS
    callsign      $mycall
    tx-ok         true
    telem-to-is   true
</interface>

<beacon>
    beaconmode aprsis
    cycle-size 20m
    beacon symbol "I#" lat "0308.50N" lon "10141.50E" comment "Aprx 2-Way IGate & Digipeater"
    beacon interface $mycall symbol "I#" lat "0308.50N" lon "10141.50E" comment "Aprx 2-Way IGate & Digipeater"
</beacon>

<digipeater>
    transmitter     $mycall
    <source>
        source      $mycall
        relay-type  viscous-digipeater
        viscous-delay 500ms
        ratelimit   60 120
    </source>
    <source>
        source      APRSIS
        relay-type  txigate
        msg-path    WIDE2-1
        ratelimit   60 120
    </source>
</digipeater>
```

---

### Scenario C: Direwolf Soundcard Modem via TCP KISS

If you run [Direwolf](https://github.com/wb2osz/direwolf) as a software modem on the same or another host, Aprx connects directly over network TCP:

```ini
<interface>
    tcpdevice     127.0.0.1 8001 KISS
    callsign      $mycall
    tx-ok         true
</interface>
```

---

### Scenario D: Linux Kernel AX.25 Interface

If you have native Linux kernel AX.25 networking configured (e.g. `ax0` in `/etc/ax25/axports`):

```ini
<interface>
    ax25-device   $mycall
    tx-ok         true
</interface>
```

---

## 🚀 Running & Service Management

### Testing & Foreground Debug Mode

Before enabling automatic startup, verify your configuration and serial connection in foreground debug mode:

```bash
# -d: debug output (use -dd or -ddd for higher verbosity)
# -v: verbose output
# -f: specify configuration file
aprx -dd -v -f /etc/aprx.conf
```

---

### Linux (systemd Service)

On Debian, Ubuntu, Raspberry Pi OS, Fedora, Arch Linux, and RHEL:

```bash
# Enable Aprx to start on boot and launch immediately
sudo systemctl enable --now aprx

# Check service status
sudo systemctl status aprx

# Restart after editing configuration
sudo systemctl restart aprx

# View live runtime logs
sudo journalctl -u aprx -f
```

---

### FreeBSD (rc.d Service)

1. Enable the service in `/etc/rc.conf`:
   ```bash
   sudo sysrc aprx_enable="YES"
   ```
2. Start and control the daemon:
   ```bash
   sudo service aprx start
   sudo service aprx status
   sudo service aprx restart
   ```

---

### macOS (launchd Service)

To run Aprx continuously in the background on macOS:

1. Create a LaunchDaemon descriptor at `/Library/LaunchDaemons/net.aprx.plist`:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>net.aprx</string>
       <key>ProgramArguments</key>
       <array>
           <string>/usr/local/bin/aprx</string>
           <string>-f</string>
           <string>/etc/aprx.conf</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>KeepAlive</key>
       <true/>
       <key>StandardErrorPath</key>
       <string>/var/log/aprx-err.log</string>
       <key>StandardOutPath</key>
       <string>/var/log/aprx-out.log</string>
   </dict>
   </plist>
   ```

2. Load and start the daemon:
   ```bash
   sudo launchctl load -w /Library/LaunchDaemons/net.aprx.plist
   ```

---

## 📊 Statistics & Telemetry (`aprx-stat`)

Aprx includes the `aprx-stat` diagnostic utility to monitor runtime performance, interface traffic, and channel loading:

```bash
# Show instantaneous summary of all interfaces and connections
aprx-stat -S

# Show interface packet and byte counters
aprx-stat -t

# Show Erlang RF channel utilization and load metrics
aprx-stat -x

# Continuous monitoring with 5-second interval
aprx-stat -S -i 5
```

---

## 🔍 Troubleshooting & Best Practices

| Problem | Cause | Solution |
| :--- | :--- | :--- |
| `Permission denied` on serial port | User / daemon lacks access to `/dev/ttyUSB0` | Add user to group: `sudo usermod -a -G dialout $USER` (Linux) or `uucp` (Arch/FreeBSD). |
| `APRS-IS login failed` | Wrong passcode or formatting | Ensure valid APRS passcode matches your `mycall` station callsign. |
| Missing `/var/log/aprx` directory | Log directory not pre-created | Run `sudo mkdir -p /var/log/aprx && sudo chmod 755 /var/log/aprx`. |
| Serial port path differences across OSes | Different kernel device naming | **Linux:** `/dev/ttyUSB0` or `/dev/ttyACM0`<br>**macOS:** `/dev/cu.usbserial-*` or `/dev/cu.usbmodem*`<br>**FreeBSD:** `/dev/cuaU0` |
| Duplicate packet storms | Multiple digipeaters without hold-off | Ensure `relay-type viscous-digipeater` and `viscous-delay 500ms` are enabled in `<digipeater>`. |

---

## 👥 Maintainers & Credits

- 🧑‍💻 **Matti Aarnio (OH2MQK)** — Original author & architect (2007–2014)
- 🧑‍💻 **Kenneth W. Finnegan (W6KWF)** — Longtime upstream maintainer (2014–Present)
- 🧑‍💻 **9M2PJU** — Modern CI/CD automation, multi-arch packaging & cross-platform releases

<div align="center">
  <br>
  <a href="http://thelifeofkenneth.com/aprx">🌍 Project Homepage</a>
  <span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
  <a href="https://github.com/9M2PJU/aprx">💻 GitHub Repository</a>
  <span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
  <a href="http://groups.google.com/group/aprx-software">💬 Google Group</a>
</div>
