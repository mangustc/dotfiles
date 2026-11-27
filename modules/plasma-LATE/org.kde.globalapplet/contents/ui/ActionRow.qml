import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

AppletItem {
    id: actionRoot

    property string text: ""
    property string iconName: "system-run"
    property bool busy: false
    property bool closeOnTrigger: false
    property bool requireConfirmation: false
    property string confirmText: "Click again to confirm"
    property int confirmTimeout: 3000
    property bool confirming: false

    signal triggered()

    onRefresh: {
        confirmTimer.stop();
        actionRoot.confirming = false;
    }

    Timer {
        id: confirmTimer
        interval: actionRoot.confirmTimeout
        repeat: false
        onTriggered: actionRoot.confirming = false
    }

    PlasmaComponents3.ItemDelegate {
        id: delegate
        Layout.fillWidth: true
        enabled: !actionRoot.busy
        text: actionRoot.confirming ? actionRoot.confirmText : actionRoot.text
        icon.name: actionRoot.confirming ? "dialog-warning" : actionRoot.iconName
        font.weight: actionRoot.confirming ? Font.DemiBold : Font.Normal
        Kirigami.Theme.inherit: !actionRoot.confirming
        Kirigami.Theme.textColor: actionRoot.confirming
            ? actionRoot.Kirigami.Theme.negativeTextColor
            : actionRoot.Kirigami.Theme.textColor

        onClicked: {
            if (actionRoot.requireConfirmation && !actionRoot.confirming) {
                actionRoot.confirming = true;
                confirmTimer.restart();
                return;
            }
            confirmTimer.stop();
            actionRoot.confirming = false;
            actionRoot.triggered();
            if (actionRoot.closeOnTrigger) {
                actionRoot.closePopup();
            }
        }

        Rectangle {
            z: -1
            anchors.fill: parent
            radius: Kirigami.Units.cornerRadius
            visible: actionRoot.confirming
            color: Qt.rgba(
                Kirigami.Theme.negativeBackgroundColor.r,
                Kirigami.Theme.negativeBackgroundColor.g,
                Kirigami.Theme.negativeBackgroundColor.b,
                delegate.down ? 0.38 : (delegate.hovered ? 0.30 : 0.22)
            )
            border.width: 1
            border.color: Kirigami.Theme.negativeTextColor
        }

        PlasmaComponents3.BusyIndicator {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: delegate.rightPadding + Kirigami.Units.smallSpacing
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
            running: actionRoot.busy
            visible: actionRoot.busy
        }
    }
}
