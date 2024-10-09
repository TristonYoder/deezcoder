{ lib, stdenv, autoPatchelfHook, dpkgDeb }:

stdenv.mkDerivation rec {
  pname = "blackmagic-desktop-video";
  version = "14.2.1a1";

  src = null;  # No source, as we are using pre-built .deb files.

  buildInputs = [ autoPatchelfHook dpkgDeb ];

  installPhase = ''
    runHook preInstall

    # Create output directories
    mkdir -p $out/bin
    mkdir -p $out/share/applications

    # Install desktopvideo
    dpkg-deb -x /home/hitech/Blackmagic/desktopvideo_${version}_amd64.deb $out
    ln -s $out/usr/bin/desktopvideo $out/bin/desktopvideo

    # Install desktopvideo-gui
    dpkg-deb -x /home/hitech/Blackmagic/desktopvideo-gui_${version}_amd64.deb $out
    ln -s $out/usr/bin/desktopvideo-gui $out/bin/desktopvideo-gui

    # Create .desktop file for GUI application
    cat <<EOF > $out/share/applications/blackmagic-desktopvideo-gui.desktop
[Desktop Entry]
Type=Application
Name=Blackmagic Desktop Video GUI
Exec=${out}/bin/desktopvideo-gui
Icon=blackmagic
Terminal=false
Categories=Graphics;
EOF

    runHook postInstall
  '';
}
