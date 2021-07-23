{ runCommandNoCCLocal
, busybox
}:

runCommandNoCCLocal "arch" {}
  ''
    mkdir -p $out/bin
    ln -s ${busybox}/bin/busybox $out/bin/arch
  ''
