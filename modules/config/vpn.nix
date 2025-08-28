# modules/config/vpn.nix - Configurazione VPN centralizzata (CORRETTA)
{ lib, ... }:

{
  options.myConfig.vpn = {
    connectionName = lib.mkOption {
      type = lib.types.str;
      default = "office-vpn";
      description = "Nome della connessione VPN in NetworkManager";
    };
    
    configFile = lib.mkOption {
      type = lib.types.str;
      default = "wg0.conf";
      description = "Nome del file di configurazione WireGuard";
    };
    
    interface = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "Nome dell'interfaccia WireGuard";
    };
    
    description = lib.mkOption {
      type = lib.types.str;
      default = "Office VPN Connection";
      description = "Descrizione della connessione VPN";
    };
  };
  
  # Valori di default (possono essere sovrascritti nei file di configurazione specifici)
  config.myConfig.vpn = {
    connectionName = lib.mkDefault "office-vpn";
    configFile = lib.mkDefault "wg0.conf";
    interface = lib.mkDefault "wg0";
    description = lib.mkDefault "Office VPN Connection";
  };
}
