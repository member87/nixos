# Ports that only the home network may reach. The casting and file-sharing services open
# these, and thor also joins untrusted networks, where networking.firewall.allowed* would
# expose them to everyone on the link. IPv4 only: nothing here is opened over IPv6.
{
  config,
  lib,
  ...
}: let
  cfg = config.networking.firewall.lan;
  inherit (lib) concatMapStrings mkOption types;

  accept = subnet: proto: dport: ''
    iptables -A nixos-fw -p ${proto} -s ${subnet} --dport ${dport} -j nixos-fw-accept
  '';

  rules = concatMapStrings (subnet:
    concatMapStrings (port: accept subnet "tcp" (toString port)) cfg.allowedTCPPorts
    + concatMapStrings (port: accept subnet "udp" (toString port)) cfg.allowedUDPPorts
    + concatMapStrings (range: accept subnet "udp" "${toString range.from}:${toString range.to}") cfg.allowedUDPPortRanges)
  cfg.subnets;
in {
  options.networking.firewall.lan = {
    subnets = mkOption {
      type = types.listOf types.str;
      default = [
        "192.168.1.0/24"
        "10.0.0.0/24"
      ];
      description = "IPv4 source subnets allowed to reach the ports below.";
    };

    allowedTCPPorts = mkOption {
      type = types.listOf types.port;
      default = [];
      description = "TCP ports open to the subnets above.";
    };

    allowedUDPPorts = mkOption {
      type = types.listOf types.port;
      default = [];
      description = "UDP ports open to the subnets above.";
    };

    allowedUDPPortRanges = mkOption {
      type = types.listOf (types.submodule {
        options = {
          from = mkOption {type = types.port;};
          to = mkOption {type = types.port;};
        };
      });
      default = [];
      description = "UDP port ranges open to the subnets above.";
    };
  };

  # The firewall rebuilds nixos-fw from scratch on every start and reload, so these need
  # no matching stop commands.
  config.networking.firewall.extraCommands = rules;
}
