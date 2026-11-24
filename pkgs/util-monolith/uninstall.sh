# the sample config and the portal config belong to this port; the user's own config is in ~/.config
rm -f /usr/local/share/monolith/config.toml
rm -f /usr/local/share/xdg-desktop-portal/monolith-portals.conf
# drop the folders only if empty: /usr/local/share/monolith/sounds is the user's and keeps its folder
rmdir /usr/local/share/monolith 2>/dev/null || true
rmdir /usr/local/share/xdg-desktop-portal 2>/dev/null || true
true
