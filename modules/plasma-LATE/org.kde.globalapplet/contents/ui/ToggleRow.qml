import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

AppletItem {
    id: toggleRoot

    property string text: ""
    property string subtitle: ""
    property string iconName: ""
    property bool checked: false
    property bool busy: false

    signal toggled(bool nextChecked)

    PlasmaComponents3.SwitchDelegate {
        id: control
        Layout.fillWidth: true
        enabled: !toggleRoot.busy
        text: toggleRoot.subtitle.length > 0
            ? (toggleRoot.text + " (" + toggleRoot.subtitle + ")")
            : toggleRoot.text
        icon.name: toggleRoot.iconName
        checked: toggleRoot.checked

        onClicked: {
            const desired = !toggleRoot.checked;
            control.checked = Qt.binding(() => toggleRoot.checked);
            toggleRoot.toggled(desired);
        }

        PlasmaComponents3.BusyIndicator {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: (control.indicator ? control.indicator.width : Kirigami.Units.gridUnit * 2)
                + control.rightPadding
                + Kirigami.Units.smallSpacing
            implicitWidth: Kirigami.Units.iconSizes.small
            implicitHeight: Kirigami.Units.iconSizes.small
            running: toggleRoot.busy
            visible: toggleRoot.busy
        }
    }
}
