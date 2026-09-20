cask "bitkub-btc-bar" do
  version "1.0.2"
  sha256 "be029c2877656f82f60d2f325579041f7c45597e2468cf16a1554260dc2e197c"

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
