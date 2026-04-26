import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: peerRoot

    required property var peerData
    spacing: 0

    // Main row: status indicator, name, OS
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: peerContent.implicitHeight + Kirigami.Units.smallSpacing * 2

        // Hover highlight background (separate so opacity doesn't affect children)
        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.highlightColor
            opacity: peerMouse.containsMouse ? 0.15 : 0.0
            radius: Kirigami.Units.smallSpacing
        }

        MouseArea {
            id: peerMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: detailsRow.visible = !detailsRow.visible
        }

        RowLayout {
            id: peerContent
            anchors {
                fill: parent
                leftMargin: Kirigami.Units.largeSpacing
                rightMargin: Kirigami.Units.largeSpacing
                topMargin: Kirigami.Units.smallSpacing
                bottomMargin: Kirigami.Units.smallSpacing
            }
            spacing: Kirigami.Units.smallSpacing

            // Online indicator
            Rectangle {
                width: Kirigami.Units.smallSpacing * 2
                height: width
                radius: width / 2
                color: peerRoot.peerData.online ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                Layout.alignment: Qt.AlignVCenter
            }

            // Name and OS
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents.Label {
                    text: peerRoot.peerData.displayName
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    opacity: peerRoot.peerData.online ? 1.0 : 0.5
                }

                PlasmaComponents.Label {
                    text: peerRoot.peerData.os
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.5
                    visible: peerRoot.peerData.os !== ""
                }
            }

            // IP + copy button
            PlasmaComponents.ToolButton {
                text: tailscaleService.copiedIp === peerRoot.peerData.ip ? "Copied!" : peerRoot.peerData.ip
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                flat: true
                onClicked: tailscaleService.copyIp(peerRoot.peerData.ip)
                visible: peerRoot.peerData.ip !== ""

                PlasmaComponents.ToolTip { text: i18n("Copy IP address") }
            }

            // Exit node badge
            PlasmaComponents.Label {
                text: "EXIT"
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.bold: true
                color: Kirigami.Theme.neutralTextColor
                visible: peerRoot.peerData.exitNode || false
                padding: 2

                background: Rectangle {
                    color: Kirigami.Theme.neutralTextColor
                    opacity: 0.15
                    radius: 2
                }
            }
        }
    }

    // Expandable action row (SSH, RDP, NX)
    RowLayout {
        id: detailsRow
        visible: false
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.largeSpacing * 2
        Layout.rightMargin: Kirigami.Units.largeSpacing
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        opacity: peerRoot.peerData.online ? 1.0 : 0.5

        // SSH username
        PlasmaComponents.TextField {
            id: sshUserField
            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
            placeholderText: "ssh user"
            text: tailscaleService.getSshUsername(peerRoot.peerData.hostname)
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            enabled: peerRoot.peerData.online
            onEditingFinished: {
                tailscaleService.setSshUsername(peerRoot.peerData.hostname, text);
            }
        }

        PlasmaComponents.ToolButton {
            icon.name: "utilities-terminal"
            text: "SSH"
            display: PlasmaComponents.AbstractButton.TextBesideIcon
            enabled: peerRoot.peerData.online
            onClicked: tailscaleService.launchSsh(peerRoot.peerData.hostname, peerRoot.peerData.ip)
            PlasmaComponents.ToolTip { text: i18n("Open SSH session") }
        }

        PlasmaComponents.ToolButton {
            icon.name: "krdc"
            text: "RDP"
            display: PlasmaComponents.AbstractButton.TextBesideIcon
            enabled: peerRoot.peerData.online
            onClicked: tailscaleService.launchRdp(peerRoot.peerData.ip)
            PlasmaComponents.ToolTip { text: i18n("Open Remote Desktop") }
        }

        PlasmaComponents.ToolButton {
            icon.name: "preferences-desktop-remote-desktop"
            text: "NX"
            display: PlasmaComponents.AbstractButton.TextBesideIcon
            enabled: peerRoot.peerData.online
            onClicked: tailscaleService.launchNoMachine(peerRoot.peerData.hostname, peerRoot.peerData.ip)
            PlasmaComponents.ToolTip { text: i18n("Open NoMachine session") }
        }

        Item { Layout.fillWidth: true }
    }
}
