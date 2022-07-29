{ fetchFromGitHub
, stdenv
, callPackage
, lib

, busybox, which, perl, flex
, git, pkg-config
, automake, cmake, autoconf, bison
, protobuf, ncurses, jansson, cairo, pcre, curl, libxml2, libxslt, zstd, gettext
, xorg, libXdmcp ? xorg.libXdmcp, libpthreadstubs ? xorg.libpthreadstubs
, libtool, utillinux
, bzip2, lzma, zlib
, boost, jemalloc
}:
let
  pname = "vg";
  version = "1.42.0";

  arch = callPackage ./arch.nix {};

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
      zstd.dev
      gettext
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
      sed -i 's/\(LD_STATIC_LIB_FLAGS.*\)-lz -lbz2 -llzma/\1/' ./source/Makefile
    '';

  preBuild = ''
    . ./source_me.sh
  '';

  src = fetchFromGitHub {
    owner = "vgteam";
    repo = "vg";
    rev = "v" + version;
    sha256 = "sha256-dJDmonPFe34pyxud/bqF3Qic2MRotWV9GpjdCuDap94=";
    fetchSubmodules = true;
  };

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://github.com/vgteam/vg";
    description = "Tools for working with genome variation graphs.";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = with maintainers; [ ]; # magic_rb ];
  };
}
