cask "bitkub-btc-bar" do
  version "1.1.0"
  sha256 "d9f917f27791cb0725b47c229e0c537c74cfb299c8e9af95d1ff3ab613cc18e7"

  url "https://github.com/greenoxz/bitkub-btc-bar/releases/download/v#{version}/BitkubBtcBar.zip"
  name "Bitkub BTC Bar"
  desc "macOS Menu Bar app for Bitkub Bitcoin DCA tracking and live prices"
  homepage "https://github.com/greenoxz/bitkub-btc-bar"

  depends_on macos: ">= :ventura"

  app "BitkubBtcBar.app"

  zap trash: [
    "~/Library/Preferences/com.pisitz.bitkubbtcbar.plist",
  ]
end
