import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

Kirigami.FormLayout {
    id: configPage

    property alias cfg_pollInterval: pollIntervalSpinBox.value
    property alias cfg_defaultTerminal: terminalCombo.currentValue

    // Can't use alias for sshUsernames since it needs JSON parsing
    property string cfg_sshUsernames

    QQC2.SpinBox {
        id: pollIntervalSpinBox
        Kirigami.FormData.label: i18n("Poll interval (seconds):")
        from: 1
        to: 60
        stepSize: 1
    }

    QQC2.ComboBox {
        id: terminalCombo
        Kirigami.FormData.label: i18n("Terminal emulator:")
        model: [
            { text: "Konsole", value: "konsole" },
            { text: "GNOME Terminal", value: "gnome-terminal" },
            { text: "Cosmic Terminal", value: "cosmic-term" },
            { text: "XTerm", value: "xterm" }
        ]
        textRole: "text"
        valueRole: "value"
        Component.onCompleted: {
            var val = cfg_defaultTerminal || "konsole";
            for (var i = 0; i < model.length; i++) {
                if (model[i].value === val) {
                    currentIndex = i;
                    break;
                }
            }
        }
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("SSH Usernames")
    }

    QQC2.Label {
        text: i18n("SSH usernames per device are configured by clicking on a device in the popup and editing the username field.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        opacity: 0.7
    }

    QQC2.Button {
        text: i18n("Clear all SSH usernames")
        icon.name: "edit-clear-all"
        onClicked: {
            cfg_sshUsernames = "{}";
        }
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("Tailscale Settings")
    }

    QQC2.Label {
        text: i18n("These settings are applied directly to Tailscale via the CLI.")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        opacity: 0.7
    }

    // Note: These aren't cfg_ properties because they control tailscale directly,
    // not plasmoid config. They use a helper DataSource to run commands.
    QQC2.Switch {
        id: acceptDnsSwitch
        Kirigami.FormData.label: i18n("Accept DNS:")
        checked: false
        onToggled: {
            configCmdSource.connectSource(
                checked ? "tailscale set --accept-dns" : "tailscale set --accept-dns=false"
            );
        }

        // Load current value
        Component.onCompleted: refreshPrefs()
    }

    QQC2.Switch {
        id: acceptRoutesSwitch
        Kirigami.FormData.label: i18n("Accept routes:")
        checked: false
        onToggled: {
            configCmdSource.connectSource(
                checked ? "tailscale set --accept-routes" : "tailscale set --accept-routes=false"
            );
        }
    }

    QQC2.Button {
        text: i18n("Open Admin Console")
        icon.name: "internet-services"
        onClicked: {
            configCmdSource.connectSource("xdg-open https://login.tailscale.com/admin/machines");
        }
    }

    // Hidden DataSource for running commands from config page
    Plasma5Support.DataSource {
        id: configCmdSource
        engine: "executable"
        connectedSources: []

        onNewData: function(source, data) {
            disconnectSource(source);
            if (source === "tailscale debug prefs") {
                try {
                    var json = JSON.parse(data.stdout);
                    acceptDnsSwitch.checked = json.CorpDNS || false;
                    acceptRoutesSwitch.checked = json.RouteAll || false;
                } catch (e) {}
            }
        }
    }

    function refreshPrefs() {
        configCmdSource.connectSource("tailscale debug prefs");
    }
}
