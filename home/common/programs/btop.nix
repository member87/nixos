{...}: {
  programs.btop = {
    enable = true;
    settings.color_theme = "rose-pine";
  };

  home.file.".config/btop/themes/rose-pine.theme" = {
    text = ''
      # Main background, empty for terminal default, need to be empty if you want transparent background
      theme[main_bg]="#191724"
      # Base

      # Main text color
      theme[main_fg]="#e0def4"
      # Text

      # Title color for boxes
      theme[title]="#908caa"
      # Subtle

      # Highlight color for keyboard shortcuts
      theme[hi_fg]="#e0def4"
      # Text

      # Background color of selected item in processes box
      theme[selected_bg]="#524f67"
      # HL High

      # Foreground color of selected item in processes box
      theme[selected_fg]="#f6c177"
      # Gold

      # Color of inactive/disabled text
      theme[inactive_fg]="#403d52"
      # HL Med

      # Color of text appearing on top of graphs, i.e uptime and current network graph scaling
      theme[graph_text]="#9ccfd8"
      # Foam

      # Background color of the percentage meters
      theme[meter_bg]="#9ccfd8"
      # Foam

      # Misc colors for processes box including mini cpu graphs, details memory graph and details status text
      theme[proc_misc]="#c4a7e7"
      # Iris

      # Cpu box outline color
      theme[cpu_box]="#ebbcba"
      # Rose

      # Memory/disks box outline color
      theme[mem_box]="#31748f"
      # Pine

      # Net up/down box outline color
      theme[net_box]="#c4a7e7"
      # Iris

      # Processes box outline color
      theme[proc_box]="#eb6f92"
      # Love

      # Box divider line and small boxes line color
      theme[div_line]="#6e6a86"
      # Muted

      # Temperature graph colors
      theme[temp_start]="#ebbcba"
      # Rose
      theme[temp_mid]="#f6c177"
      # Gold
      theme[temp_end]="#eb6f92"
      # Love

      # CPU graph colors
      theme[cpu_start]="#f6c177"
      # Gold
      theme[cpu_mid]="#ebbcba"
      # Rose
      theme[cpu_end]="#eb6f92"
      # Love

      # Mem/Disk free meter
      # all love
      theme[free_start]="#eb6f92"
      theme[free_mid]="#eb6f92"
      theme[free_end]="#eb6f92"

      # Mem/Disk cached meter
      # all iris
      theme[cached_start]="#c4a7e7"
      theme[cached_mid]="#c4a7e7"
      theme[cached_end]="#c4a7e7"

      # Mem/Disk available meter
      # all pine
      theme[available_start]="#31748f"
      theme[available_mid]="#31748f"
      theme[available_end]="#31748f"

      # Mem/Disk used meter
      # all rose
      theme[used_start]="#ebbcba"
      theme[used_mid]="#ebbcba"
      theme[used_end]="#ebbcba"

      # Download graph colors
      # Pine for start, foam for the rest
      theme[download_start]="#31748f"
      theme[download_mid]="#9ccfd8"
      theme[download_end]="#9ccfd8"

      # Upload graph colors
      theme[upload_start]="#ebbcba"
      # Rose for start
      theme[upload_mid]="#eb6f92"
      # Love for mid and end
      theme[upload_end]="#eb6f92"

      # Process box color gradient for threads, mem and cpu usage
      theme[process_start]="#31748f"
      # Pine
      theme[process_mid]="#9ccfd8"
      # Foam for mid and end
      theme[process_end]="#9ccfd8"

    '';
  };
}
