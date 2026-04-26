#!/bin/bash
# Install/uninstall KDE Plasma 6 Tailscale widget

WIDGET_ID="io.github.reality2_roycdavies.kde-tailscale"
WIDGET_DIR="$(dirname "$(realpath "$0")")"

case "${1:-install}" in
    install)
        echo "Installing $WIDGET_ID..."
        # Remove old version if present
        kpackagetool6 -t Plasma/Applet -r "$WIDGET_ID" 2>/dev/null
        # Install
        kpackagetool6 -t Plasma/Applet -i "$WIDGET_DIR"
        echo "Done. Add 'Tailscale' widget to your panel via right-click > Add Widgets."
        echo "You can test it immediately with: plasmawindowed $WIDGET_ID"
        ;;
    remove|uninstall)
        echo "Removing $WIDGET_ID..."
        kpackagetool6 -t Plasma/Applet -r "$WIDGET_ID"
        echo "Done."
        ;;
    upgrade|update)
        echo "Upgrading $WIDGET_ID..."
        kpackagetool6 -t Plasma/Applet -u "$WIDGET_DIR"
        echo "Done."
        ;;
    test)
        echo "Testing $WIDGET_ID in standalone window..."
        plasmawindowed "$WIDGET_ID"
        ;;
    *)
        echo "Usage: $0 {install|remove|upgrade|test}"
        exit 1
        ;;
esac
