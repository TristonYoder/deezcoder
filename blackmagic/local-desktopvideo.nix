{ stdenv, lib, autoPatchelfHook, dpkgDeb }:

stdenv.mkDerivation rec {
  pname = "blackmagic-desktop-video";
  version = "14.2.1a1";

  src = null; # No source, we are using local .deb files

  buildInputs = [ autoPatchelfHook dpkgDeb ];

  unpackPhase = ''
    # Create a directory to unpack the .deb files
    mkdir -p $out
    # Unpack the versioned desktopvideo and desktopvideo-gui .deb files
    dpkg-deb -x /trashy/Blackmagic/desktopvideo_${version}_amd64.deb $out
    dpkg-deb -x /trashy/Blackmagic/desktopvideo-gui_${version}_amd64.deb $out
  '';

  installPhase = ''
    runHook preInstall

    # Perform any necessary installation steps here
    # (Copy files to the correct locations, set permissions, etc.)

    runHook postInstall
  '';

  # Define the outputs
  meta = with lib; {
    description = "Blackmagic Desktop Video";
    homepage = "https://www.blackmagicdesign.com/";
    license = licenses.unfree; # Adjust based on the license
  };
}
