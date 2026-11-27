import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Plasma5Support.DataSource {
    id: runner
    engine: "executable"
    connectedSources: []

    property var pendingCallbacks: ({})

    onNewData: (source, data) => {
        const callbacks = runner.pendingCallbacks[source] || [];
        const next = Object.assign({}, runner.pendingCallbacks);
        delete next[source];
        runner.pendingCallbacks = next;
        runner.disconnectSource(source);

        const exitCode = data["exit code"] !== undefined ? Number(data["exit code"]) : 0;
        const stdout = data["stdout"] !== undefined ? String(data["stdout"]) : "";
        const stderr = data["stderr"] !== undefined ? String(data["stderr"]) : "";

        for (let i = 0; i < callbacks.length; ++i) {
            if (typeof callbacks[i] === "function") {
                callbacks[i](exitCode, stdout, stderr);
            }
        }
    }

    function exec(cmd, callback) {
        const existing = runner.pendingCallbacks[cmd];
        const next = Object.assign({}, runner.pendingCallbacks);
        if (existing) {
            next[cmd] = existing.concat(callback ? [callback] : []);
            runner.pendingCallbacks = next;
            return;
        }
        next[cmd] = callback ? [callback] : [];
        runner.pendingCallbacks = next;
        runner.connectSource(cmd);
    }
}
