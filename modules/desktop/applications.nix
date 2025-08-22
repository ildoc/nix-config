{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Communication
    firefox
    telegram-desktop

    # Development
    vscode

    # Multimedia
    vlc

    # Spotify con supporto completo per podcast
    (spotify.override {
      ffmpeg = ffmpeg-full;
    })
    
    # Codec e librerie multimediali necessarie
    ffmpeg-full           # Codec completi per audio/video
    gst_all_1.gstreamer   # GStreamer base
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav  # Plugin libav per GStreamer

    # Games
    prismlauncher

    # KDE applications
    kdePackages.kate
    kdePackages.dolphin
    kdePackages.spectacle
    kdePackages.okular
    kdePackages.gwenview
    kdePackages.konsole

    # System utilities
    dconf-editor
    pkgs.nixfmt-rfc-style
  ];

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    khelpcenter
  ];

  # Variabili d'ambiente per GStreamer
  environment.sessionVariables = {
    GST_PLUGIN_SYSTEM_PATH_1_0 = "${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-ugly}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-libav}/lib/gstreamer-1.0";
  };
}
