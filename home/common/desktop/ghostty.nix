{...}: {
  home.file.".config/ghostty/config" = {
    text = ''
      theme = Rose Pine
      window-decoration = false
      window-theme = ghostty
      window-titlebar-background = 000000
      font-family = "Monaspace Neon"
      font-family-bold = "Monaspace Neon Bold"
      font-family-italic = "Monaspace Krypton Italic"
      font-family-bold-italic = "Monaspace Krypton Bold Italic"

      # Zellij (launched automatically in the shell) owns tabs/splits/pane
      # navigation now, so Ghostty's own multiplexing keybinds are freed up
      # rather than fighting zellij for the same keystrokes.
      keybind = ctrl+shift+t=unbind
      keybind = ctrl+shift+n=unbind
      keybind = ctrl+shift+w=unbind
      keybind = ctrl+tab=unbind
      keybind = ctrl+shift+tab=unbind
      keybind = ctrl+page_up=unbind
      keybind = ctrl+page_down=unbind
      keybind = ctrl+shift+arrow_left=unbind
      keybind = ctrl+shift+arrow_right=unbind
      keybind = ctrl+shift+o=unbind
      keybind = ctrl+shift+e=unbind
      keybind = super+ctrl+[=unbind
      keybind = super+ctrl+]=unbind
      keybind = ctrl+alt+arrow_up=unbind
      keybind = ctrl+alt+arrow_down=unbind
      keybind = ctrl+alt+arrow_left=unbind
      keybind = ctrl+alt+arrow_right=unbind
      keybind = super+ctrl+shift+arrow_up=unbind
      keybind = super+ctrl+shift+arrow_down=unbind
      keybind = super+ctrl+shift+arrow_left=unbind
      keybind = super+ctrl+shift+arrow_right=unbind
      keybind = ctrl+shift+enter=unbind
      keybind = alt+1=unbind
      keybind = alt+2=unbind
      keybind = alt+3=unbind
      keybind = alt+4=unbind
      keybind = alt+5=unbind
      keybind = alt+6=unbind
      keybind = alt+7=unbind
      keybind = alt+8=unbind
      keybind = alt+9=unbind
      keybind = alt+digit_1=unbind
      keybind = alt+digit_2=unbind
      keybind = alt+digit_3=unbind
      keybind = alt+digit_4=unbind
      keybind = alt+digit_5=unbind
      keybind = alt+digit_6=unbind
      keybind = alt+digit_7=unbind
      keybind = alt+digit_8=unbind
    '';
  };
}
