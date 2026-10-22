# nodejs.org の公式バイナリ (darwin-arm64) をそのまま置く一時的なパッケージ。
#
# 2026-10-21 の security release (CVE-2026-111497 ほか 10 件) の修正版 24.22.1 が nixpkgs では staging 止まりで、
# nixos-unstable の nodejs_24 は 24.21.0 のまま。追いつくまでこれを home.packages に入れる。
# 進み具合: https://nixpk.gs/pr-tracker.html?pr=576777
# nixos-unstable の nodejs が 24.22.1 以上になったら、packages.nix を pkgs.nodejs に戻してこのファイルを消す (#136)。
# version と sha256 は直書きなので Dependabot では進まない。次の security release が出たら手で上げる。
#
# macOS のバイナリはビルド済みのまま動くので、fixup (strip / shebang の書き換え / 再署名) をかけない。
# Mach-O の署名を保ったまま store へ置く
{ stdenvNoCC, fetchurl }:
let
  version = "24.22.1";
in
stdenvNoCC.mkDerivation {
  pname = "nodejs-bin";
  inherit version;

  src = fetchurl {
    url = "https://nodejs.org/dist/v${version}/node-v${version}-darwin-arm64.tar.gz";
    # https://nodejs.org/dist/v24.22.1/SHASUMS256.txt の値
    sha256 = "89c682593d76cd44233fa53b1563264e7de9cbb189cad169135c5b4fadfbc0a7";
  };

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -R bin include lib share "$out/"
    runHook postInstall
  '';

  meta.platforms = [ "aarch64-darwin" ];
}
