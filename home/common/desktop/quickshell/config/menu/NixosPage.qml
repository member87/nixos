import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// How far the running generation is behind main (services/Updates.qml),
// what it brought into the store and from where, and how the nightly
// upgrade went (GenerationInfo.qml).
ColumnLayout {
  id: root

  readonly property string behind: {
    if (!Updates.outOfDate)
      return "";
    const parts = [];
    if (Updates.behindBy > 0)
      parts.push(plural(Updates.behindBy, "commit"));
    if (Updates.nixpkgsDays > 0)
      parts.push(`nixpkgs ${plural(Updates.nixpkgsDays, "day")}`);
    else if (Updates.nixpkgsBehind)
      parts.push("newer nixpkgs");
    return parts.join(" · ");
  }
  // the caches other than the home one take the wallpaper's cool stripes
  readonly property var cacheColors: [Theme.stripes[3], Theme.stripes[4], Theme.orange]

  function short(sha: string): string {
    return sha.slice(0, 7);
  }
  function plural(n: int, word: string): string {
    return `${n} ${word}${n === 1 ? "" : "s"}`;
  }
  function size(bytes: real): string {
    const units = ["B", "KiB", "MiB", "GiB", "TiB"];
    let i = 0;
    while (bytes >= 1024 && i < units.length - 1) {
      bytes /= 1024;
      i++;
    }
    return `${bytes < 10 && i > 0 ? bytes.toFixed(1) : Math.round(bytes)} ${units[i]}`;
  }
  function duration(ms: real): string {
    const s = Math.round(ms / 1000);
    if (s < 60)
      return `${s} s`;
    if (s < 3600)
      return `${Math.floor(s / 60)} min ${s % 60} s`;
    return `${Math.floor(s / 3600)} h ${Math.floor(s % 3600 / 60)} min`;
  }
  // "Today 10:19", "Tomorrow 05:08", "Mon 05:12", "27 Oct 18:36"
  function when(ms: real): string {
    if (!ms)
      return "";
    const d = new Date(ms);
    const now = Time.now;
    const midnight = t => new Date(t.getFullYear(), t.getMonth(), t.getDate()).getTime();
    const days = Math.round((midnight(d) - midnight(now)) / 86400000);
    const hm = Qt.formatDateTime(d, "hh:mm");
    if (days === 0)
      return `Today ${hm}`;
    if (days === -1)
      return `Yesterday ${hm}`;
    if (days === 1)
      return `Tomorrow ${hm}`;
    if (Math.abs(days) < 7)
      return `${Qt.formatDateTime(d, "ddd")} ${hm}`;
    return Qt.formatDateTime(d, "d MMM hh:mm");
  }
  function sourceColor(index: int): color {
    const s = gen.sources[index];
    if (s.key === "kept")
      return Theme.border;
    if (s.key === "built")
      return Theme.accent;
    if (s.key === "jackhumes")
      return Theme.good;
    const others = gen.sources.slice(0, index).filter(o => !["jackhumes", "built", "kept"].includes(o.key)).length;
    return cacheColors[others % cacheColors.length];
  }

  spacing: 10

  Component.onCompleted: Updates.refresh()

  GenerationInfo {
    id: gen
  }

  PageHeader {
    title: "NixOS"
  }

  // against main on GitHub
  ColumnLayout {
    spacing: 8
    Layout.fillWidth: true

    RowLayout {
      spacing: 8

      Glyph {
        text: Icons.nixos
        color: Updates.outOfDate ? Theme.accent : Theme.fg
        font.pixelSize: 18
        Layout.preferredWidth: 24
      }

      ColumnLayout {
        spacing: 0
        Layout.fillWidth: true

        Txt {
          text: Updates.status
          color: Updates.outOfDate && Updates.error === "" ? Theme.accent : Theme.fgBright
          font.pixelSize: 13
          font.weight: Font.Medium
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Txt {
          visible: text !== ""
          font.pixelSize: 12
          text: Updates.known && Updates.lastAttempt > 0 ? `Compared with main at ${Qt.formatDateTime(new Date(Updates.lastAttempt), "hh:mm")}` : ""
        }
      }
    }

    ColumnLayout {
      spacing: 4
      Layout.leftMargin: 32

      InfoRow {
        key: "Running"
        value: Updates.version
      }
      InfoRow {
        key: "Latest"
        value: Updates.latestVersion
      }
      // the repo commits, when the generation recorded its own; changes on
      // top of it show under Local
      InfoRow {
        key: "Commit"
        value: {
          if (Updates.revision === "")
            return "";
          const running = root.short(Updates.revision);
          if (!Updates.known || Updates.latestRevision === Updates.revision)
            return running;
          return `${running} → ${root.short(Updates.latestRevision)}`;
        }
      }
      InfoRow {
        key: "Behind"
        value: root.behind
        valueColor: Theme.accent
      }
      InfoRow {
        key: "Local"
        value: {
          const parts = [];
          if (Updates.dirty)
            parts.push("uncommitted changes");
          if (Updates.aheadBy > 0)
            parts.push(`${root.plural(Updates.aheadBy, "commit")} not on main`);
          if (Updates.unpushed)
            parts.push("commit not on GitHub");
          return parts.join(" · ");
        }
      }
      // the running nixpkgs snapshot's age, whatever main has
      InfoRow {
        key: "nixpkgs"
        value: {
          const day = Updates.dayOf(Updates.version);
          if (isNaN(day))
            return "";
          const now = Time.now;
          const days = Math.round((Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()) - day) / 86400000);
          const date = Qt.formatDate(new Date(day), "d MMM");
          return days <= 0 ? `${date} · today` : `${date} · ${root.plural(days, "day")} old`;
        }
      }
      InfoRow {
        key: "Kernel"
        value: gen.kernel === "" || gen.nextKernel === "" || gen.kernel === gen.nextKernel ? gen.kernel : `${gen.kernel} → ${gen.nextKernel} on reboot`
        valueColor: gen.kernel !== gen.nextKernel && gen.nextKernel !== "" ? Theme.accent : Theme.fgBright
      }
    }
  }

  Rule {
    visible: gen.number > 0
  }

  // what the generation brought, by where it came from
  ColumnLayout {
    visible: gen.number > 0
    spacing: 8
    Layout.fillWidth: true

    ColumnLayout {
      spacing: 0

      RowLayout {
        spacing: 8

        Txt {
          text: `Generation ${gen.number}`
          color: Theme.fgBright
          font.pixelSize: 13
          font.weight: Font.Medium
          Layout.fillWidth: true
        }

        Txt {
          text: root.when(gen.switchedAt)
          font.pixelSize: 12
        }
      }

      // the last nightly run's system or not; unknown without one
      Txt {
        visible: text !== ""
        font.pixelSize: 12
        text: gen.fromUpgrade ? "Installed by the nightly upgrade" : gen.runConfig !== "" ? "Switched to by hand" : ""
      }
    }

    RowLayout {
      spacing: 8

      Txt {
        font.pixelSize: 12
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        text: {
          if (gen.previous === 0)
            return "No earlier generation kept to compare with";
          if (!gen.loaded)
            return "Reading the store…";
          if (gen.newPaths === 0)
            return `The same paths as generation ${gen.previous}`;
          return `New since ${gen.previous}`;
        }
      }

      Txt {
        visible: gen.loaded && gen.newPaths > 0
        text: `${root.plural(gen.newPaths, "path")} · ${root.size(gen.newBytes)}`
        color: Theme.fgBright
        font.pixelSize: 12
      }
    }

    // the new paths' share by size, in the legend's order; an Item, so
    // the segments' widths do not feed back into the layout
    Item {
      id: bar

      readonly property real room: width - 2 * Math.max(0, gen.sources.length - 1)

      visible: gen.newPaths > 0
      clip: true
      implicitHeight: 6
      Layout.fillWidth: true

      Row {
        spacing: 2

        Repeater {
          model: gen.sources

          Rectangle {
            required property var modelData
            required property int index

            width: Math.max(3, bar.room * modelData.bytes / Math.max(1, gen.newBytes))
            height: 6
            radius: 3
            color: root.sourceColor(index)
          }
        }
      }
    }

    ColumnLayout {
      visible: gen.newPaths > 0
      spacing: 4

      Repeater {
        model: gen.sources

        ColumnLayout {
          id: source

          required property var modelData
          required property int index

          spacing: 2
          Layout.fillWidth: true

          RowLayout {
            spacing: 8

            Rectangle {
              implicitWidth: 8
              implicitHeight: 8
              radius: 4
              color: root.sourceColor(source.index)
            }

            Txt {
              text: source.modelData.label
              color: Theme.fgBright
              font.pixelSize: 12
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Txt {
              text: `${root.plural(source.modelData.paths, "path")} · ${root.size(source.modelData.bytes)}`
              font.pixelSize: 12
            }
          }

          // a big path here is a cache miss worth knowing about
          Txt {
            visible: source.modelData.key === "built" && gen.builtLargest.length > 0
            text: `Largest: ${gen.builtLargest.join(", ")}`
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.leftMargin: 16
          }
        }
      }
    }
  }

  Rule {
    visible: gen.upgrades
  }

  // system.autoUpgrade's last and next run
  ColumnLayout {
    visible: gen.upgrades
    spacing: 8
    Layout.fillWidth: true

    Txt {
      text: "Nightly upgrade"
      color: Theme.fgBright
      font.pixelSize: 12
      font.weight: Font.Medium
    }

    ColumnLayout {
      spacing: 4

      InfoRow {
        key: "Last run"
        value: gen.runState === "" ? "No run in the journal" : root.when(gen.runStart)
      }
      // its own row: beside the start it ran past the tab's width
      InfoRow {
        key: "Took"
        value: gen.runState !== "" && gen.runEnd > 0 ? root.duration(gen.runEnd - gen.runStart) : ""
      }
      InfoRow {
        key: "Result"
        valueColor: gen.runState === "failed" ? Theme.critical : Theme.fgBright
        value: {
          switch (gen.runState) {
          case "running":
            return "Running now";
          case "failed":
            return "Failed";
          case "succeeded":
            return gen.runNumber > 0 ? `Installed generation ${gen.runNumber}` : "Succeeded";
          default:
            return "";
          }
        }
      }
      Txt {
        visible: gen.runState === "failed" && gen.runError !== ""
        text: gen.runError
        font.pixelSize: 11
        wrapMode: Text.WrapAnywhere
        maximumLineCount: 4
        elide: Text.ElideRight
        Layout.fillWidth: true
        Layout.leftMargin: 84
      }
      InfoRow {
        key: "Download"
        value: {
          if (gen.fetched > 0)
            return `${root.size(gen.downloaded)} · ${root.size(gen.unpacked)} unpacked`;
          return gen.runState === "succeeded" ? "Nothing to fetch" : "";
        }
      }
      InfoRow {
        key: "Next run"
        value: root.when(gen.nextRun)
      }
    }
  }
}
