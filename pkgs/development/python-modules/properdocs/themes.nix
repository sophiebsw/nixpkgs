{
  # eval time deps
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonAtLeast,
  callPackage,

  # buildtime
  hatchling,

  # optional-dependencies
  babel,
  setuptools,
}:
let
  # properdocs depends on these themes in order for its unit tests to pass, but these themes depend on properdocs. disables running the checkPhase in the version of properdocs used for these phases specifically, but the top-level package still runs it
  properdocs = callPackage ./. { doCheck = false; };
  themes = [ "properdocs-theme-mkdocs" "properdocs-theme-readthedocs" ];
in
lib.genAttrs themes (pname:
buildPythonPackage (finalAttrs: {
  inherit pname;
  version = "1.6.7";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ProperDocs";
    repo = "properdocs";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ACEgR9oNMPEDMLxeSJhNO7dJZBpTOiusfpE7XaXuztE=";
  };

  sourceRoot = "${finalAttrs.src.name}/packages/${pname}";

  build-system = [
    hatchling
    # babel, setuptools required as "build hooks"
    babel
  ]
  ++ lib.optionals (pythonAtLeast "3.12") [ setuptools ];

  dependencies = [
    properdocs
  ];

  optional-dependencies = {
    i18n = [ babel ];
  };

  pythonImportsCheck = lib.singleton (lib.replaceString "-" "_" pname);

  meta = {
    changelog = "https://github.com/ProperDocs/properdocs/releases/tag/${finalAttrs.version}";
    description = "Project documentation with Markdown / static website generator";
    mainProgram = finalAttrs.pname;
    downloadPage = "https://github.com/ProperDocs/properdocs";
    longDescription = ''
      ProperDocs is a fast, simple and downright gorgeous static site generator that's geared towards building project documentation. Documentation source files are written in Markdown, and configured with a single YAML configuration file.
    '';
    homepage = "https://properdocs.org/";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ sophiebsw ];
  };
}))
