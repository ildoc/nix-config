{ config, pkgs, lib, ... }:

{
  # Configurazione per Dolphin places
  home-manager.users.filippo = lib.mkIf config.services.desktopManager.plasma6.enable {
    # Crea il file places per Dolphin
    xdg.configFile."user-places.xbel".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE xbel>
      <xbel xmlns:kdepriv="http://www.kde.org/kdepriv" xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks">
       <bookmark href="file:///home/filippo/Projects">
        <title>Projects</title>
        <info>
         <metadata owner="http://freedesktop.org">
          <bookmark:icon name="folder-development"/>
         </metadata>
         <metadata owner="http://www.kde.org">
          <ID>projects</ID>
          <isSystemItem>false</isSystemItem>
         </metadata>
        </info>
       </bookmark>
      </xbel>
    '';
    
    # Assicura che la directory Projects esista
    systemd.user.tmpfiles.rules = [
      "d ${config.home-manager.users.filippo.home.homeDirectory}/Projects 0755 filippo users -"
    ];
  };
}
