{
  lib,
  stdenv,
  testers,
  buildGoModule,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  nix-update-script,
  # whether to build the rdp-bridge submodule, requires CGO and pkgsStatic for static linking or the tests will fail
  withRDPBridge ? stdenv.hostPlatform.isStatic,
}:
buildGoModule (finalAttrs: {
  pname = "infisical";
  version = "0.43.121";

  src = fetchFromGitHub {
    owner = "infisical";
    repo = "cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-YQEftG6MHnM16ccL7+6d7Hds4hWIcR1kfMFJZs8fWAU=";
  };

  vendorHash = "sha256-XUqaPM5Rgzm2iyMbpb8okxjmVN9r7tR/m2BCA3Uo4dI=";

  rdp-bridge = lib.optionalDrvAttr withRDPBridge (rustPlatform.buildRustPackage {
    inherit (finalAttrs) version;

    pname = "infisical-rdp-bridge";
    src = "${finalAttrs.src}/packages/pam/handlers/rdp/native";

    cargoHash = "sha256-TPGt61WrgtyWC8EA0NjVRZorHQQcTmwtE7sQlaIAu9I=";
  });

  ldflags = [
    "-X github.com/Infisical/infisical-merge/packages/util.CLI_VERSION=${finalAttrs.version}"
    "-extldflags \"-static\""
  ];

  tags = [
    "osusergo"
    "netgo"
  ]
  ++ lib.lists.optional withRDPBridge "rdp";

  env.CGO_ENABLED = if withRDPBridge then 1 else 0;

  subPackages = [
    "."
    "packages/*"
  ];

  nativeBuildInputs = [ installShellFiles ];

  buildInputs = [ finalAttrs.rdp-bridge ];

  postBuild = ''
    mv $GOPATH/bin/infisical-merge $GOPATH/bin/infisical
  '';

  # infisical cli tests require credentials, we can only run the smoke test
  checkPhase = ''
    runHook preCheck
    PATH=$PATH:$GOPATH/bin sh ./smoke-tests/smoke.sh
    runHook postCheck
  '';

  postInstall = ''
    mkdir -p $out/share/man

    $out/bin/infisical man | gzip > $out/share/man/infisical.1.gz

    installManPage $out/share/man/infisical.1.gz

    mkdir -p $out/share/completions

    for shell in bash fish zsh; do
      $out/bin/infisical completion $shell > $out/share/completions/infisical.$shell
    done

    installShellCompletion $out/share/completions/infisical.{bash,fish,zsh}
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--subpackage"
        "rdp-bridge"
      ];
    };
    tests.version = testers.testVersion { package = finalAttrs.finalPackage; };
  };

  meta = {
    description = "Official Infisical CLI";
    longDescription = ''
      Infisical is the open-source secret management platform:
      Sync secrets across your team/infrastructure and prevent secret leaks.
    '';
    homepage = "https://infisical.com";
    changelog = "https://github.com/Infisical/cli/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "infisical";
    maintainers = with lib.maintainers; [ hausken ];
    teams = [ lib.teams.infisical ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
})
