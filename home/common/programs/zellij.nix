_: {
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      simplified_ui = true;
      pane_frames = false;
      theme = "catppuccin-frappe";
    };
  };

  xdg.configFile."zellij/config.kdl".text = ''
    keybinds {
      normal {
        bind "Ctrl 1" { GoToTab 1; }
        bind "Ctrl 2" { GoToTab 2; }
        bind "Ctrl 3" { GoToTab 3; }
        bind "Ctrl 4" { GoToTab 4; }
        bind "Ctrl 5" { GoToTab 5; }
        bind "Ctrl 6" { GoToTab 6; }
        bind "Ctrl 7" { GoToTab 7; }
        bind "Ctrl 8" { GoToTab 8; }
        bind "Ctrl 9" { GoToTab 9; }
        bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
        bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
        bind "Alt j" "Alt Down" { MoveFocus "Down"; }
        bind "Alt k" "Alt Up" { MoveFocus "Up"; }
        bind "Ctrl t" { NewTab; }
        bind "Ctrl w" { CloseTab; }
        bind "Ctrl n" { NewPane; }
        bind "Ctrl x" { CloseFocus; }
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

  xdg.configFile."zellij/layouts/code.kdl".text = ''
    layout {
      default_tab_template {
        pane size=1 borderless=true {
          plugin location="tab-bar"
        }
        children
        pane size=1 borderless=true {
          plugin location="status-bar"
        }
      }
      tab name="editor" split_direction="vertical" {
        pane edit="." {
            focus true
        }
      }
      tab name="terminal" split_direction="vertical" {
        pane command="npm" name="dev server" {
          args "run" "dev"
        }
        pane size="40%" split_direction="horizontal" {
            pane
            pane
        }
      }
    }
  '';
}
