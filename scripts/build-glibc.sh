#!/usr/bin/env bash
set -euxo pipefail

PATCH_SCRIPT="${1:-scripts/patch-glibc-spec.sh}"
OUTPUT_DIR="output"

dnf install -y \
    rpm-build rpmdevtools dnf-plugins-core \
    gcc gcc-c++ make git python3 \
    qemu-user-static \
    --setopt=install_weak_deps=False

rpmdev-setuptree 2>/dev/null || mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

cd /tmp
dnf download --source glibc
SRPM=$(ls glibc-*.src.rpm | head -1)

rpm -ivh "$SRPM"

SPEC=$(find ~/rpmbuild/SPECS -name "glibc.spec" -type f | head -1)
if [[ -z "$SPEC" ]]; then
    exit 1
fi

chmod +x "$PATCH_SCRIPT"
bash "$PATCH_SCRIPT" "$SPEC"

dnf builddep -y "$SPEC"

mkdir -p "$OUTPUT_DIR"

rpmbuild -bb "$SPEC" \
    --define "_rpmdir $(pwd)/$OUTPUT_DIR" \
    --define "debug_package %{nil}" \
    --define "_annotated_build 0"
