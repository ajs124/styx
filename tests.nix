/* Basic tests for Styx

   run all tests with:

     nix-build ./tests.nix

   Open a theme example site in a browser with (many links will be broken):

     $BROWSER $(nix-build -A showcase-site ./tests.nix)/index.html

*/
{ pkgs ? import <nixpkgs> {} }:

with pkgs.lib;
let

  styx = import ./. { inherit pkgs; };

  styx-themes = pkgs.styx-themes;

  mkThemeTest = theme: (pkgs.callPackage (import "${styx-themes."${theme}"}/example/site.nix") {
    inherit styx;
    # Overriding the siteUrl to make url relatives for browsing directly from the store
    # work only for the top page
    extraConf.siteUrl = ".";
  }).site;

  themes = fold (a: acc: acc // { "${a}-site" = mkThemeTest a; }) {} [ "agency" "hyde" "orbit" "showcase" ];

in

rec {

  new = pkgs.runCommand "styx-new-site" {} ''
    mkdir $out
    ${styx}/bin/styx new site my-site --in $out
  '';

  new-theme = pkgs.runCommand "styx-new-theme" {} ''
    mkdir $out
    ${styx}/bin/styx new site my-site --in $out
    ${styx}/bin/styx new theme my-theme --in $out/my-site/themes
  '';

  serve = pkgs.runCommand "styx-serve" { buildInputs = [ pkgs.curl ]; } ''
    mkdir $out
    ${styx}/bin/styx serve --site-path ${themes.showcase-site} --detach
    sleep 3
    curl -I 127.0.0.1:8080/index.html > $out/result
  '';

  deploy-gh-pages = pkgs.runCommand "styx-deploy-gh" { buildInputs = [ pkgs.git ]; } ''
    mkdir $out
    cp -r ${styx-themes.showcase}/example/* $out/
    export HOME=$out
    export GIT_CONFIG_NOSYSTEM=1
    git config --global user.name  "styx test"
    git config --global user.email "styx@test.styx"
    cd $out && git init && git add . && git commit -m "init repo"
    ${styx}/bin/styx deploy --init-gh-pages --in $out
    ${styx}/bin/styx deploy --gh-pages --in $out --site-path "${themes.showcase-site}/"
  '';

} // themes
