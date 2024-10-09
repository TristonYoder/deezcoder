{ stdenv
, lib
, cacert
, curl
, runCommandLocal
, autoPatchelfHook
, libcxx
, libGL
, gcc7
, gtk3
, libsForQt5
, dbus
, xorg
, glib
, makeWrapper
, copyDesktopItems
, makeDesktopItem
}:

stdenv.mkDerivation rec {
  pname = "blackmagic-desktop-video";
  version = "12.9a3";
  buildInputs = [
    autoPatchelfHook
    libcxx
    libGL
    gcc7.cc.lib
    gtk3
    libsForQt5.qtbase
    dbus
    xorg.libX11
    xorg.libXext
    glib
  ];
  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
    libsForQt5.wrapQtAppsHook
  ];

  # The download function remains the same
  src = runCommandLocal "${pname}-${lib.versions.majorMinor version}-src.tar.gz"
    rec {
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = "sha256-H7AHD6u8KsJoL+ug3QCqxuPfMP4A0nHtIyKx5IaQkdQ=";
      impureEnvVars = lib.fetchers.proxyImpureEnvVars;
      nativeBuildInputs = [ curl ];
      # ENV VARS
      SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
      DOWNLOADID = "495ebc707969447598c2f1cf0ff8d7d8";
      REFERID = "6e65a87d97bd49e1915c57f8df255f5c";
      SITEURL = "https://www.blackmagicdesign.com/api/register/us/download/${DOWNLOADID}";
      USERAGENT = builtins.concatStringsSep " " [
        "User-Agent: Mozilla/5.0 (X11; Linux ${stdenv.hostPlatform.linuxArch})"
        "AppleWebKit/537.36 (KHTML, like Gecko)"
        "Chrome/77.0.3865.75"
        "Safari/537.36"
      ];
      REQJSON = builtins.toJSON {
        "country" = "nl";
        "downloadOnly" = true;
        "platform" = "Linux";
        "policy" = true;
      };
    } ''
    RESOLVEURL=$(curl \
      -s \
      -H "$USERAGENT" \
      -H 'Content-Type: application/json;charset=UTF-8' \
      -H "Referer: https://www.blackmagicdesign.com/support/download/$REFERID/Linux" \
      --data-ascii "$REQJSON" \
      --compressed \
      "$SITEURL")
    curl \
      --retry 3 --retry-delay 3 \
      --compressed \
      "$RESOLVEURL" \
      > $out
  '';
  postUnpack = let
    arch = stdenv.hostPlatform.uname.processor;
  in ''
    tar xf Blackmagic_Desktop_Video_Linux_${lib.versions.majorMinor version}/other/${arch}/desktopvideo-${version}-${arch}.tar.gz
    unpacked=$NIX_BUILD_TOP/desktopvideo-${version}-${stdenv.hostPlatform.uname.processor}
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,share/doc,lib,lib/systemd/system,share/applications,share/icons/hicolor/256x256/apps}
    
    # Copy libraries
    if [ -d $unpacked/usr/lib ]; then
      cp -r $unpacked/usr/lib/* $out/lib/
    else
      echo "Warning: usr/lib directory not found"
    fi
    
    # Copy documentation
    if [ -d $unpacked/usr/share/doc/desktopvideo ]; then
      cp -r $unpacked/usr/share/doc/desktopvideo $out/share/doc/
    else
      echo "Warning: Documentation directory not found"
    fi
    
    # Copy and modify systemd service
    if [ -f $unpacked/usr/lib/systemd/system/DesktopVideoHelper.service ]; then
      cp $unpacked/usr/lib/systemd/system/DesktopVideoHelper.service $out/lib/systemd/system/
      substituteInPlace $out/lib/systemd/system/DesktopVideoHelper.service \
        --replace "/usr/lib/blackmagic/DesktopVideo/DesktopVideoHelper" "$out/bin/DesktopVideoHelper"
    else
      echo "Warning: DesktopVideoHelper.service not found"
    fi
    
    # Copy DesktopVideoHelper
    if [ -f $unpacked/usr/lib/blackmagic/DesktopVideo/DesktopVideoHelper ]; then
      cp $unpacked/usr/lib/blackmagic/DesktopVideo/DesktopVideoHelper $out/bin/
    else
      echo "Warning: DesktopVideoHelper not found"
    fi
    
    # Copy GUI applications
    for app in BlackmagicDesktopVideoSetup BlackmagicFirmwareUpdater; do
      if [ -f $unpacked/usr/bin/$app ]; then
        cp $unpacked/usr/bin/$app $out/bin/
      else
        echo "Warning: $app not found"
      fi
    done
    
    # Copy icon if it exists
    if [ -f $unpacked/usr/share/icons/hicolor/256x256/apps/BlackmagicDesktopVideoSetup.png ]; then
      cp $unpacked/usr/share/icons/hicolor/256x256/apps/BlackmagicDesktopVideoSetup.png $out/share/icons/hicolor/256x256/apps/
    else
      echo "Warning: BlackmagicDesktopVideoSetup icon not found"
    fi
    
    runHook postInstall
  '';
  
  # need to tell the DesktopVideoHelper and GUI applications where to find their libraries
  appendRunpaths = [ "${placeholder "out"}/lib" ];

  qtWrapperArgs = [
    "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc libcxx libGL libsForQt5.qtbase ]}"
    "--prefix XDG_DATA_DIRS : ${placeholder "out"}/share"
  ];
  
  desktopItems = [
    (makeDesktopItem {
      name = "BlackmagicDesktopVideoSetup";
      exec = "BlackmagicDesktopVideoSetup";
      icon = "BlackmagicDesktopVideoSetup";
      desktopName = "Blackmagic Desktop Video Setup";
      genericName = "Blackmagic Desktop Video Setup";
      comment = "Setup utility for Blackmagic Design capture and playback devices";
      categories = [ "Settings" "HardwareSettings" ];
    })
  ];
  
  meta = with lib; {
    homepage = "https://www.blackmagicdesign.com/support/family/capture-and-playback";
    maintainers = [ maintainers.hexchen ];
    license = licenses.unfree;
    description = "Supporting applications for Blackmagic Decklink, including GUI applications";
    platforms = platforms.linux;
  };
}
