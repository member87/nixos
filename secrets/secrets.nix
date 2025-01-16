let
  jack = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO78M52OtE7n7W/aDwYwwek6jk4BIBz5A3Jvzu/FlhdU";

  users = [ jack ];
in
{
  "jack.age".publicKeys = users;
}
