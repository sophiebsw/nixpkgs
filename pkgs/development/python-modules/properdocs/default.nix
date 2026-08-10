{
  # eval time deps
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonAtLeast,

  # buildtime
  hatchling,

  # runtime deps
  click,
  ghp-import,
  jinja2,
  markdown,
  markupsafe,
  mergedeep,
  mkdocs-get-deps,
  packaging,
  pathspec,
  platformdirs,
  pyyaml,
  pyyaml-env-tag,
  watchdog,
  properdocs-theme-mkdocs,
  properdocs-theme-readthedocs,

  # optional-dependencies
  babel,
  setuptools,

  # testing deps
  mock,
  unittestCheckHook,
  doCheck ? true,
}:

buildPythonPackage (finalAttrs: {
  inherit doCheck;

  pname = "properdocs";
  version = "1.6.7";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ProperDocs";
    repo = "properdocs";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ACEgR9oNMPEDMLxeSJhNO7dJZBpTOiusfpE7XaXuztE=";
  };

  build-system = [
    hatchling
    # babel, setuptools required as "build hooks"
    babel
  ]
  ++ lib.optionals (pythonAtLeast "3.12") [ setuptools ];

  dependencies = [
    click
    ghp-import
    jinja2
    markdown
    markupsafe
    mergedeep
    mkdocs-get-deps
    packaging
    pathspec
    platformdirs
    pyyaml
    pyyaml-env-tag
    watchdog
  ];

  optional-dependencies = {
    i18n = [ babel ];
  };

  nativeCheckInputs = [
    unittestCheckHook
    mock
    properdocs-theme-mkdocs
    properdocs-theme-readthedocs
  ]
  #++ lib.optionals finalAttrs.doCheck [ unittestCheckHook properdocs-theme-mkdocs ]
  ++ finalAttrs.passthru.optional-dependencies.i18n;

  unittestFlagsArray = [
    "-v"
    "-p"
    "'*tests.py'"
    "properdocs"
  ];

  pythonImportsCheck = [ "properdocs" ];

  passthru.tests.unitTests = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };

  meta = {
    changelog = "https://github.com/ProperDocs/properdocs/releases/tag/${finalAttrs.version}";
    description = "Project documentation with Markdown / static website generator";
    mainProgram = "properdocs";
    downloadPage = "https://github.com/ProperDocs/properdocs";
    longDescription = ''
      ProperDocs is a fast, simple and downright gorgeous static site generator that's geared towards building project documentation. Documentation source files are written in Markdown, and configured with a single YAML configuration file.
    '';
    homepage = "https://properdocs.org/";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ sophiebsw ];
  };
})
