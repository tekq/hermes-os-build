#!/usr/bin/env bash
set -euxo pipefail

PATCH_SCRIPT="${1:-$HOME/patch-glibc-spec.sh}"
OUTPUT_DIR="/output"

# Install Intel's SDE
export SDE_VERSION=10.13.1-2026-07-28
curl -fL https://downloadmirror.intel.com/924984/sde-external-${SDE_VERSION}-lin.tar.xz -o /tmp/intel-sde.tar.xz

mkdir ~/sde

tar xfv /tmp/intel-sde.tar.xz -C ~/sde

setenforce 0

dnf install -y \
    rpm-build rpmdevtools dnf-plugins-core \
    gcc gcc-c++ make \
    git python3 \
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

export PATH=$PATH:$(find ~/sde/* -name sde | sed 's|lin/sde|lin|')

sde64 -- rpmbuild -bb "$SPEC" \
    --define "_rpmdir $OUTPUT_DIR" \
    --define "debug_package %{nil}" \
    --define "_annotated_build 0"

chmod -R 755 "$OUTPUT_DIR"
