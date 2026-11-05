import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// The running NixOS generation against main's head on GitHub, which the
// 05:00 upgrade installs (services/Updates.qml): up to date or not, what
// the latest is, and how far behind. Checked as the menu opens.
Section {
  id: root

  function short(sha: string): string {
    return sha.slice(0, 7);
  }
  function plural(n: int, word: string): string {
    return `${n} ${word}${n === 1 ? "" : "s"}`;
  }

  Component.onCompleted: Updates.refresh()

  RowLayout {
    spacing: 10

    Glyph {
      text: Icons.nixos
      color: Updates.outOfDate ? Theme.accent : Theme.fg
      font.pixelSize: 18
      Layout.preferredWidth: 26
    }

    ColumnLayout {
      spacing: 0
      Layout.fillWidth: true

      Txt {
        text: "NixOS"
        color: Theme.fgBright
        font.pixelSize: 13
        font.weight: Font.Medium
      }

      Txt {
        font.pixelSize: 12
        color: Updates.outOfDate && Updates.error === "" ? Theme.accent : Theme.fg
        text: {
          if (Updates.error !== "")
            return Updates.error;
          if (Updates.version === "")
            return "Running version unknown";
          if (!Updates.known)
            return "Checking GitHub…";
          if (Updates.outOfDate)
            return "Update available";
          if (Updates.localBuild)
            return "Local build";
          return "Up to date";
        }
      }
    }
  }

  ColumnLayout {
    spacing: 4
    Layout.leftMargin: 36

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
      value: {
        if (!Updates.outOfDate)
          return "";
        const parts = [];
        if (Updates.behindBy > 0)
          parts.push(root.plural(Updates.behindBy, "commit"));
        if (Updates.nixpkgsDays > 0)
          parts.push(`nixpkgs ${root.plural(Updates.nixpkgsDays, "day")}`);
        else if (Updates.nixpkgsBehind)
          parts.push("newer nixpkgs");
        return parts.join(" · ");
      }
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
  }
}
