cask "bitkub-btc-bar" do
  version "1.0.0"
  sha256 :no_check

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
