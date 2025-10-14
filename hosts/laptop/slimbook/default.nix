{ config, pkgs, lib, inputs, hostConfig, globalConfig, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "slimbook";

  hardware.enableRedistributableFirmware = true;

  # ============================================================================
  # DUAL BOOT FIX - Workaround per Windows che si rimette primo
  # ============================================================================
  
  # Systemd activation script che sostituisce bootmgfw.efi con systemd-boot
  # Questo forza il BIOS ad avviare systemd-boot anche quando Windows
  # si ripristina come prima opzione di boot
  #system.activationScripts.fixWindowsBootOrder = lib.stringAfter [ "usrbinenv" ] ''
  #  BOOT_DIR="/boot/EFI"
  #  SYSTEMD_BOOT="$BOOT_DIR/systemd/systemd-bootx64.efi"
  #  WINDOWS_BOOT="$BOOT_DIR/Microsoft/Boot/bootmgfw.efi"
  #  WINDOWS_BACKUP="$BOOT_DIR/Microsoft/Boot/bootmgfw.efi.original"
  #  
    # Verifica che systemd-boot esista
  #  if [ ! -f "$SYSTEMD_BOOT" ]; then
  #    echo "WARNING: systemd-boot not found at $SYSTEMD_BOOT"
  #    exit 0
  #  fi
    
    # Verifica che la directory Windows Boot esista
  #  if [ ! -d "$BOOT_DIR/Microsoft/Boot" ]; then
  #    echo "WARNING: Windows Boot directory not found"
  #    exit 0
  #  fi
    
  #  # Se non esiste il backup, crealo (prima volta)
  #  if [ ! -f "$WINDOWS_BACKUP" ]; then
  #    if [ -f "$WINDOWS_BOOT" ]; then
  #      echo "Creating backup of Windows bootloader..."
  #      ${pkgs.coreutils}/bin/cp "$WINDOWS_BOOT" "$WINDOWS_BACKUP"
  #      echo "Backup created: $WINDOWS_BACKUP"
  #    fi
  #  fi
    
    # Controlla se bootmgfw.efi è diverso da systemd-boot
  #  if [ -f "$WINDOWS_BOOT" ]; then
  #    if ! ${pkgs.diffutils}/bin/cmp -s "$SYSTEMD_BOOT" "$WINDOWS_BOOT"; then
  #      echo "Applying Windows boot order workaround..."
  #      ${pkgs.coreutils}/bin/cp "$SYSTEMD_BOOT" "$WINDOWS_BOOT"
  #      echo "✓ Windows bootloader replaced with systemd-boot"
  #    else
  #      echo "✓ Boot order workaround already applied"
  #    fi
  #  else
  #    echo "Applying Windows boot order workaround (first time)..."
  #    ${pkgs.coreutils}/bin/cp "$SYSTEMD_BOOT" "$WINDOWS_BOOT"
  #    echo "✓ Windows bootloader replaced with systemd-boot"
  #  fi
  #'';
  
  # Entry esplicita per Windows che punta al backup originale
  #boot.loader.systemd-boot.extraEntries = {
  #  "windows.conf" = ''
  #    title Windows 11
  #    efi /EFI/Microsoft/Boot/bootmgfw.efi.original
  #    sort-key z_windows
  #  '';
  #};

  # ============================================================================
  # PACCHETTI SPECIFICI HOST
  # ============================================================================
  environment.systemPackages = with pkgs; [
    jetbrains.rider
    prismlauncher

    google-chrome              # Browser per Meshtastic Web Flasher
    
    # Serial/USB tools per debugging
    picocom                    # Terminal seriale
    minicom                    # Alternative terminal seriale
    screen                     # Può essere usato per seriale
    
    # Python tools per Meshtastic (opzionale, per CLI)
    (python3.withPackages (ps: with ps; [
      meshtastic                # CLI Meshtastic
      pyserial                  # Libreria seriale Python
    ]))
  ];

  # ============================================================================
  # USB/SERIAL DEVICE SUPPORT
  # ============================================================================
  
  # Abilita i driver USB per chip seriali comuni
  boot.kernelModules = [ 
    "cp210x"      # Silicon Labs CP210x USB to UART
    "ch341"       # WCH CH340/CH341 USB to serial
    "ftdi_sio"    # FTDI USB to serial (per sicurezza)
  ];

  # Regole udev per accesso alle porte seriali senza root
  services.udev.extraRules = ''
    # Silicon Labs CP210x
    SUBSYSTEM=="usb", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666", GROUP="dialout"
    
    # WCH CH340/CH341
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666", GROUP="dialout"
    
    # Heltec boards (ESP32)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="303a", MODE="0666", GROUP="dialout"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="10c4", MODE="0666", GROUP="dialout"
    
    # Tutti i dispositivi ttyUSB* e ttyACM* accessibili al gruppo dialout
    KERNEL=="ttyUSB[0-9]*", MODE="0666", GROUP="dialout"
    KERNEL=="ttyACM[0-9]*", MODE="0666", GROUP="dialout"
  '';

  # Aggiungi l'utente al gruppo dialout per accesso seriale
  users.users.filippo.extraGroups = [ "dialout" ];
}
