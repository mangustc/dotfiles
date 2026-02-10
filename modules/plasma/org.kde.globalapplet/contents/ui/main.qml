import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    compactRepresentation: Item {
        width: Kirigami.Units.iconSizes.smallMedium
        height: width

        Kirigami.Icon {
            source: "diag_component"
            active: root.expanded
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.expanded = !root.expanded
        }
    }

    property var warpCheckCMD: `bash -c 'warp-cli status | grep Connected'`
    property var nethandlerCheckCMD: `bash -c 'systemctl is-active nethandler.service'`
    property var isWARPEnabled: false
    property var isNethandlerEnabled: true
    function updateStatus() {
        executable.exec(warpCheckCMD)
        executable.exec(nethandlerCheckCMD)
    }
    Timer {
        id: updateStatusTimer
        interval: 2000
        repeat: false
        onTriggered: updateStatus()
    }
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            if (source == warpCheckCMD) {
                isWARPEnabled = data["stdout"] == "" ? false : true
            }
            if (source == nethandlerCheckCMD) {
                isNethandlerEnabled = data["stdout"] == "active\n" ? true : false
            }
            disconnectSource(source)
        }
        function exec(cmd) {
            connectSource(cmd)
        }
    }
    fullRepresentation: Column {
        spacing: 5
        MenuItem {
            text: "Toggle WARP"
            icon.name: "system-run"
            onTriggered: {
                executable.exec(`bash -c '! [ "$(warp-cli status | grep Connected)" = "" ] && warp stop || warp start'`)
                updateStatusTimer.start()
            }
        }
        MenuItem {
            text: "Toggle Nethandler"
            icon.name: "system-run"
            onTriggered: {
                executable.exec(`bash -c 'systemctl is-active --quiet "nethandler.service" && systemctl stop nethandler.service || systemctl start nethandler.service'`)
                updateStatusTimer.start()
            }
        }
        MenuItem {
            text: "1920x1080@70"
            icon.name: "system-run"
            onTriggered: {
                executable.exec(`bash -c 'kscreen-doctor output.DP-3.mode.1920x1080@70'`)
            }
        }
        MenuItem {
            text: "1600x900@75"
            icon.name: "system-run"
            onTriggered: {
                executable.exec(`bash -c 'kscreen-doctor output.DP-3.mode.1600x900@75'`)
            }
        }
        MenuItem {
            text: "1920x1080@60"
            icon.name: "system-run"
            onTriggered: {
                executable.exec(`bash -c 'kscreen-doctor output.DP-3.mode.1920x1080@60'`)
            }
        }
        MenuItem {
            text: "chlayout default"
            icon.name: "system-run"
            onTriggered: {
                executable.exec(`bash -c 'chlayout default'`)
            }
        }
        MenuItem {
            text: "chlayout gaming"
            icon.name: "system-run"
            onTriggered: {
                executable.exec(`bash -c 'chlayout gaming'`)
            }
        }
        MenuItem {
            text: "WARP: " + isWARPEnabled + ", " + "Nethandler: " + isNethandlerEnabled
            icon.name: "system-run"
            onTriggered: updateStatus()
        }
    }
}

