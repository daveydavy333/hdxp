VER=128
SHA=6edb06bf1448e49e428f9597a97af6a05d62146dd0b58f86eeaebcee3f5ecfaa
TAR="polkit-$VER.tar.gz"
SRC="${HDX_SRC:-/hdxp/src/util-polkit-src}"
if [ "$(id -u)" -eq 0 ]; then SU=""; else SU=doas; fi
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"

# polkitd runs as its own user, and rules.d is owned by its group, so both have to exist before the install
grep -q '^polkitd:' /etc/group  || $SU addgroup -S polkitd
grep -q '^polkitd:' /etc/passwd || $SU adduser -S -D -H -h /var/empty -s /sbin/nologin -G polkitd -g polkitd polkitd
grep -q '^wheel:' /etc/group    || echo "note: no wheel group, polkit's default admin group; add one and put your user in it for pkexec as non-root"

mkdir -p "$SRC"
cd "$SRC"
[ -f "$TAR" ] || curl -fL -o "$TAR" "https://github.com/polkit-org/polkit/archive/refs/tags/$VER.tar.gz"
echo "$SHA  $TAR" | sha256sum -c -
[ -d "polkit-$VER" ] || tar -xf "$TAR"
cd "polkit-$VER"

# no gettext tools on hdxi: the policy file has no translatable markup, so install it as it is and skip po/
cat > actions/meson.build <<'MESON'
install_data(
  'org.freedesktop.policykit.policy.in',
  rename: 'org.freedesktop.policykit.policy',
  install_dir: pk_pkgactiondir,
)
MESON
sed -i "/^subdir('po')/d" meson.build

# shadow authentication (no PAM), session tracking set to ConsoleKit only because that doesn't link libsystemd/elogind
# (there is no logind here, so polkit sees no sessions: admin authentication works, "active session" rules don't)
rm -rf build
meson setup build \
    --prefix=/usr/local --sysconfdir=/etc --localstatedir=/var \
    --libdir=lib --libexecdir=lib \
    -Dauthfw=shadow -Dsession_tracking=ConsoleKit -Dprivileged_group=wheel -Dpolkitd_user=polkitd \
    -Dintrospection=false -Dtests=false -Dexamples=false -Dman=false -Dgtk_doc=false -Dgettext=false
meson compile -C build
$SU meson install -C build --no-rebuild

# upstream installs systemd units and sysusers/tmpfiles files, none of which are used here
$SU rm -f /usr/lib/systemd/system/polkit.service /usr/lib/systemd/system/polkit-agent-helper@.service \
          /usr/lib/systemd/system/polkit-agent-helper.socket /usr/lib/sysusers.d/polkit.conf \
          /usr/lib/tmpfiles.d/polkit-tmpfiles.conf
sync

for f in /usr/local/bin/pkexec /usr/local/lib/polkit-1/polkit-agent-helper-1 /usr/local/lib/polkit-1/polkitd; do
    [ -s "$f" ] || { echo "error: $f is empty or missing"; exit 1; }
done
for f in /usr/local/bin/pkexec /usr/local/lib/polkit-1/polkit-agent-helper-1; do
    [ -u "$f" ] || echo "note: $f is not setuid root, run: chown root $f && chmod 4755 $f"
done
echo "note: polkitd needs a running D-Bus system bus (it is started by the bus through org.freedesktop.PolicyKit1.service)"
