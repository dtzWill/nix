{ pkgs }:

with pkgs;


rec {
  stdenv = (pkgs.llvmPackages_latest or pkgs.llvmPackages).libcxxStdenv;

  # 1.67 has problems w/libc++, probably could use older or newer
  # let's just use newer when available...
  boost = (pkgs.boost17x or pkgs.boost169 or pkgs.boost168 or pkgs.boost16x).override { inherit stdenv; };

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
      docbook_xsl_ns
      autoconf-archive
      autoreconfHook
    ];

  curl = pkgs.curl.overrideAttrs (o: rec {
    name = "curl-7.65.1";

    src = fetchurl {
      urls = [
        "https://curl.haxx.se/download/${name}.tar.bz2"
        "https://github.com/curl/curl/releases/download/${lib.replaceStrings ["."] ["_"] name}/${name}.tar.bz2"
      ];
      sha256 = "1xz3hr3frbawpw49cpm5d6cxqjqqy77n8c2g3c0n3r291kv6vlyb";
    };
    inherit stdenv;

    patches = null; # remove ipv6 patch now included \o/
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
      (aws-sdk-cpp.override {
        apis = ["s3" "transfer"];
        customMemoryManagement = false;
        inherit stdenv curl;
      });

  perlDeps =
    [ perl
      perlPackages.DBDSQLite
    ];
}
