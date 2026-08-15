---
name: aprx-ci-diagnostics
description: "Use when diagnosing GitHub Actions build failures, verifying workflow runs, or inspecting multi-platform release matrix logs in the aprx repository."
---

# APRX CI & Release Diagnostics

## Overview
Automate verification and failure triage for the `aprx` multi-platform build and release matrix (Debian, Ubuntu, Fedora, Arch Linux, FreeBSD, macOS ARM64, Raspberry Pi ARM64/armhf).

## When to Use
- Immediately after any `git push` to verify CI status.
- When the user asks to check CI, why a build failed, or why releases are missing.
- When modifying `.github/workflows/release.yml`, `Makefile.in`, `debian/*`, `rpm/*`, or `archlinux/*`.

## Rules & Validation Workflow

1. **Check Workflow Status**:
   ```bash
   gh run list --repo 9M2PJU/aprx --limit 1 --json databaseId,status,conclusion,headSha,event
   ```

2. **Inspect Matrix Breakdown**:
   ```bash
   gh run view <run_id> --repo 9M2PJU/aprx
   ```

3. **Extract Specific Job Failures**:
   If a matrix leg fails, fetch only the failed log:
   ```bash
   gh run view <run_id> --repo 9M2PJU/aprx --log-failed
   # Or for specific job:
   gh run view --job=<job_id> --repo 9M2PJU/aprx --log-failed
   ```

4. **Common Matrix Pitfalls & Fixes**:
   - **Version String Format**: Packaging tools (`dpkg`, `rpmbuild`, `makepkg`) strictly reject hyphens in version strings (e.g. `2.9-detatched`). Always ensure version is numeric/dot (`2.9.1`).
   - **Debian (`dh_prep` vs `dh_clean -k`)**: Modern debhelper (compat >= 10) removes `dh_clean -k` and `dh_installlogrotate`.
   - **Fedora RPM**: Spec file must not force 32-bit compilation (`-m32 -march=i386`) on 64-bit systems.
   - **Arch Linux**: `makepkg` cannot run as root. Run under isolated `builduser` with `--nodeps --noconfirm`.
   - **Raspberry Pi**: Uses QEMU (`uraimo/run-on-arch-action@v2`). Ensure standard packages (`libssl-dev`, `build-essential`) are installed.
   - **Non-blocking Matrix**: Always preserve `fail-fast: false` under `strategy:` so a failure on one distro does not cancel the rest.
