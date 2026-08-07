#!/usr/bin/env bash
set -euo pipefail

SPEC="${1:?Usage: $0 <path-to-glibc.spec>}"

SDEPATH=$(find ~/sde/* -name sde | sed 's|lin/sde|lin|')
SDE64="${SDEPATH}/sde64"

if [[ ! -f "$SPEC" ]]; then
    exit 1
fi

if grep -qE -- '-march=x86-64(-v[0-9])?' "$SPEC"; then
    sed -i -E 's/-march=x86-64(-v[0-9])?/-march=znver4/g' "$SPEC"
fi

sed -i 's/%make_build install_root=%{glibc_sysroot} install/%make_build install_root=%{glibc_sysroot} install LOCALEDEF=\/usr\/bin\/localedef/g' "$SPEC"


sed -i '/^%build$/a\
export CFLAGS="${CFLAGS:+$CFLAGS }-march=znver4 -mtune=znver4"\
export CXXFLAGS="${CXXFLAGS:+$CXXFLAGS }-march=znver4 -mtune=znver4"\
export RPM_OPT_FLAGS="${RPM_OPT_FLAGS:+$RPM_OPT_FLAGS }-march=znver4 -mtune=znver4"' "$SPEC"

sed -i '/^%check$/a\
export test-wrapper="$SDE64 --"' "$SPEC"

sed -i -E "s@(\\\$RPM_BUILD_ROOT|%\{buildroot\})%\{_bindir\}/localedef@$SDE64 &@g" "$SPEC"

sed -i -E "s@(\\\$RPM_BUILD_ROOT|%\{buildroot\})%\{_sbindir\}/iconvconfig@$SDE64 &@g" "$SPEC"

for var_pattern in 'BuildFlags=' 'build_CFLAGS=' 'glibc_flags_cflags='; do
    if grep -q "$var_pattern" "$SPEC"; then
        sed -i "s|\(${var_pattern}\"[^\"]*\)|\1 -march=znver4 -mtune=znver4|" "$SPEC"
    fi
done

if grep -q 'with_doc' "$SPEC"; then
    sed -i '1i\
%global with_doc 0' "$SPEC"
fi

if grep -q 'with_benchtests' "$SPEC"; then
    sed -i '1i\
%global with_benchtests 0' "$SPEC"
fi
