import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    Plasmoid.icon: tailscaleService.connected ? "network-vpn" : "network-vpn-disconnected"
    Plasmoid.title: "Tailscale"
    Plasmoid.status: tailscaleService.connected ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus

    TailscaleService {
        id: tailscaleService
    }
}
