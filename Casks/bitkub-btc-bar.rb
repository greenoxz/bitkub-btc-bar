cask "bitkub-btc-bar" do
  version "1.0.1"
  sha256 "acb0a06b1202e515a38be7bb937c286e2951697bd7cf02c58e16fd8a8f774433"

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
