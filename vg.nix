{ fetchFromGitHub
, stdenv
, callPackage
, lib

, busybox, which, perl, flex
, git, pkg-config
, automake, cmake, autoconf, bison
, protobuf, ncurses, jansson, cairo, pcre, curl, libxml2, libxslt
, xorg, libXdmcp ? xorg.libXdmcp, libpthreadstubs ? xorg.libpthreadstubs
, libtool, utillinux
, bzip2, lzma, zlib
, boost, jemalloc
}:
let
  pname = "vg";
  version = "1.33.0";

  arch = callPackage ./arch.nix {};

  hopscotch_map = fetchFromGitHub {
    owner = "Tessil";
    repo = "hopscotch-map";
    rev = "848374746a50b3ebebe656611d554cb134e9aeef";
    sha256 = "sha256-8ChVKK80M1nG5HvhpU3rNrG0nzmYxeKk78e3TB8e+nY=";
  };

  inherit (lib) optionalString;
in
stdenv.mkDerivation {
  inherit pname version;

  nativeBuildInputs =
    [ git pkg-config protobuf
      arch which perl flex
      cmake automake autoconf bison
    ];
  buildInputs =
    [ ncurses.dev
      jansson
      cairo
      pcre.dev
      libpthreadstubs
      libXdmcp
      libtool
      utillinux
      curl.dev
      libxml2
      libxslt.dev
      bzip2 lzma zlib.static
      boost
    ];

  dontConfigure = true;
  
  buildPhase = ''
    . ./source_me.sh && make -j "$NIX_BUILD_CORES"
  '';

  installPhase = ''
    install -D ./bin/bgzip $out/bin/bgzip 
    install -D ./bin/htsfile $out/bin/htsfile 
    install -D ./bin/tabix $out/bin/tabix 
    install -D ./bin/vg $out/bin/vg 

    install -D ./lib/libjemalloc.so $out/lib/libjemalloc.so
    install -D ./lib/libdeflate.so $out/lib/libdeflate.so
    ln -s $out/lib/libjemalloc.so $out/lib/libjemalloc.so.2
  '';

  fixupPhase = ''
    for bin in $out/bin/* ; do
      patchelf --allowed-rpath-prefixes /nix/store --shrink-rpath $bin
      patchelf --set-rpath "$out/lib:$(patchelf --print-rpath $bin)" $bin
    done
  '';

  postUnpack =
    ''
      patchShebangs --build ./source/deps/sdsl-lite/ ./source/deps/sdsl-lite/build/
      sed -i 's/return HTSCODECS_VERSION_TEXT;/return '"\"$(grep -oP 'version (\d+\.)+\d+$' ./source/deps/htslib/htscodecs/README.md | grep -oP '(\d+\.)+\d+$')\""';/' ./source/deps/htslib/htscodecs/htscodecs/htscodecs.c 
      sed -i 's/hopscotch_map-prefix\/src\/hopscotch_map\/include\/\*/\''${PWD}\/deps\/DYNAMIC\/deps\/hopscotch_map\/include\/*/' ./source/Makefile
      sed -i 's/\(LD_STATIC_LIB_FLAGS.*\)-lz -lbz2 -llzma/\1/' ./source/Makefile

      (
        cd ./source/deps/DYNAMIC
        patch -i ${./patches/0001-DYNAMIC-Move-hopscotch_map-to-a-submodule-and-update-CMakeLists.patch} 
        mkdir -p ./deps
        ln -s ${hopscotch_map} ./deps/hopscotch_map
        ls ./deps/hopscotch_map
      )
    '';

  preBuild = ''
    . ./source_me.sh
  '';

  src = fetchFromGitHub {
    owner = "vgteam";
    repo = "vg";
    rev = "v" + version;
    sha256 = "sha256-YkbLe3etJHKtNYeK8qm2MLBVzokYb4uaJoyxWPg3Ss4=";
    fetchSubmodules = true;
  };

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://github.com/vgteam/vg";
    description = "Tools for working with genome variation graphs.";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = with maintainers; [ magic_rb ];
  };
}
