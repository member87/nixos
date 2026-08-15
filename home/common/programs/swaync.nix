_: {
  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "application";
      control-center-margin-top = 0;
      control-center-margin-bottom = 0;
      control-center-margin-right = 0;
      control-center-margin-left = 0;
      notification-2fa-action = true;
      notification-inline-replies = false;
      notification-icon-size = 64;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 0;
      fit-to-screen = true;
      control-center-width = 500;
      control-center-height = 600;
      notification-window-width = 500;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = false;
    };

    style = ''
      * {
        all: unset;
        font-family: FiraCode Nerd Font;
        transition: 0.3s;
        font-size: 1.2rem;
      }

      .floating-notifications.background .notification-row {
        padding: 1rem;
      }

      .floating-notifications.background .notification-row .notification-background {
        border-radius: 0.5rem;
        background-color: #1d2021;
        color: #ebdbb2;
        border: 1px solid #665c54;
      }

      .floating-notifications.background
        .notification-row
        .notification-background
        .notification {
        padding: 0.5rem;
        border-radius: 0.5rem;
      }

      .floating-notifications.background
        .notification-row
        .notification-background
        .notification.critical {
        border: 1px solid #fb4934;
      }

      .floating-notifications.background
        .notification-row
        .notification-background
        .notification
        .notification-content
        .summary {
        margin: 0.5rem;
        color: #ebdbb2;
        font-weight: bold;
      }

      .floating-notifications.background
        .notification-row
        .notification-background
        .notification
        .notification-content
        .body {
        margin: 0.5rem;
        color: #a89984;
      }

      .floating-notifications.background
        .notification-row
        .notification-background
        .notification
        > *:last-child
        > * {
        min-height: 3rem;
      }

      .floating-notifications.background
        .notification-row
        .notification-background
        .notification
        > *:last-child
        > *
        .notification-action {
        border-radius: 0.5rem;
        color: #ebdbb2;
        background-color: #3c3836;
        border: 1px solid #665c54;
      }

      .floating-notifications.background
        .notification-row
        .notification-background
        .notification
        > *:last-child
        > *
        .notification-action:hover {
        background-color: #504945;
      }

      .floating-notifications.background
        .notification-row
        .notification-background
        .notification
        > *:last-child
        > *
        .notification-action:active {
        background-color: #665c54;
      }

      .floating-notifications.background
        .notification-row
        .notification-background
        .close-button {
        margin: 0.5rem;
        padding: 0.25rem;
        border-radius: 0.5rem;
        color: #ebdbb2;
        background-color: #fb4934;
      }

      .floating-notifications.background
        .notification-row
        .notification-background
        .close-button:hover {
        color: #1d2021;
      }

      .floating-notifications.background
        .notification-row
        .notification-background
        .close-button:active {
        background-color: #fabd2f;
      }

      .control-center {
        border-radius: 0.5rem;
        margin: 1rem;
        background-color: #1d2021;
        color: #ebdbb2;
        padding: 1rem;
        border: 1px solid #665c54;
      }

      .control-center .widget-title {
        color: #fabd2f;
        font-weight: bold;
      }

      .control-center .widget-title button {
        border-radius: 0.5rem;
        color: #ebdbb2;
        background-color: #3c3836;
        border: 1px solid #665c54;
        padding: 0.5rem;
      }

      .control-center .widget-title button:hover {
        background-color: #504945;
      }

      .control-center .widget-title button:active {
        background-color: #665c54;
      }

      .control-center .notification-row .notification-background {
        border-radius: 0.5rem;
        margin: 0.5rem 0;
        background-color: #3c3836;
        color: #ebdbb2;
        border: 1px solid #665c54;
      }

      .control-center .notification-row .notification-background .notification {
        padding: 0.5rem;
        border-radius: 0.5rem;
      }

      .control-center
        .notification-row
        .notification-background
        .notification.critical {
        border: 1px solid #fb4934;
      }

      .control-center
        .notification-row
        .notification-background
        .notification
        .notification-content {
        color: #ebdbb2;
      }

      .control-center
        .notification-row
        .notification-background
        .notification
        .notification-content
        .summary {
        margin: 0.5rem;
        color: #ebdbb2;
        font-weight: bold;
      }

      .control-center
        .notification-row
        .notification-background
        .notification
        .notification-content
        .body {
        margin: 0.5rem;
        color: #a89984;
      }

      .control-center
        .notification-row
        .notification-background
        .notification
        > *:last-child
        > * {
        min-height: 3rem;
      }

      .control-center
        .notification-row
        .notification-background
        .notification
        > *:last-child
        > *
        .notification-action {
        border-radius: 0.5rem;
        color: #ebdbb2;
        background-color: #3c3836;
        border: 1px solid #665c54;
      }

      .control-center
        .notification-row
        .notification-background
        .notification
        > *:last-child
        > *
        .notification-action:hover {
        background-color: #504945;
      }

      .control-center
        .notification-row
        .notification-background
        .notification
        > *:last-child
        > *
        .notification-action:active {
        background-color: #665c54;
      }

      .control-center .notification-row .notification-background .close-button {
        margin: 0.5rem;
        padding: 0.25rem;
        border-radius: 0.5rem;
        color: #ebdbb2;
        background-color: #fb4934;
      }

      .control-center .notification-row .notification-background .close-button:hover {
        color: #1d2021;
      }

      .control-center
        .notification-row
        .notification-background
        .close-button:active {
        background-color: #fabd2f;
      }

      progressbar;
      progress;
      trough {
        border-radius: 0.5rem;
      }

      .notification.critical progress {
        background-color: #fb4934;
      }

      .notification.low progress;
      .notification.normal progress {
        background-color: #83a598;
      }

      trough {
        background-color: #3c3836;
      }

      .control-center trough {
        background-color: #665c54;
      }

      .control-center-dnd {
        margin: 1rem 0;
        border-radius: 0.5rem;
      }

      .control-center-dnd slider {
        background: #504945;
        border-radius: 0.5rem;
      }

      .widget-dnd {
        color: #a89984;
      }

      .widget-dnd > switch {
        border-radius: 0.5rem;
        background: #504945;
        border: 1px solid #665c54;
      }

      .widget-dnd > switch:checked slider {
        background: #b8bb26;
      }

      .widget-dnd > switch slider {
        background: #665c54;
        border-radius: 0.5rem;
        margin: 0.25rem;
      }
    '';
  };
}
