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

    signal triggered()

    PlasmaComponents3.ItemDelegate {
        id: delegate
        Layout.fillWidth: true
        enabled: !actionRoot.busy
        text: actionRoot.text
        icon.name: actionRoot.iconName

        onClicked: {
            actionRoot.triggered();
            if (actionRoot.closeOnTrigger) {
                actionRoot.closePopup();
            }
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
