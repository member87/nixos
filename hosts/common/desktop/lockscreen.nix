{
  config,
  lib,
  ...
}: {
  # PAM stacks for the quickshell lock screen (home/common/desktop/quickshell,
  # lock.qml). Password and fingerprint run as two separate conversations:
  # a single stack with both would make the password wait for the
  # fingerprint reader to time out.
  security.pam.services.quickshell-lock.fprintAuth = false;

  security.pam.services.quickshell-lock-fprint = lib.mkIf config.services.fprintd.enable {
    fprintAuth = true;
    unixAuth = false;
  };
}
