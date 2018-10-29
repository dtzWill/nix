{ pkgs }:

with pkgs;

let stdenv = clangStdenv; in

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

  curl = pkgs.curl.overrideAttrs (o:{
    src = fetchFromGitHub {
      owner = "curl";
      repo = "curl";
      rev = "5728229a4fd209421fdd324dab5fd445d5917508";
      sha256 = "1f4wrzdhrdhjny6scc28apadrmcn9jlmwkzgb1ccs6nmjnhs3cyn";
    };
    name = "curl-2018-10-29";

    nativeBuildInputs = (o.nativeBuildInputs or []) ++ [ autoreconfHook ];
    inherit stdenv;

    preConfigure = ":"; # override normal 'preConfigure', not needed when building from git
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
        patches = args.patches or [] ++ [ ./transfermanager-content-encoding.patch ];
      }));

  perlDeps =
    [ perl
      perlPackages.DBDSQLite
    ];
}
