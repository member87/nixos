{
  pkgs,
  config,
  lib,
  ...
}: {
  systemd.user.services.battery-notification = {
    Unit = {
      Description = "Battery level notification daemon";
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.writeShellScript "battery-notify-service" ''
        STATE_FILE="/tmp/battery_notification_state"

        while true; do
            battery_dir="/sys/class/power_supply"
            battery="BAT1"

            if [ -d "$battery_dir/$battery" ]; then
                PERCENTAGE=$(cat "$battery_dir/$battery/capacity" 2>/dev/null)
                STATUS=$(cat "$battery_dir/$battery/status" 2>/dev/null)

                PREV_STATE=""
                if [ -f "$STATE_FILE" ]; then
                    PREV_STATE=$(cat "$STATE_FILE")
                fi

                if [ "$STATUS" != "Charging" ]; then
                    if [ "$PERCENTAGE" -le 5 ]; then
                        if [ "$PREV_STATE" != "critical" ]; then
                            ${pkgs.libnotify}/bin/notify-send -u critical "Battery Critical" "Battery level is ''${PERCENTAGE}%. Please charge immediately!" -i battery-caution
                            echo "critical" > "$STATE_FILE"
                        fi
                    elif [ "$PERCENTAGE" -le 10 ]; then
                        if [ "$PREV_STATE" != "low" ] && [ "$PREV_STATE" != "critical" ]; then
                            ${pkgs.libnotify}/bin/notify-send -u critical "Battery Low" "Battery level is ''${PERCENTAGE}%. Please charge soon." -i battery-low
                            echo "low" > "$STATE_FILE"
                        fi
                    else
                        # Battery is above 10%, reset state
                        if [ "$PREV_STATE" = "low" ] || [ "$PREV_STATE" = "critical" ]; then
                            echo "" > "$STATE_FILE"
                        fi
                    fi
                else
                    # Battery is charging, reset state
                    if [ "$PREV_STATE" = "low" ] || [ "$PREV_STATE" = "critical" ]; then
                        echo "" > "$STATE_FILE"
                    fi
                fi
            fi

            sleep 10
        done
      ''}";
      Restart = "always";
      RestartSec = 5;
      Environment = [
        "PATH=${lib.makeBinPath (with pkgs; [coreutils libnotify])}"
      ];
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
