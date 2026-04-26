import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

PlasmaExtras.Representation {
    id: fullRoot

    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 20
    Layout.preferredWidth: Kirigami.Units.gridUnit * 24
    Layout.preferredHeight: Kirigami.Units.gridUnit * 28

    header: PlasmaExtras.PlasmoidHeading {
        RowLayout {
            anchors.fill: parent

            Kirigami.Heading {
                text: "Tailscale"
                level: 2
                Layout.fillWidth: true
            }

            PlasmaComponents.ToolButton {
                icon.name: "configure"
                onClicked: Plasmoid.internalAction("configure").trigger()
                PlasmaComponents.ToolTip { text: i18n("Settings") }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // Status section
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true

                Kirigami.Icon {
                    source: tailscaleService.connected ? "network-vpn" : "network-vpn-disconnected"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents.Label {
                        text: {
                            if (tailscaleService.toggling) {
                                return tailscaleService.connected ? "Disconnecting..." : "Connecting...";
                            }
                            return tailscaleService.connected ? "Connected" : "Disconnected";
                        }
                        font.bold: true
                    }

                    PlasmaComponents.Label {
                        text: tailscaleService.selfHostname
                        visible: tailscaleService.connected && tailscaleService.selfHostname !== ""
                        opacity: 0.7
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }
            }

            // Connection details
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                visible: tailscaleService.connected
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: 2

                PlasmaComponents.Label {
                    text: "IP:"
                    opacity: 0.7
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
                PlasmaComponents.Label {
                    text: tailscaleService.selfIp
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }

                PlasmaComponents.Label {
                    text: "Network:"
                    opacity: 0.7
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
                PlasmaComponents.Label {
                    text: tailscaleService.tailnetName
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }

                PlasmaComponents.Label {
                    text: "Exit Node:"
                    opacity: 0.7
                    visible: tailscaleService.exitNodeActive
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
                PlasmaComponents.Label {
                    text: "Active"
                    visible: tailscaleService.exitNodeActive
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }

            // Error message
            PlasmaComponents.Label {
                text: tailscaleService.errorMessage
                visible: tailscaleService.errorMessage !== ""
                color: Kirigami.Theme.negativeTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        // Connect/Disconnect button
        PlasmaComponents.Button {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            text: {
                if (tailscaleService.toggling) {
                    return tailscaleService.connected ? "Disconnecting..." : "Connecting...";
                }
                return tailscaleService.connected ? "Disconnect" : "Connect";
            }
            icon.name: tailscaleService.connected ? "network-disconnect" : "network-connect"
            enabled: !tailscaleService.toggling
            onClicked: tailscaleService.toggleConnection()
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            visible: tailscaleService.connected
        }

        // Devices header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            visible: tailscaleService.connected

            Kirigami.Heading {
                text: {
                    var online = 0;
                    for (var i = 0; i < tailscaleService.peers.length; i++) {
                        if (tailscaleService.peers[i].online) online++;
                    }
                    return "Devices (" + online + "/" + tailscaleService.peers.length + " online)";
                }
                level: 4
                Layout.fillWidth: true
            }
        }

        // Peer list
        PlasmaComponents.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: tailscaleService.connected

            ListView {
                id: peerList
                model: tailscaleService.peers
                clip: true
                spacing: 1

                delegate: PeerDelegate {
                    width: peerList.width
                    peerData: modelData
                }
            }
        }

        // Placeholder when no peers
        Kirigami.PlaceholderMessage {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: tailscaleService.connected && tailscaleService.peers.length === 0
            text: "No devices found"
            icon.name: "network-vpn"
        }

        // Placeholder when disconnected
        Kirigami.PlaceholderMessage {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !tailscaleService.connected
            text: "Not connected to Tailscale"
            icon.name: "network-vpn-disconnected"
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        // Bottom actions
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing

            PlasmaComponents.Button {
                text: "Admin Console"
                icon.name: "internet-services"
                flat: true
                onClicked: tailscaleService.openAdminConsole()
            }

            Item { Layout.fillWidth: true }

            PlasmaComponents.Label {
                text: tailscaleService.loginName
                opacity: 0.5
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                visible: tailscaleService.loginName !== ""
            }
        }
    }
}
