{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    mkRemovedOptionModule
    types
    ;

  im = config.i18n.inputMethod;
  cfg = config.i18n.inputMethod.kime;
in
{
  imports = [
    (mkRemovedOptionModule [ "i18n" "inputMethod" "kime" "config" ] ''
      Please use 'i18n.inputMethod.kime.extraConfig' instead.
    '')
  ];

  options.i18n.inputMethod.kime = {
    daemonModules = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "Xim"
          "Wayland"
          "Indicator"
        ]
      );
      default = [
        "Xim"
        "Wayland"
        "Indicator"
      ];
      example = [
        "Xim"
        "Indicator"
      ];
      description = ''
        List of enabled daemon modules
      '';
    };
    iconColor = lib.mkOption {
      type = lib.types.enum [
        "Black"
        "White"
      ];
      default = "Black";
      example = "White";
      description = ''
        Color of the indicator icon
      '';
    };
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = literalExpression ''
        engine:
          hangul:
            layout: dubeolsik
      '';
      description = ''
        kime configuration. Refer to
        <https://github.com/Riey/kime/blob/develop/docs/CONFIGURATION.md>
        for details on supported values.
      '';
    };
  };

  config = mkIf (im.enable && im.type == "kime") {
    i18n.inputMethod.package = pkgs.kime;

    home.sessionVariables = {
      GTK_IM_MODULE = "kime";
      QT_IM_MODULE = "kime";
      XMODIFIERS = "@im=kime";
    };

    xdg.configFile."kime/config.yaml".text =
      ''
        daemon:
          modules: [${lib.concatStringsSep "," cfg.kime.daemonModules}]
        indicator:
          icon_color: ${cfg.kime.iconColor}
      ''
      + cfg.extraConfig;

    systemd.user.services.kime-daemon = {
      Unit = {
        Description = "Kime input method editor";
        PartOf = [ "graphical-session.target" ];
      };
      Service.ExecStart = "${pkgs.kime}/bin/kime";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
