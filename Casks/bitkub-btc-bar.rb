cask "bitkub-btc-bar" do
  version "1.0.0"
  sha256 "7c0aecd51b4235ec2f44e528fe2b84f129bb372b3735f06f929092eb0c7e7a62"

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
