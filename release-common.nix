{ pkgs }:

with pkgs;


rec {
  stdenv = (pkgs.llvmPackages_latest or pkgs.llvmPackages).libcxxStdenv;
  boost = pkgs.boost.override { inherit stdenv; };

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
    pname = "curl";
    version = "2019-03-20";
    name = "${pname}-${version}";

    src = fetchFromGitHub {
      owner = pname;
      repo = pname;
      rev = "a375ab3be458c1aed126efc9739cf4d6eae9d59b";
      sha256 = "0j3q2f91wm9z96x4kay5mpyfnm7d6hlrgd16kfxnrwga0zzg2znv";
    };
    #src = fetchurl {
    #  urls = [
    #    "https://curl.haxx.se/download/${name}.tar.bz2"
    #    "https://github.com/curl/curl/releases/download/${lib.replaceStrings ["."] ["_"] name}/${name}.tar.bz2"
    #  ];
    #  sha256 = "1szj9ia1snbfqzfcsk6hx1j7jhbqsy0f9k5d7x9xiy8w5lfblwym";
    #};
    inherit stdenv;

    nativeBuildInputs = (o.nativeBuildInputs or []) ++ [ autoreconfHook ];
    preConfigure = ""; # default preConfigure not needed when building w/git (and problematic)

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
