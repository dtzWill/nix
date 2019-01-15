{ pkgs }:

with pkgs;

let stdenv = llvmPackages_5.libcxxStdenv; in

rec {
  # Use "busybox-sandbox-shell" if present,
  # if not (legacy) fallback and hope it's sufficient.
  sh = pkgs.busybox-sandbox-shell or (busybox.override {
    useMusl = true;
    enableStatic = true;
    enableMinimal = true;
    extraConfig = ''
      CONFIG_FEATURE_FANCY_ECHO y
      CONFIG_FEATURE_SH_MATH y
      CONFIG_FEATURE_SH_MATH_64 y

      CONFIG_ASH y
      CONFIG_ASH_OPTIMIZE_FOR_SIZE y

      CONFIG_ASH_ALIAS y
      CONFIG_ASH_BASH_COMPAT y
      CONFIG_ASH_CMDCMD y
      CONFIG_ASH_ECHO y
      CONFIG_ASH_GETOPTS y
      CONFIG_ASH_INTERNAL_GLOB y
      CONFIG_ASH_JOB_CONTROL y
      CONFIG_ASH_PRINTF y
      CONFIG_ASH_TEST y
    '';
  });

  configureFlags =
    [
      "--enable-gc"
    ] ++ lib.optionals stdenv.isLinux [
      "--with-sandbox-shell=${sh}/bin/busybox"
    ];

  tarballDeps =
    [ bison
      flex
      libxml2
      libxslt
      docbook5
      docbook5_xsl
      autoconf-archive
      autoreconfHook
    ];

  curl = pkgs.curl.overrideAttrs (o: rec {
    name = "curl-7.63.0";

    src = fetchurl {
      urls = [
        "https://curl.haxx.se/download/${name}.tar.bz2"
        "https://github.com/curl/curl/releases/download/${lib.replaceStrings ["."] ["_"] name}/${name}.tar.bz2"
      ];
      sha256 = "1n4dzlbllwks8xkz466j362da0pbnxgwr11d64504xzzxka7xawv";
    };
    inherit stdenv;

    patches = null; # remove ipv6 patch now included :/
  });

  buildDeps =
  [   curl
      bzip2 xz brotli editline
      openssl pkgconfig sqlite boehmgc
      boost

      # Tests
      git
      mercurial
    ]
    ++ lib.optionals stdenv.isLinux [libseccomp utillinuxMinimal]
    ++ lib.optional (stdenv.isLinux || stdenv.isDarwin) libsodium
    ++ lib.optional (stdenv.isLinux || stdenv.isDarwin)
      ((aws-sdk-cpp.override {
        apis = ["s3" "transfer"];
        customMemoryManagement = false;
        inherit stdenv curl;
      }).overrideDerivation (args: rec {
        name = "aws-sdk-cpp-${version}";
        version = "1.7.34";
        src = fetchFromGitHub {
          owner = "aws";
          repo = "aws-sdk-cpp";
          rev = "${version}";
          sha256 = "0vd90ycqlldgiwygb8lswbi6mmfjhbkkjbpjimssa3qvjdfaybg8";
        };
        #patches = args.patches or [] ++ [ ./transfermanager-content-encoding.patch ];
      }));

  perlDeps =
    [ perl
      perlPackages.DBDSQLite
    ];
}
