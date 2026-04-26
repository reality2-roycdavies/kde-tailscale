import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: service

    // Status properties
    property bool connected: false
    property bool toggling: false
    property string backendState: ""
    property string selfHostname: ""
    property string selfIp: ""
    property string tailnetName: ""
    property bool exitNodeActive: false
    property var peers: []

    // Preferences
    property bool acceptDns: false
    property bool acceptRoutes: false
    property string loginName: ""

    // SSH usernames from config
    property var sshUsernames: ({})

    // Feedback
    property string errorMessage: ""
    property string copiedIp: ""

    // Poll timer
    Timer {
        id: pollTimer
        interval: (Plasmoid.configuration.pollInterval || 3) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: service.fetchStatus()
    }

    // Copied feedback timer
    Timer {
        id: copiedTimer
        interval: 2000
        onTriggered: service.copiedIp = ""
    }

    // DataSource for running commands
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(source, data) {
            disconnectSource(source);

            if (source === "tailscale status --json") {
                parseStatus(data);
            } else if (source === "tailscale debug prefs") {
                parsePrefs(data);
            } else if (source.startsWith("tailscale up")) {
                service.toggling = false;
                fetchStatus();
            } else if (source.startsWith("tailscale down")) {
                service.toggling = false;
                fetchStatus();
            }
        }
    }

    Component.onCompleted: {
        loadSshUsernames();
    }

    function loadSshUsernames() {
        try {
            sshUsernames = JSON.parse(Plasmoid.configuration.sshUsernames || "{}");
        } catch (e) {
            sshUsernames = {};
        }
    }

    function saveSshUsernames() {
        Plasmoid.configuration.sshUsernames = JSON.stringify(sshUsernames);
    }

    function setSshUsername(hostname, username) {
        var updated = Object.assign({}, sshUsernames);
        if (username && username.length > 0) {
            updated[hostname] = username;
        } else {
            delete updated[hostname];
        }
        sshUsernames = updated;
        saveSshUsernames();
    }

    function getSshUsername(hostname) {
        return sshUsernames[hostname] || "";
    }

    function fetchStatus() {
        executable.connectSource("tailscale status --json");
        executable.connectSource("tailscale debug prefs");
    }

    function parseStatus(data) {
        if (data["exit code"] !== 0) {
            service.connected = false;
            service.backendState = "Stopped";
            service.peers = [];
            return;
        }

        try {
            var json = JSON.parse(data.stdout);
            service.backendState = json.BackendState || "";
            service.connected = (service.backendState === "Running");

            // Self node
            if (json.Self) {
                service.selfHostname = extractDisplayName(json.Self.DNSName || json.Self.HostName || "");
                service.selfIp = (json.Self.TailscaleIPs && json.Self.TailscaleIPs.length > 0)
                    ? json.Self.TailscaleIPs[0] : "";
            }

            // Tailnet
            if (json.CurrentTailnet && json.CurrentTailnet.Name) {
                service.tailnetName = json.CurrentTailnet.Name;
            }

            // Peers
            var peerList = [];
            var exitActive = false;
            if (json.Peer) {
                for (var key in json.Peer) {
                    var p = json.Peer[key];
                    var peer = {
                        hostname: p.HostName || "",
                        displayName: extractDisplayName(p.DNSName || p.HostName || ""),
                        ip: (p.TailscaleIPs && p.TailscaleIPs.length > 0) ? p.TailscaleIPs[0] : "",
                        os: p.OS || "",
                        online: p.Online || false,
                        exitNode: p.ExitNode || false
                    };
                    if (peer.exitNode) exitActive = true;
                    peerList.push(peer);
                }
            }

            // Sort: online first, then alphabetical
            peerList.sort(function(a, b) {
                if (a.online !== b.online) return b.online ? 1 : -1;
                return a.displayName.localeCompare(b.displayName);
            });

            service.peers = peerList;
            service.exitNodeActive = exitActive;
            service.errorMessage = "";

        } catch (e) {
            service.errorMessage = "Failed to parse status";
        }
    }

    function parsePrefs(data) {
        if (data["exit code"] !== 0) return;

        try {
            var json = JSON.parse(data.stdout);
            service.acceptDns = json.CorpDNS || false;
            service.acceptRoutes = json.RouteAll || false;

            if (json.Config && json.Config.UserProfile) {
                service.loginName = json.Config.UserProfile.LoginName || "";
            }
        } catch (e) {
            // Prefs parsing is non-critical
        }
    }

    function extractDisplayName(dnsName) {
        if (!dnsName) return "";
        // DNSName comes as "hostname.tailnet.ts.net." - extract just the hostname
        var parts = dnsName.split(".");
        return parts[0] || dnsName;
    }

    function toggleConnection() {
        if (service.toggling) return;
        service.toggling = true;

        if (service.connected) {
            executable.connectSource("tailscale down");
        } else {
            executable.connectSource("tailscale up");
        }
    }

    function copyIp(ip) {
        executable.connectSource("wl-copy " + ip);
        service.copiedIp = ip;
        copiedTimer.restart();
    }

    function setAcceptDns(value) {
        if (value) {
            executable.connectSource("tailscale set --accept-dns");
        } else {
            executable.connectSource("tailscale set --accept-dns=false");
        }
    }

    function setAcceptRoutes(value) {
        if (value) {
            executable.connectSource("tailscale set --accept-routes");
        } else {
            executable.connectSource("tailscale set --accept-routes=false");
        }
    }

    function launchSsh(hostname, ip) {
        var user = getSshUsername(hostname);
        var target = user ? (user + "@" + ip) : ip;
        var terminal = Plasmoid.configuration.defaultTerminal || "konsole";

        var cmd;
        if (terminal === "konsole") {
            cmd = "konsole -e ssh " + target;
        } else if (terminal === "gnome-terminal") {
            cmd = "gnome-terminal -- ssh " + target;
        } else if (terminal === "cosmic-term") {
            cmd = "cosmic-term -e ssh " + target;
        } else {
            cmd = "xterm -e ssh " + target;
        }
        executable.connectSource(cmd);
    }

    function launchRdp(ip) {
        executable.connectSource("remmina -c rdp://" + ip);
    }

    function launchNoMachine(hostname, ip) {
        // Create a temporary .nxs file and open it
        var nxsContent = '<?xml version="1.0" encoding="UTF-8"?>'
            + '<!DOCTYPE NXClientSettings>'
            + '<NXClientSettings application="nxclient" version="1.3">'
            + '<group name="General">'
            + '<option key="Server host" value="' + ip + '" />'
            + '<option key="Server port" value="4000" />'
            + '<option key="Session" value="unix" />'
            + '<option key="Desktop" value="' + hostname + '" />'
            + '</group></NXClientSettings>';

        var tmpFile = "/tmp/kde-tailscale-" + hostname + ".nxs";
        var writeCmd = "echo '" + nxsContent.replace(/'/g, "'\\''") + "' > " + tmpFile;
        var launchCmd = writeCmd + " && (nxplayer --session " + tmpFile
            + " 2>/dev/null || flatpak run com.nomachine.nxplayer --session " + tmpFile + " 2>/dev/null)";
        executable.connectSource(launchCmd);
    }

    function openAdminConsole() {
        executable.connectSource("xdg-open https://login.tailscale.com/admin/machines");
    }
}
