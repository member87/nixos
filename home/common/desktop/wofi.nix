{...}: {
  programs.wofi = {
    enable = true;

    style = ''
      @define-color primary #ebbcba;
      @define-color primary-fg #313244;
      @define-color background #11111b;
      @define-color backgroundalt: #1e1e2e;

      window {
        margin: 5px;
        background-color: @background;
      }

      #entry:selected {
        background-color: @primary;
        color: @primary-fg;
      }

      #text:selected {
        color: @primary-fg;
      }

      #input {
        border: 2px solid @primary;
        background-color: @background-alt;
      }
    '';
  };
}
