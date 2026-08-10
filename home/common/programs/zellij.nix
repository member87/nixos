{pkgs, ...}: {
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableZshIntegration = true;
  };

  # config.kdl is hand-written (not via programs.zellij.settings/extraConfig)
  # so the keybinds block below stays fully readable as raw KDL.
  xdg.configFile."zellij/config.kdl".text = ''
    show_startup_tips false
    simplified_ui true
    pane_frames false
    theme "catppuccin-frappe"

    keybinds {
        normal {
            // tabs
            bind "Ctrl t" { NewTab; }
            bind "Ctrl w" { CloseTab; }
            bind "Ctrl Tab" { GoToNextTab; }
            bind "Ctrl Shift Tab" { GoToPreviousTab; }
            bind "Ctrl 1" { GoToTab 1; }
            bind "Ctrl 2" { GoToTab 2; }
            bind "Ctrl 3" { GoToTab 3; }
            bind "Ctrl 4" { GoToTab 4; }
            bind "Ctrl 5" { GoToTab 5; }
            bind "Ctrl 6" { GoToTab 6; }
            bind "Ctrl 7" { GoToTab 7; }
            bind "Ctrl 8" { GoToTab 8; }
            bind "Ctrl 9" { GoToTab 9; }

            // panes / splits, macOS Terminal.app-style:
            // Ctrl+D = vertical split (side by side), Ctrl+Shift+D = horizontal split (stacked)
            bind "Ctrl d" { NewPane "Right"; }
            bind "Ctrl Shift d" { NewPane "Down"; }
            bind "Ctrl x" { CloseFocus; }

            // pane focus / resize
            bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
            bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
            bind "Alt j" "Alt Down" { MoveFocus "Down"; }
            bind "Alt k" "Alt Up" { MoveFocus "Up"; }
            bind "Ctrl Alt h" { Resize "Left"; }
            bind "Ctrl Alt l" { Resize "Right"; }
            bind "Ctrl Alt j" { Resize "Down"; }
            bind "Ctrl Alt k" { Resize "Up"; }
        }
    }
  '';

  xdg.configFile."zellij/layouts/default.kdl".text = ''
    layout {
      default_tab_template {
        pane size=1 borderless=true {
          plugin location="tab-bar"
        }
        pane
        pane size=1 borderless=true {
          plugin location="status-bar"
        }
      }
    }
  '';
}
