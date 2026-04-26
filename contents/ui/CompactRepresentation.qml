import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

MouseArea {
    id: compactRoot

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton

    onClicked: root.expanded = !root.expanded

    Kirigami.Icon {
        anchors.fill: parent
        source: tailscaleService.connected ? "network-vpn" : "network-vpn-disconnected"
        active: compactRoot.containsMouse
    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        mainText: "Tailscale"
        subText: tailscaleService.connected
            ? "Connected - " + tailscaleService.selfHostname
            : "Disconnected"
    }
}
