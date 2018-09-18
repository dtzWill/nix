{ pkgs }:

with pkgs;

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

  buildDeps =
  [ (curl.overrideAttrs (o:{
    src = fetchFromGitHub {
      owner = "curl";
      repo = "curl";
      rev = "d0c615b81b28e21e312f8a264e8c513757136c41";
      sha256 = "16iwfbb7rby68rc0y4z2cifnxcph7w9kd4hakv93h5k6asc4mffq";
    };
    name = "curl-2018-09-18";

    nativeBuildInputs = (o.nativeBuildInputs or []) ++ [ autoreconfHook ];

    preConfigure = ":"; # override normal 'preConfigure', not needed when building from git
  }))
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
      }).overrideDerivation (args: rec {
        name = "aws-sdk-cpp-${version}";
        version = "1.5.15";
        src = fetchFromGitHub {
          owner = "aws";
          repo = "aws-sdk-cpp";
          rev = "${version}";
          sha256 = "0a7k2cclmhkhlq5l7lwvq84lczxdjjbr4dayj4ffn02w2ds0dxmh";
        };
        patches = args.patches or [] ++ [ ./transfermanager-content-encoding.patch ];
        #patches = args.patches or [] ++ [ (fetchpatch {
        #  url = https://github.com/edolstra/aws-sdk-cpp/commit/3e07e1f1aae41b4c8b340735ff9e8c735f0c063f.patch;
        #  sha256 = "1pij0v449p166f9l29x7ppzk8j7g9k9mp15ilh5qxp29c7fnvxy2";
        #}) ];
      }));

  perlDeps =
    [ perl
      perlPackages.DBDSQLite
    ];
}
