pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var list: []
    property string active: ""
    property string sessionEngine: ""   // "lua" | "hyprlang"

    readonly property string home: Quickshell.env("HOME")
    readonly property string profiles: home + "/dotfiles/profiles"

    // активный риг: readlink profiles/active
    Process {
        command: ["readlink", root.profiles + "/active"]
        running: true
        stdout: StdioCollector { onStreamFinished: { root.active = this.text.trim(); root.refresh(); } }
    }

    // движок сессии — как hypr_provider в dotprofile
    Process {
        command: ["sh", "-c", "hyprctl systeminfo 2>/dev/null | awk -F': ' '/configProvider/{print $2}'"]
        running: true
        stdout: StdioCollector { onStreamFinished: { root.sessionEngine = this.text.trim(); root.refresh(); } }
    }

    // список ригов + движок каждого + разрешённый путь превью обоев
    Process {
        command: [root.home + "/.config/quickshell/rigswitch/scan-rigs.sh"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.parseScan(this.text) }
    }

    property var scanned: []   // [{name, engine, wallpaper, role}]
    function parseScan(t) {
        // строки вида: name<TAB>engine<TAB>путь-превью-или-пусто<TAB>role-или-пусто
        root.scanned = t.trim().split("\n").filter(l => l).map(l => {
            const p = l.split("\t");
            return { name: p[0], engine: p[1], wallpaper: p[2] || "", role: p[3] || "" };
        });
        root.refresh();
    }

    function refresh() {
        if (!root.scanned.length) return;
        root.list = root.scanned.map(r => ({
            name: r.name,
            engine: r.engine,
            active: r.name === root.active,
            relogin: root.sessionEngine !== "" && r.engine !== root.sessionEngine,
            wallpaper: r.wallpaper ? "file://" + r.wallpaper : "",
            role: r.role
        }));
    }

    // Риг по имени, для transition-анимации (identity нужна и для source, и
    // для target рига). undefined, если список ещё не загружен — вызывающий
    // код должен сам подставлять дефолт.
    function byName(name) {
        return root.list.find(r => r.name === name);
    }
}
