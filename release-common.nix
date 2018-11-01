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
    name = "curl-7.62.0";

    src = fetchurl {
      urls = [
        "https://curl.haxx.se/download/${name}.tar.bz2"
        "https://github.com/curl/curl/releases/download/${lib.replaceStrings ["."] ["_"] name}/${name}.tar.bz2"
      ];
      sha256 = "084niy7cin13ba65p8x38w2xcyc54n3fgzbin40fa2shfr0ca0kq";
    };
    inherit stdenv;
  });

  buildDeps =
  [   curl
      bzip2 xz brotli
      openssl pkgconfig sqlite (boehmgc.override { enableLargeConfig = true; })
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
        version = "1.6.40";
        src = fetchFromGitHub {
          owner = "aws";
          repo = "aws-sdk-cpp";
          rev = "${version}";
          sha256 = "0hm1gjdckwxplhnq0s76zsvh410bmzbbhv942p9ammim4lvi864h";
        };
        #patches = args.patches or [] ++ [ ./transfermanager-content-encoding.patch ];
      }));

  perlDeps =
    [ perl
      perlPackages.DBDSQLite
    ];
}
