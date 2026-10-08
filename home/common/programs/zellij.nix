{pkgs, ...}: {
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableZshIntegration = true;
  };

  # config.kdl is hand-written (not via programs.zellij.settings/extraConfig)
  # so the keybinds/theme blocks below stay fully readable as raw KDL.
  xdg.configFile."zellij/config.kdl".text = ''
    show_startup_tips false
    simplified_ui true
    pane_frames false
    theme "gruvbox-dark"

    themes {
        gruvbox-dark {
            text_unselected {
                base 235 219 178
                background 29 32 33
                emphasis_0 254 128 25
                emphasis_1 184 187 38
                emphasis_2 250 189 47
                emphasis_3 211 134 155
            }
            text_selected {
                base 235 219 178
                background 60 56 54
                emphasis_0 254 128 25
                emphasis_1 184 187 38
                emphasis_2 250 189 47
                emphasis_3 211 134 155
            }
            ribbon_selected {
                base 29 32 33
                background 250 189 47
                emphasis_0 251 73 52
                emphasis_1 254 128 25
                emphasis_2 211 134 155
                emphasis_3 131 165 152
            }
            ribbon_unselected {
                base 235 219 178
                background 60 56 54
                emphasis_0 251 73 52
                emphasis_1 168 153 132
                emphasis_2 131 165 152
                emphasis_3 211 134 155
            }
            table_title {
                base 250 189 47
                background 0
                emphasis_0 254 128 25
                emphasis_1 184 187 38
                emphasis_2 250 189 47
                emphasis_3 211 134 155
            }
            table_cell_selected {
                base 235 219 178
                background 80 73 69
                emphasis_0 254 128 25
                emphasis_1 184 187 38
                emphasis_2 250 189 47
                emphasis_3 211 134 155
            }
            table_cell_unselected {
                base 235 219 178
                background 29 32 33
                emphasis_0 254 128 25
                emphasis_1 184 187 38
                emphasis_2 250 189 47
                emphasis_3 211 134 155
            }
            list_selected {
                base 235 219 178
                background 80 73 69
                emphasis_0 254 128 25
                emphasis_1 184 187 38
                emphasis_2 250 189 47
                emphasis_3 211 134 155
            }
            list_unselected {
                base 235 219 178
                background 29 32 33
                emphasis_0 254 128 25
                emphasis_1 184 187 38
                emphasis_2 250 189 47
                emphasis_3 211 134 155
            }
            frame_selected {
                base 250 189 47
                background 0
                emphasis_0 254 128 25
                emphasis_1 184 187 38
                emphasis_2 211 134 155
                emphasis_3 0
            }
            frame_highlight {
                base 254 128 25
                background 0
                emphasis_0 211 134 155
                emphasis_1 254 128 25
                emphasis_2 254 128 25
                emphasis_3 254 128 25
            }
            exit_code_success {
                base 184 187 38
                background 0
                emphasis_0 184 187 38
                emphasis_1 60 56 54
                emphasis_2 211 134 155
                emphasis_3 131 165 152
            }
            exit_code_error {
                base 251 73 52
                background 0
                emphasis_0 250 189 47
                emphasis_1 0
                emphasis_2 0
                emphasis_3 0
            }
            multiplayer_user_colors {
                player_1 211 134 155
                player_2 131 165 152
                player_3 0
                player_4 250 189 47
                player_5 184 187 38
                player_6 0
                player_7 251 73 52
                player_8 0
                player_9 0
                player_10 0
            }
        }
    }

    // Fully self-contained keybind set (clear-defaults=true) instead of
    // layering overrides on top of zellij's tmux-style defaults.
    //
    // Zellij's stock defaults bind common Emacs/readline chars (Ctrl+n,
    // Ctrl+p, Ctrl+h, Ctrl+b, ...) globally to enter modal submodes, which
    // both fights shell/readline/vim bindings running *inside* zellij and,
    // via zellij's "mode-specific bind wins over shared_except" merge rule,
    // makes it easy to end up with the same key doing two different things
    // depending on hidden precedence. clear-defaults=true removes all of
    // that ambiguity: every binding zellij will ever act on for us is
    // listed below, so ghostty (see desktop/ghostty.nix) only ever needs to
    // stay out of the way of exactly these keys, nothing implicit.
    keybinds clear-defaults=true {
        shared_except "locked" {
            bind "Alt q" { Quit; }
        }

        locked {
            bind "Alt g" { SwitchToMode "Normal"; }
        }

        normal {
            bind "Alt g" { SwitchToMode "Locked"; }
            bind "Alt o" { SwitchToMode "Session"; }
            bind "Alt s" { SwitchToMode "Scroll"; }

            // tabs
            bind "Alt t" { NewTab; }
            bind "Alt Shift r" { SwitchToMode "RenameTab"; TabNameInput 0; }
            bind "Alt w" { CloseFocus; }
            bind "Alt Tab" { GoToNextTab; }
            bind "Alt Shift Tab" { GoToPreviousTab; }
            bind "Alt 1" { GoToTab 1; }
            bind "Alt 2" { GoToTab 2; }
            bind "Alt 3" { GoToTab 3; }
            bind "Alt 4" { GoToTab 4; }
            bind "Alt 5" { GoToTab 5; }
            bind "Alt 6" { GoToTab 6; }
            bind "Alt 7" { GoToTab 7; }
            bind "Alt 8" { GoToTab 8; }
            bind "Alt 9" { GoToTab 9; }

            // panes / splits
            // Alt+D = vertical split (side by side), Alt+Shift+D = horizontal split (stacked)
            bind "Alt d" { NewPane "Right"; }
            bind "Alt Shift d" { NewPane "Down"; }
            bind "Alt x" { CloseFocus; }

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

        renametab {
            bind "Ctrl c" { SwitchToMode "Normal"; }
            bind "Esc" { UndoRenameTab; SwitchToMode "Normal"; }
        }

        // Keyboard scrollback (mouse wheel scrolling always works regardless
        // of keybinds). Kept close to zellij's own defaults.
        scroll {
            bind "Alt s" "Esc" { SwitchToMode "Normal"; }
            bind "Alt c" { ScrollToBottom; SwitchToMode "Normal"; }
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "Alt f" "PageDown" "Right" "l" { PageScrollDown; }
            bind "Alt b" "PageUp" "Left" "h" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
            bind "e" { EditScrollback; SwitchToMode "Normal"; }
        }
        search {
            bind "Alt s" { SwitchToMode "Normal"; }
            bind "Alt c" { ScrollToBottom; SwitchToMode "Normal"; }
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "Alt f" "PageDown" "Right" "l" { PageScrollDown; }
            bind "Alt b" "PageUp" "Left" "h" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "n" { Search "down"; }
            bind "p" { Search "up"; }
            bind "c" { SearchToggleOption "CaseSensitivity"; }
            bind "w" { SearchToggleOption "Wrap"; }
            bind "o" { SearchToggleOption "WholeWord"; }
        }
        entersearch {
            bind "Alt c" "Esc" { SwitchToMode "Scroll"; }
            bind "Enter" { SwitchToMode "Search"; }
        }

        // Session mode: detach + the built-in plugin launchers.
        session {
            bind "Alt o" { SwitchToMode "Normal"; }
            bind "Alt s" { SwitchToMode "Scroll"; }
            bind "d" { Detach; }
            bind "w" {
                LaunchOrFocusPlugin "session-manager" {
                    floating true
                    move_to_focused_tab true
                };
                SwitchToMode "Normal"
            }
            bind "c" {
                LaunchOrFocusPlugin "configuration" {
                    floating true
                    move_to_focused_tab true
                };
                SwitchToMode "Normal"
            }
            bind "p" {
                LaunchOrFocusPlugin "plugin-manager" {
                    floating true
                    move_to_focused_tab true
                };
                SwitchToMode "Normal"
            }
            bind "a" {
                LaunchOrFocusPlugin "zellij:about" {
                    floating true
                    move_to_focused_tab true
                };
                SwitchToMode "Normal"
            }
            bind "l" {
                LaunchOrFocusPlugin "zellij:layout-manager" {
                    floating true
                    move_to_focused_tab true
                };
                SwitchToMode "Normal"
            }
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
