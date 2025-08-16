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
