{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.kbfs;

in
{
  options = {
    services.kbfs = {
      enable = lib.mkEnableOption "Keybase File System";

      package = lib.mkPackageOption pkgs "kbfs" { };

      mountPoint = lib.mkOption {
        type = lib.types.str;
        default = "keybase";
        description = ''
          Mount point for the Keybase filesystem, relative to
          {env}`HOME`.
        '';
      };

      extraFlags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "-label kbfs"
          "-mount-type normal"
        ];
        description = ''
          Additional flags to pass to the Keybase filesystem on launch.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.kbfs" pkgs lib.platforms.linux)
    ];

    systemd.user.services.kbfs = {
      Unit = {
        Description = "Keybase File System";
        Requires = [ "keybase.service" ];
        After = [ "keybase.service" ];
      };

      Service =
        let
          mountPoint = ''"%h/${cfg.mountPoint}"'';
        in
        {
          Environment = [
            "PATH=/run/wrappers/bin"
            "KEYBASE_SYSTEMD=1"
          ];
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}";
          ExecStart = "${lib.getExe' cfg.package "kbfsfuse"} ${toString cfg.extraFlags} ${mountPoint}";
          ExecStopPost = "/run/wrappers/bin/fusermount -u ${mountPoint}";
          Restart = "on-failure";
        };

      Install.WantedBy = [ "default.target" ];
    };

    home.packages = [ cfg.package ];
    services.keybase.enable = true;
  };
}
