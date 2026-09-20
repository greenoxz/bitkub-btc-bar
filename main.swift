import Cocoa
import SwiftUI
import Charts
import CryptoKit
import Combine

// MARK: - Models

struct BitkubTickerItem: Codable {
    let id: Int?
    let last: Double
    let lowestAsk: Double?
    let highestBid: Double?
    let percentChange: Double
    let baseVolume: Double?
    let quoteVolume: Double?
    let high24hr: Double
    let low24hr: Double
}

struct PriceHistoryPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let price: Double
}

struct DcaComparisonPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let btcValue: Double
    let cashValue: Double
}

struct DcaOrderItem: Identifiable {
    let id = UUID()
    let date: Date
    let thbAmount: Double
    let rate: Double
    let btcAmount: Double
    var satsAmount: Int64 {
        return Int64(btcAmount * 100_000_000)
    }
}

// MARK: - Visual Effect Blur (Frosted Glass Backdrop)

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Liquid Glass View Modifier

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    var fillOpacity: Double = 0.08
    var borderOpacity: Double = 0.35

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.12),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(borderOpacity),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 12, fillOpacity: Double = 0.08, borderOpacity: Double = 0.35) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, fillOpacity: fillOpacity, borderOpacity: borderOpacity))
    }
}

struct LiquidGlassPillModifier: ViewModifier {
    var fillOpacity: Double = 0.08
    var borderOpacity: Double = 0.35

    func body(content: Content) -> some View {
        content
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.14),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(borderOpacity),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.18), radius: 5, x: 0, y: 2)
    }
}

extension View {
    func liquidGlassPill(fillOpacity: Double = 0.09, borderOpacity: Double = 0.25) -> some View {
        self.modifier(LiquidGlassPillModifier(fillOpacity: fillOpacity, borderOpacity: borderOpacity))
    }
}

// MARK: - Secure Storage Helper

final class SecureStore {
    static let shared = SecureStore()
    private let keyPrefix = "com.bitkub.btcbar."

    func save(key: String, value: String) {
        UserDefaults.standard.set(value, forKey: keyPrefix + key)
    }

    func load(key: String) -> String {
        return UserDefaults.standard.string(forKey: keyPrefix + key) ?? ""
    }
}

// MARK: - Bitkub Store

final class BitkubStore: ObservableObject, @unchecked Sendable {
    @Published var lastPrice: Double = 0.0
    @Published var percentChange: Double = 0.0
    @Published var high24hr: Double = 0.0
    @Published var low24hr: Double = 0.0

    // Balances
    @Published var btcBalance: Double = 0.0
    @Published var thbBalance: Double = 0.0
    @Published var manualBalance: Double = 0.0
    @Published var useApiForBalance: Bool = true

    // DCA Tracking & History
    @Published var totalInvestedThb: Double = 0.0
    @Published var dcaBtcAmount: Double = 0.0
    @Published var averageBuyPrice: Double = 0.0
    @Published var dcaOrderCount: Int = 0
    @Published var dcaStartDate: Date?
    @Published var showDcaProfitOnBar: Bool = true
    @Published var barDisplayMode: Int = 0 // 0: เงินในพอร์ต (Portfolio), 1: ราคาตลาดวันนี้ (Market Price)
    @Published var recentDcaOrders: [DcaOrderItem] = []

    // Low Balance Alert by Days (Default: 2 days)
    @Published var dailyDcaAmount: Double = 108.0
    @Published var warningDaysThreshold: Int = 2
    @Published var thresholdInput: String = "2"
    private var lastAlertDate: Date? = nil

    // Charts: 0: DCA vs Cash, 1: 90-Day Price, 2: 24h, 3: Daily Buys
    @Published var selectedChartTab: Int = 0
    @Published var comparisonPoints: [DcaComparisonPoint] = []
    @Published var priceHistory24h: [PriceHistoryPoint] = []
    @Published var priceHistoryDca: [PriceHistoryPoint] = []
    @Published var dcaMinPrice: Double = 0.0
    @Published var dcaMaxPrice: Double = 0.0

    @Published var isRefreshing: Bool = false
    @Published var lastUpdated: Date?
    @Published var apiErrorMessage: String?

    // UI & Settings State
    @Published var showingSettings: Bool = false
    @Published var apiKeyInput: String = ""
    @Published var apiSecretInput: String = ""
    @Published var manualBtcInput: String = ""
    @Published var saveSuccess: Bool = false

    // Saved Credentials
    @Published var apiKey: String = ""
    @Published var apiSecret: String = ""

    var onUpdate: (() -> Void)?

    private var priceTimer: Timer?
    private var walletTimer: Timer?
    private var historyTimer: Timer?

    init() {
        self.apiKey = SecureStore.shared.load(key: "apiKey")
        self.apiSecret = SecureStore.shared.load(key: "apiSecret")
        self.apiKeyInput = self.apiKey
        self.apiSecretInput = self.apiSecret

        self.manualBalance = UserDefaults.standard.double(forKey: "com.bitkub.btcbar.manualBalance")
        if self.manualBalance > 0 {
            self.manualBtcInput = String(format: "%.8f", self.manualBalance)
        }
        let savedDays = UserDefaults.standard.integer(forKey: "com.bitkub.btcbar.warningDays")
        if savedDays > 0 {
            self.warningDaysThreshold = savedDays
            self.thresholdInput = "\(savedDays)"
        } else {
            self.warningDaysThreshold = 2
            self.thresholdInput = "2"
        }

        self.useApiForBalance = !apiKey.isEmpty && !apiSecret.isEmpty
        self.showDcaProfitOnBar = UserDefaults.standard.bool(forKey: "com.bitkub.btcbar.showDcaOnBar")
        self.barDisplayMode = UserDefaults.standard.integer(forKey: "com.bitkub.btcbar.barDisplayMode")

        startTimers()
        fetchAllData()
    }

    func saveCredentials() {
        self.apiKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiSecret = apiSecretInput.trimmingCharacters(in: .whitespacesAndNewlines)
        SecureStore.shared.save(key: "apiKey", value: self.apiKey)
        SecureStore.shared.save(key: "apiSecret", value: self.apiSecret)

        if let val = Double(manualBtcInput) {
            self.manualBalance = val
            UserDefaults.standard.set(val, forKey: "com.bitkub.btcbar.manualBalance")
        }

        if let days = Int(thresholdInput), days > 0 {
            self.warningDaysThreshold = days
            UserDefaults.standard.set(days, forKey: "com.bitkub.btcbar.warningDays")
        }

        self.useApiForBalance = !self.apiKey.isEmpty && !self.apiSecret.isEmpty
        self.apiErrorMessage = nil
        self.saveSuccess = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.saveSuccess = false
            self?.showingSettings = false
        }

        fetchAllData()
    }

    func toggleBarDisplayMode() {
        showDcaProfitOnBar.toggle()
        UserDefaults.standard.set(showDcaProfitOnBar, forKey: "com.bitkub.btcbar.showDcaOnBar")
        onUpdate?()
    }

    func setBarDisplayMode(_ mode: Int) {
        barDisplayMode = mode
        UserDefaults.standard.set(mode, forKey: "com.bitkub.btcbar.barDisplayMode")
        onUpdate?()
    }

    var effectiveBtc: Double {
        if useApiForBalance && (!apiKey.isEmpty && !apiSecret.isEmpty) {
            return btcBalance
        }
        return manualBalance
    }

    var totalPortfolioValue: Double {
        return effectiveBtc * lastPrice
    }

    // Sats Calculations
    var totalSats: Int64 {
        return Int64(effectiveBtc * 100_000_000)
    }

    var dcaSats: Int64 {
        return Int64(dcaBtcAmount * 100_000_000)
    }

    var latestOrder: DcaOrderItem? {
        return recentDcaOrders.first
    }

    // DCA Calculations
    var dcaCurrentValue: Double {
        return dcaBtcAmount * lastPrice
    }

    var dcaProfitThb: Double {
        return dcaCurrentValue - totalInvestedThb
    }

    var dcaProfitPercent: Double {
        guard totalInvestedThb > 0 else { return 0.0 }
        return (dcaProfitThb / totalInvestedThb) * 100.0
    }

    var dcaDaysLeft: Int {
        guard dailyDcaAmount > 0 else { return 0 }
        return Int(thbBalance / dailyDcaAmount)
    }

    var isThbLow: Bool {
        return dcaDaysLeft <= warningDaysThreshold
    }

    func checkAndNotifyLowBalance() {
        guard isThbLow && !apiKey.isEmpty else { return }
        if let last = lastAlertDate, Date().timeIntervalSince(last) < 21600 {
            return
        }
        lastAlertDate = Date()

        let msg = "เงินบาทใน Bitkub เหลือ ฿\(thbBalance.formattedWithCommas(decimalPlaces: 2)) (DCA ได้อีก ~\(dcaDaysLeft) วัน) อย่าลืมเติมเงินนะครับ"
        let script = "display notification \"\(msg)\" with title \"⚠️ เตือนเงินบาท Bitkub ใกล้หมด!\" sound name \"Submarine\""
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        try? proc.run()
    }

    func startTimers() {
        priceTimer?.invalidate()
        priceTimer = Timer.scheduledTimer(withTimeInterval: 12.0, repeats: true) { [weak self] _ in
            self?.fetchTicker()
        }

        walletTimer?.invalidate()
        walletTimer = Timer.scheduledTimer(withTimeInterval: 45.0, repeats: true) { [weak self] _ in
            self?.fetchWallet()
        }

        historyTimer?.invalidate()
        historyTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchOrderHistoryAsync()
            }
        }
    }

    func fetchAllData() {
        DispatchQueue.main.async { self.isRefreshing = true }
        Task {
            await fetchTickerAsync()
            await fetch24hHistoryAsync()
            await fetchWalletAsync()
            await fetchOrderHistoryAsync()
            DispatchQueue.main.async {
                self.lastUpdated = Date()
                self.isRefreshing = false
                self.onUpdate?()
            }
        }
    }

    func fetchTicker() {
        Task {
            await fetchTickerAsync()
            DispatchQueue.main.async {
                self.lastUpdated = Date()
                self.onUpdate?()
            }
        }
    }

    func fetchWallet() {
        Task {
            await fetchWalletAsync()
            DispatchQueue.main.async {
                self.onUpdate?()
            }
        }
    }

    // MARK: - Async Fetchers

    private func fetchTickerAsync() async {
        guard let url = URL(string: "https://api.bitkub.com/api/market/ticker") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode([String: BitkubTickerItem].self, from: data)
            if let btc = result["THB_BTC"] {
                DispatchQueue.main.async {
                    self.lastPrice = btc.last
                    self.percentChange = btc.percentChange
                    self.high24hr = btc.high24hr
                    self.low24hr = btc.low24hr
                }
            }
        } catch {
            print("Ticker fetch error: \(error)")
        }
    }

    private func fetch24hHistoryAsync() async {
        let to = Int(Date().timeIntervalSince1970)
        let from = to - (24 * 60 * 60)
        guard let url = URL(string: "https://api.bitkub.com/tradingview/history?symbol=BTC_THB&resolution=60&from=\(from)&to=\(to)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let closes = json["c"] as? [Double],
               let timestamps = json["t"] as? [Int] {

                var points: [PriceHistoryPoint] = []
                for (idx, price) in closes.enumerated() {
                    let date = Date(timeIntervalSince1970: TimeInterval(timestamps[idx]))
                    points.append(PriceHistoryPoint(timestamp: date, price: price))
                }
                DispatchQueue.main.async {
                    self.priceHistory24h = points
                }
            }
        } catch {
            print("24h History fetch error: \(error)")
        }
    }

    private func fetchDcaComparisonAndHistoryAsync(startDate: Date, buys: [(thb: Double, btc: Double, ts: Int64, rate: Double)]) async {
        let from = Int(startDate.timeIntervalSince1970)
        let to = Int(Date().timeIntervalSince1970)
        guard let url = URL(string: "https://api.bitkub.com/tradingview/history?symbol=BTC_THB&resolution=D&from=\(from)&to=\(to)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let closes = json["c"] as? [Double],
               let highs = json["h"] as? [Double],
               let lows = json["l"] as? [Double],
               let timestamps = json["t"] as? [Int] {

                var pricePoints: [PriceHistoryPoint] = []
                var comparison: [DcaComparisonPoint] = []

                var cumCash: Double = 0.0
                var cumBtc: Double = 0.0
                var buyIdx = 0

                let sortedBuysAsc = buys.sorted(by: { $0.ts < $1.ts })

                for (idx, price) in closes.enumerated() {
                    let dayTime = Double(timestamps[idx])
                    let dayEndDate = dayTime + 86400
                    let dayEndMs = Int64(dayEndDate * 1000)

                    while buyIdx < sortedBuysAsc.count && sortedBuysAsc[buyIdx].ts < dayEndMs {
                        cumCash += sortedBuysAsc[buyIdx].thb
                        cumBtc += sortedBuysAsc[buyIdx].btc
                        buyIdx += 1
                    }

                    let date = Date(timeIntervalSince1970: dayTime)
                    let currentBtcValue = cumBtc * price

                    pricePoints.append(PriceHistoryPoint(timestamp: date, price: price))
                    comparison.append(DcaComparisonPoint(timestamp: date, btcValue: currentBtcValue, cashValue: cumCash))
                }

                let minP = lows.min() ?? (closes.min() ?? 0)
                let maxP = highs.max() ?? (closes.max() ?? 0)

                DispatchQueue.main.async {
                    self.priceHistoryDca = pricePoints
                    self.comparisonPoints = comparison
                    self.dcaMinPrice = minP
                    self.dcaMaxPrice = maxP
                }
            }
        } catch {
            print("DCA comparison fetch error: \(error)")
        }
    }

    private func fetchServerTime() async throws -> Int64 {
        guard let url = URL(string: "https://api.bitkub.com/api/v3/servertime") else {
            return Int64(Date().timeIntervalSince1970 * 1000)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           let ms = Int64(str) {
            return ms
        }
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    private func generateSignature(secret: String, payload: String) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(payload.utf8), using: key)
        return signature.map { String(format: "%02hhx", $0) }.joined()
    }

    private func fetchWalletAsync() async {
        guard !apiKey.isEmpty && !apiSecret.isEmpty else { return }

        do {
            let timestamp = try await fetchServerTime()
            let method = "GET"
            let path = "/api/v4/wallet/balances"
            let payload = "\(timestamp)\(method)\(path)"
            let signature = generateSignature(secret: apiSecret, payload: payload)

            guard let url = URL(string: "https://api.bitkub.com\(path)") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "X-BTK-APIKEY")
            request.setValue("\(timestamp)", forHTTPHeaderField: "X-BTK-TIMESTAMP")
            request.setValue(signature, forHTTPHeaderField: "X-BTK-SIGN")

            let (data, _) = try await URLSession.shared.data(for: request)

            struct V4Response: Codable {
                let code: String?
                let message: String?
                let data: [V4BalanceItem]?
            }
            struct V4BalanceItem: Codable {
                let currency: String
                let available: String?
                let reserved: String?
                let total: String?
            }

            let decoder = JSONDecoder()
            if let res = try? decoder.decode(V4Response.self, from: data), let list = res.data {
                if let btcItem = list.first(where: { $0.currency.uppercased() == "BTC" }) {
                    let totalVal = Double(btcItem.total ?? "") ?? ((Double(btcItem.available ?? "") ?? 0.0) + (Double(btcItem.reserved ?? "") ?? 0.0))
                    DispatchQueue.main.async {
                        self.btcBalance = totalVal
                    }
                }

                if let thbItem = list.first(where: { $0.currency.uppercased() == "THB" }) {
                    let availThb = Double(thbItem.available ?? "") ?? (Double(thbItem.total ?? "") ?? 0.0)
                    DispatchQueue.main.async {
                        self.thbBalance = availThb
                        self.checkAndNotifyLowBalance()
                    }
                }

                DispatchQueue.main.async {
                    self.apiErrorMessage = nil
                }
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                DispatchQueue.main.async {
                    if let msg = json["message"] as? String, msg != "success" {
                        self.apiErrorMessage = msg
                    } else if let error = json["error"] as? Int, error != 0 {
                        self.apiErrorMessage = "Bitkub error: \(error)"
                    }
                }
            }
        } catch {
            print("Wallet error: \(error)")
            DispatchQueue.main.async {
                self.apiErrorMessage = "เชื่อมต่อล้มเหลว: \(error.localizedDescription)"
            }
        }
    }

    private func fetchOrderHistoryAsync() async {
        guard !apiKey.isEmpty && !apiSecret.isEmpty else { return }

        var cursor: String? = nil
        var buys: [(thb: Double, btc: Double, ts: Int64, rate: Double)] = []

        while true {
            do {
                let timestamp = try await fetchServerTime()
                let method = "GET"
                let path = "/api/v3/market/my-order-history"
                var query = "?sym=BTC_THB&lmt=100"
                if let cur = cursor, !cur.isEmpty {
                    let encoded = cur.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cur
                    query += "&cursor=\(encoded)"
                }
                let payload = "\(timestamp)\(method)\(path)\(query)"
                let signature = generateSignature(secret: apiSecret, payload: payload)

                guard let url = URL(string: "https://api.bitkub.com\(path)\(query)") else { break }
                var request = URLRequest(url: url)
                request.httpMethod = method
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue(apiKey, forHTTPHeaderField: "X-BTK-APIKEY")
                request.setValue("\(timestamp)", forHTTPHeaderField: "X-BTK-TIMESTAMP")
                request.setValue(signature, forHTTPHeaderField: "X-BTK-SIGN")

                let (data, _) = try await URLSession.shared.data(for: request)

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let orders = json["result"] as? [[String: Any]] {

                    for o in orders {
                        if let side = o["side"] as? String, side == "buy" {
                            let amtStr = "\(o["amount"] ?? "0")"
                            let rateStr = "\(o["rate"] ?? "1")"
                            let feeStr = "\(o["fee"] ?? "0")"
                            let amt = Double(amtStr) ?? 0
                            let rate = Double(rateStr) ?? 1
                            let fee = Double(feeStr) ?? 0
                            let ts = (o["ts"] as? Int64) ?? Int64(Date().timeIntervalSince1970 * 1000)

                            let btcReceived = rate > 0 ? (amt - fee) / rate : 0
                            buys.append((thb: amt, btc: btcReceived, ts: ts, rate: rate))
                        }
                    }

                    if let pag = json["pagination"] as? [String: Any],
                       let hasNext = pag["has_next"] as? Bool, hasNext,
                       let nextCursor = pag["cursor"] as? String {
                        cursor = nextCursor
                    } else {
                        break
                    }
                } else {
                    break
                }
            } catch {
                print("Order history error: \(error)")
                break
            }
        }

        if !buys.isEmpty {
            let totalThb = buys.reduce(0.0) { $0 + $1.thb }
            let totalBtc = buys.reduce(0.0) { $0 + $1.btc }
            let avgPrice = totalBtc > 0 ? totalThb / totalBtc : 0
            let minTs = buys.map { $0.ts }.min() ?? 0
            let startDate = minTs > 0 ? Date(timeIntervalSince1970: TimeInterval(minTs) / 1000.0) : nil

            let recentBuys = buys.suffix(10)
            if !recentBuys.isEmpty {
                let avgAmt = recentBuys.reduce(0.0) { $0 + $1.thb } / Double(recentBuys.count)
                if avgAmt > 0 {
                    DispatchQueue.main.async {
                        self.dailyDcaAmount = avgAmt
                    }
                }
            }

            // จัดเรียงออเดอร์ล่าสุดไว้บนสุด
            let sortedBuysDesc = buys.sorted(by: { $0.ts > $1.ts })
            let orderItems = sortedBuysDesc.prefix(15).map { b in
                DcaOrderItem(
                    date: Date(timeIntervalSince1970: TimeInterval(b.ts) / 1000.0),
                    thbAmount: b.thb,
                    rate: b.rate,
                    btcAmount: b.btc
                )
            }

            DispatchQueue.main.async {
                self.totalInvestedThb = totalThb
                self.dcaBtcAmount = totalBtc
                self.averageBuyPrice = avgPrice
                self.dcaOrderCount = buys.count
                self.dcaStartDate = startDate
                self.recentDcaOrders = Array(orderItems)
            }

            if let start = startDate {
                await fetchDcaComparisonAndHistoryAsync(startDate: start, buys: buys)
            }
        }
    }
}

// MARK: - Extensions & Formatting Helpers

extension Double {
    func formattedWithCommas(decimalPlaces: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Int {
    func formattedWithCommas() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Int64 {
    func formattedWithCommas() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

func formatShortThaiDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM"
    formatter.locale = Locale(identifier: "th_TH")
    return formatter.string(from: date)
}

func formatDcaOrderDate(_ date: Date) -> String {
    let cal = Calendar.current
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm"

    if cal.isDateInToday(date) {
        return "วันนี้ \(timeFormatter.string(from: date))"
    } else if cal.isDateInYesterday(date) {
        return "เมื่อวาน \(timeFormatter.string(from: date))"
    } else {
        let f = DateFormatter()
        f.locale = Locale(identifier: "th_TH")
        f.dateFormat = "d MMM HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Popover View (Glass Root)

struct PopoverView: View {
    @ObservedObject var store: BitkubStore
    var onResize: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 8) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 1.0, green: 0.62, blue: 0.04))

                Text("Bitkub DCA Tracker")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                if !store.apiKey.isEmpty {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color(red: 0.2, green: 0.85, blue: 0.45))
                            .frame(width: 5, height: 5)
                            .shadow(color: Color.green.opacity(0.6), radius: 2)
                        Text("LIVE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color(red: 0.2, green: 0.85, blue: 0.45))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
                    .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 0.8))
                }

                Spacer()

                Button(action: {
                    store.fetchAllData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .rotationEffect(.degrees(store.isRefreshing ? 360 : 0))
                        .animation(store.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: store.isRefreshing)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help("รีเฟรชข้อมูล")

                Button(action: {
                    store.showingSettings.toggle()
                }) {
                    Image(systemName: store.showingSettings ? "chart.line.uptrend.xyaxis" : "gearshape")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help(store.showingSettings ? "กลับหน้าหลัก" : "ตั้งค่า API")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()
                .opacity(0.15)

            if store.showingSettings {
                SettingsView(store: store)
            } else {
                DashboardView(store: store)
            }

            Divider()
                .opacity(0.15)

            // Footer Bar
            HStack {
                if let updated = store.lastUpdated {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 4, height: 4)
                        Text("อัปเดต \(updated.formatted(date: .omitted, time: .standard))")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.8))
                }

                Spacer()

                Button("ออกจากแอป") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 9.5))
                .foregroundColor(.white.opacity(0.65))
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.06)))
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
        }
        .frame(width: 360, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            ZStack {
                VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.06),
                        Color.white.opacity(0.01),
                        Color.black.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .onReceive(store.$showingSettings) { _ in
            DispatchQueue.main.async {
                onResize?()
            }
        }
        .onReceive(store.$selectedChartTab) { _ in
            DispatchQueue.main.async {
                onResize?()
            }
        }
        .onReceive(store.$thbBalance) { _ in
            DispatchQueue.main.async {
                onResize?()
            }
        }
    }
}

// MARK: - Dashboard View (Liquid Glass Design)

struct DashboardView: View {
    @ObservedObject var store: BitkubStore

    var body: some View {
        VStack(spacing: 9) {
            // ⚠️ LOW BALANCE ALERT BANNER (เมื่อเหลือ DCA <= 2 วัน)
            if store.isThbLow && !store.apiKey.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.orange)
                        .font(.callout)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("เงินบาทใน Bitkub ใกล้หมด!")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.orange)
                        Text("เหลือ ฿\(store.thbBalance.formattedWithCommas(decimalPlaces: 2)) (DCA ได้อีก ~\(store.dcaDaysLeft) วัน)")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    Spacer()
                    Link("เติมเงิน ↗", destination: URL(string: "https://www.bitkub.com/deposit/thb")!)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                        .overlay(Capsule().stroke(Color.orange.opacity(0.4), lineWidth: 1))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.12))
                        .background(Capsule().fill(Color.black.opacity(0.2)))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                )
            }

            // 1. HERO GLASS CARD: มูลค่าพอร์ต DCA & จำนวน Sats
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("มูลค่าพอร์ต DCA")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                    Spacer()
                    if let date = store.dcaStartDate {
                        Text("สะสม \(store.dcaOrderCount) ไม้ (เริ่ม \(formatShortThaiDate(date)))")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("฿\(store.dcaCurrentValue.formattedWithCommas(decimalPlaces: 2))")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    let profit = store.dcaProfitThb
                    let pct = store.dcaProfitPercent
                    let sign = profit >= 0 ? "+" : ""

                    // Glowing Glass Pill Profit Badge
                    HStack(spacing: 3) {
                        Image(systemName: profit >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(sign)\(pct, specifier: "%.2f")% (\(sign)฿\(profit.formattedWithCommas(decimalPlaces: 0)))")
                    }
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundColor(profit >= 0 ? Color(red: 0.3, green: 0.95, blue: 0.5) : Color(red: 1.0, green: 0.35, blue: 0.3))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((profit >= 0 ? Color.green : Color.red).opacity(0.18))
                    )
                    .overlay(
                        Capsule()
                            .stroke((profit >= 0 ? Color.green : Color.red).opacity(0.38), lineWidth: 1)
                    )
                    .fixedSize()
                }

                // ข้อมูล Sats สะสม และราคาไม้ล่าสุด (Pill Chips)
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                        Text("\(store.dcaSats.formattedWithCommas()) Sats")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.78, blue: 0.2))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(red: 1.0, green: 0.7, blue: 0.1).opacity(0.16)))
                    .overlay(Capsule().stroke(Color(red: 1.0, green: 0.7, blue: 0.1).opacity(0.35), lineWidth: 1))

                    if let latest = store.latestOrder {
                        HStack(spacing: 3) {
                            Text("ล่าสุด:")
                                .foregroundColor(.white.opacity(0.6))
                            Text("฿\(Int(latest.rate).formattedWithCommas())")
                                .foregroundColor(.white.opacity(0.95))
                        }
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
                    }
                }

                Text("ต้นทุนสะสม: ฿\(store.totalInvestedThb.formattedWithCommas(decimalPlaces: 2)) (~฿\(Int(store.dailyDcaAmount))/วัน)")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(10)
            .liquidGlass(cornerRadius: 12, fillOpacity: 0.12, borderOpacity: 0.3)

            // 2. 2 x 2 GLASS METRICS GRID
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                // 1. เงินสดคงเหลือ
                VStack(alignment: .leading, spacing: 3) {
                    Text("เงินสดคงเหลือ (THB)")
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                    Text("฿\(store.thbBalance.formattedWithCommas(decimalPlaces: 2))")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(store.isThbLow ? Color.orange : .white)

                    HStack(spacing: 3) {
                        if store.isThbLow {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 7))
                        }
                        Text("DCA ได้อีก ~\(store.dcaDaysLeft) วัน")
                            .font(.system(size: 8, weight: .semibold))
                    }
                    .foregroundColor(store.isThbLow ? Color.orange : .white.opacity(0.7))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(store.isThbLow ? Color.orange.opacity(0.18) : Color.white.opacity(0.08)))
                    .overlay(Capsule().stroke(store.isThbLow ? Color.orange.opacity(0.35) : Color.white.opacity(0.14), lineWidth: 0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .liquidGlass(cornerRadius: 10, fillOpacity: 0.08, borderOpacity: 0.2)

                // 2. Bitcoin ที่ถือครอง (Sats ⚡️)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Bitcoin ในกระเป๋า (Sats ⚡️)")
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                    Text("\(store.totalSats.formattedWithCommas()) Sats")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("≈ ฿\(store.totalPortfolioValue.formattedWithCommas(decimalPlaces: 0)) (\(store.effectiveBtc, specifier: "%.4f") BTC)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.07)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .liquidGlass(cornerRadius: 10, fillOpacity: 0.08, borderOpacity: 0.2)

                // 3. ราคาซื้อเฉลี่ย & ไม้ล่าสุด
                VStack(alignment: .leading, spacing: 3) {
                    Text("ราคาซื้อเฉลี่ยของคุณ")
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                    Text("฿\(Int(store.averageBuyPrice).formattedWithCommas())")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.15))

                    if let latest = store.latestOrder {
                        HStack(spacing: 3) {
                            Text("ไม้ล่าสุด ฿\(Int(latest.rate).formattedWithCommas())")
                                .font(.system(size: 8, weight: .medium))
                        }
                        .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red.opacity(0.001)).background(Capsule().fill(Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.14))))
                        .overlay(Capsule().stroke(Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.3), lineWidth: 0.8))
                    } else {
                        Text("ต่อ 1 BTC")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .liquidGlass(cornerRadius: 10, fillOpacity: 0.08, borderOpacity: 0.2)

                // 4. ราคาตลาดล่าสุด
                VStack(alignment: .leading, spacing: 3) {
                    Text("ราคาตลาดล่าสุด")
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                    Text("฿\(Int(store.lastPrice).formattedWithCommas())")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    HStack(spacing: 2) {
                        Image(systemName: store.percentChange >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 6.5))
                        Text("24h: \(store.percentChange >= 0 ? "+" : "")\(store.percentChange, specifier: "%.2f")%")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(store.percentChange >= 0 ? Color(red: 0.3, green: 0.95, blue: 0.5) : Color(red: 1.0, green: 0.35, blue: 0.3))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill((store.percentChange >= 0 ? Color.green : Color.red).opacity(0.16)))
                    .overlay(Capsule().stroke((store.percentChange >= 0 ? Color.green : Color.red).opacity(0.35), lineWidth: 0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .liquidGlass(cornerRadius: 10, fillOpacity: 0.08, borderOpacity: 0.2)
            }

            // 3. CHART & DAILY BUYS SECTION (Glass Pill Tabs)
            VStack(alignment: .leading, spacing: 6) {
                // Glass Pill Tab Selector
                HStack(spacing: 3) {
                    chartTabButton(title: "DCA vs เงินสด", index: 0)
                    chartTabButton(title: "ราคา 90 วัน", index: 1)
                    chartTabButton(title: "24 ชม.", index: 2)
                    chartTabButton(title: "ไม้รายวัน 📜", index: 3)
                }
                .padding(3)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().fill(Color.white.opacity(0.06)))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

                // TAB 0: DCA vs Cash Saved
                if store.selectedChartTab == 0 {
                    if !store.comparisonPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                HStack(spacing: 4) {
                                    Circle().fill(Color(red: 1.0, green: 0.65, blue: 0.15)).frame(width: 6, height: 6)
                                    Text("DCA: ฿\(Int(store.dcaCurrentValue).formattedWithCommas())")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "minus")
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("เงินสด: ฿\(Int(store.totalInvestedThb).formattedWithCommas())")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.75))
                                }
                            }

                            Chart {
                                ForEach(store.comparisonPoints) { pt in
                                    LineMark(
                                        x: .value("Date", pt.timestamp),
                                        y: .value("Value", pt.cashValue),
                                        series: .value("Type", "เงินสด")
                                    )
                                    .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                                    .foregroundStyle(Color.white.opacity(0.4))

                                    LineMark(
                                        x: .value("Date", pt.timestamp),
                                        y: .value("Value", pt.btcValue),
                                        series: .value("Type", "DCA")
                                    )
                                    .interpolationMethod(.monotone)
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                    .foregroundStyle(Color(red: 1.0, green: 0.65, blue: 0.15))

                                    AreaMark(
                                        x: .value("Date", pt.timestamp),
                                        yStart: .value("Cash", pt.cashValue),
                                        yEnd: .value("BTC", pt.btcValue)
                                    )
                                    .interpolationMethod(.monotone)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.green.opacity(0.35), Color.green.opacity(0.04)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                }
                            }
                            .chartYScale(domain: 0...(max(store.dcaCurrentValue, store.totalInvestedThb) * 1.1))
                            .chartXAxis(.hidden)
                            .chartYAxis {
                                AxisMarks(position: .trailing) { value in
                                    AxisValueLabel {
                                        if let v = value.as(Double.self) {
                                            Text("฿\(Int(v / 1000))k")
                                                .font(.system(size: 8, weight: .medium))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                }
                            }
                            .frame(height: 75)
                        }
                    } else {
                        VStack(spacing: 5) {
                            ProgressView().scaleEffect(0.65)
                            Text(store.apiKey.isEmpty ? "กรุณาใส่ API Key ในหน้าตั้งค่า" : "กำลังโหลดกราฟเปรียบเทียบ...")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(height: 75)
                    }
                } else if store.selectedChartTab == 1 {
                    // TAB 1: 90-Day Price Trend
                    if !store.priceHistoryDca.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("ราคา BTC 90 วัน")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("ต่ำสุด ฿\(Int(store.dcaMinPrice).formattedWithCommas()) • สูงสุด ฿\(Int(store.dcaMaxPrice).formattedWithCommas())")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Chart {
                                ForEach(store.priceHistoryDca) { point in
                                    LineMark(
                                        x: .value("Time", point.timestamp),
                                        y: .value("Price", point.price)
                                    )
                                    .interpolationMethod(.monotone)
                                    .foregroundStyle(Color(red: 1.0, green: 0.65, blue: 0.15))

                                    AreaMark(
                                        x: .value("Time", point.timestamp),
                                        yStart: .value("Low", store.dcaMinPrice),
                                        yEnd: .value("Price", point.price)
                                    )
                                    .interpolationMethod(.monotone)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.orange.opacity(0.3), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                }

                                if store.averageBuyPrice > 0 {
                                    RuleMark(y: .value("ต้นทุนเฉลี่ย", store.averageBuyPrice))
                                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                                        .foregroundStyle(Color.yellow)
                                        .annotation(position: .top, alignment: .leading) {
                                            Text("ต้นทุน ฿\(Int(store.averageBuyPrice).formattedWithCommas())")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(.yellow)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(Color.black.opacity(0.75)))
                                                .overlay(Capsule().stroke(Color.yellow.opacity(0.4), lineWidth: 0.8))
                                        }
                                }
                            }
                            .chartYScale(domain: store.dcaMinPrice...store.dcaMaxPrice)
                            .chartXAxis(.hidden)
                            .chartYAxis(.hidden)
                            .frame(height: 75)
                        }
                    } else {
                        VStack(spacing: 5) {
                            ProgressView().scaleEffect(0.65)
                            Text("กำลังโหลดแนวโน้มราคา...")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(height: 75)
                    }
                } else if store.selectedChartTab == 2 {
                    // TAB 2: 24h Short-term Chart
                    if !store.priceHistory24h.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("ราคา BTC 24 ชม.")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("ต่ำสุด ฿\(Int(store.low24hr).formattedWithCommas()) • สูงสุด ฿\(Int(store.high24hr).formattedWithCommas())")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Chart(store.priceHistory24h) { point in
                                LineMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("Price", point.price)
                                )
                                .interpolationMethod(.monotone)
                                .foregroundStyle(store.percentChange >= 0 ? Color.green : Color.red)

                                AreaMark(
                                    x: .value("Time", point.timestamp),
                                    yStart: .value("Low", store.low24hr),
                                    yEnd: .value("Price", point.price)
                                )
                                .interpolationMethod(.monotone)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            (store.percentChange >= 0 ? Color.green : Color.red).opacity(0.3),
                                            .clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                            .chartYScale(domain: store.low24hr...store.high24hr)
                            .chartXAxis(.hidden)
                            .chartYAxis(.hidden)
                            .frame(height: 75)
                        }
                    } else {
                        VStack(spacing: 5) {
                            ProgressView().scaleEffect(0.65)
                            Text("กำลังโหลดกราฟ 24 ชม....")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(height: 75)
                    }
                } else if store.selectedChartTab == 3 {
                    // TAB 3: ประวัติไม้ DCA รายวันล่าสุด
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("ประวัติไม้ DCA รายวัน")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            if !store.recentDcaOrders.isEmpty {
                                Text("ล่าสุด \(store.recentDcaOrders.count) ไม้ • ~฿\(Int(round(store.dailyDcaAmount)))/วัน")
                                    .font(.system(size: 8.5))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }

                        if store.recentDcaOrders.isEmpty {
                            VStack(spacing: 5) {
                                ProgressView().scaleEffect(0.65)
                                Text(store.apiKey.isEmpty ? "กรุณาใส่ API Key ในหน้าตั้งค่า" : "กำลังโหลดข้อมูลไม้ DCA...")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .frame(height: 75)
                        } else {
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 3.5) {
                                    ForEach(store.recentDcaOrders) { order in
                                        HStack(spacing: 6) {
                                            // วันที่และเวลา
                                            Text(formatDcaOrderDate(order.date))
                                                .font(.system(size: 9.5, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(minWidth: 72, alignment: .leading)

                                            Spacer()

                                            // ราคาซื้อต่อ BTC
                                            Text("@ ฿\(Int(order.rate).formattedWithCommas())")
                                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                                .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))

                                            // Sats ที่ได้รับ
                                            HStack(spacing: 2) {
                                                Text("+\(order.satsAmount.formattedWithCommas())")
                                                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                                Text("Sats")
                                                    .font(.system(size: 8, weight: .medium))
                                                Image(systemName: "bolt.fill")
                                                    .font(.system(size: 7))
                                            }
                                            .foregroundColor(Color(red: 0.3, green: 0.95, blue: 0.5))
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 2.5)
                                            .background(Capsule().fill(Color.green.opacity(0.16)))
                                            .overlay(Capsule().stroke(Color.green.opacity(0.35), lineWidth: 0.8))
                                        }
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 3.5)
                                        .background(Capsule().fill(Color.white.opacity(0.06)))
                                        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.8))
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                            .frame(height: 75)
                        }
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func chartTabButton(title: String, index: Int) -> some View {
        Button(action: { store.selectedChartTab = index }) {
            Text(title)
                .font(.system(size: 9.5, weight: store.selectedChartTab == index ? .bold : .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(store.selectedChartTab == index ? Color.white.opacity(0.2) : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(store.selectedChartTab == index ? Color.white.opacity(0.35) : Color.clear, lineWidth: 1)
                )
                .foregroundColor(store.selectedChartTab == index ? .white : .white.opacity(0.6))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var store: BitkubStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ตั้งค่า Bitkub API")
                .font(.headline)
                .foregroundColor(.white)

            Text("เปิดสิทธิ์เฉพาะ Read / Wallet เท่านั้น เพื่อความปลอดภัย (ไม่ต้องเปิดสิทธิ์ Trade หรือ Withdraw)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text("API Key")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
                TextField("ใส่ Bitkub API Key", text: $store.apiKeyInput)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API Secret")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
                SecureField("ใส่ Bitkub API Secret", text: $store.apiSecretInput)
                    .textFieldStyle(.roundedBorder)
            }

            Divider()
                .opacity(0.15)

            VStack(alignment: .leading, spacing: 4) {
                Text("เตือนเมื่อเงินบาทเหลือ DCA ได้ต่ำกว่ากี่วัน:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
                HStack {
                    TextField("2", text: $store.thresholdInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                    Text("วัน (ปัจจุบันเหลือ ~\(store.dcaDaysLeft) วัน)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.65))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("แสดงข้อมูลบน Menu Bar:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))

                HStack(spacing: 4) {
                    barModeButton(title: "💰 เงินในพอร์ต", mode: 0)
                    barModeButton(title: "📈 ราคาวันนี้", mode: 1)
                }
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().fill(Color.white.opacity(0.06)))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .allowsHitTesting(false)
                )
            }

            Toggle(isOn: Binding(
                get: { store.showDcaProfitOnBar },
                set: { _ in store.toggleBarDisplayMode() }
            )) {
                Text("แสดงเป็น % กำไร DCA (แทน % ตลาด 24 ชม.)")
                    .font(.caption)
                    .foregroundColor(store.barDisplayMode == 0 ? .white.opacity(0.85) : .white.opacity(0.35))
            }
            .disabled(store.barDisplayMode != 0)

            Divider()
                .opacity(0.15)

            HStack(spacing: 8) {
                Button(action: {
                    store.saveCredentials()
                }) {
                    Text("บันทึกข้อมูล")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.accentColor))
                        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)

                if store.saveSuccess {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark")
                        Text("บันทึกสำเร็จ!")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.green.opacity(0.15)))
                    .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 0.8))
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
    }

    private func barModeButton(title: String, mode: Int) -> some View {
        Button(action: {
            store.setBarDisplayMode(mode)
        }) {
            Text(title)
                .font(.system(size: 10.5, weight: store.barDisplayMode == mode ? .bold : .medium))
                .foregroundColor(store.barDisplayMode == mode ? .white : .white.opacity(0.65))
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(store.barDisplayMode == mode ? Color.white.opacity(0.24) : Color.white.opacity(0.001))
                )
                .overlay(
                    Capsule()
                        .stroke(store.barDisplayMode == mode ? Color.white.opacity(0.38) : Color.clear, lineWidth: 1)
                        .allowsHitTesting(false)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NSApplication & AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var hostingController: NSHostingController<PopoverView>!
    var store = BitkubStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "₿ กำลังโหลด..."
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        let popoverView = PopoverView(store: store, onResize: { [weak self] in
            self?.updatePopoverSize()
        })
        hostingController = NSHostingController(rootView: popoverView)

        popover = NSPopover()
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .vibrantDark)
        popover.contentViewController = hostingController

        updatePopoverSize()

        store.onUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.updateStatusBarLabel()
                self?.updatePopoverSize()
            }
        }

        updateStatusBarLabel()
    }

    func updatePopoverSize() {
        guard let hc = hostingController else { return }
        let targetSize = hc.sizeThatFits(in: NSSize(width: 360, height: CGFloat.greatestFiniteMagnitude))
        let targetHeight = max(510, ceil(targetSize.height))
        if popover.contentSize.height != targetHeight {
            popover.contentSize = NSSize(width: 360, height: targetHeight)
        }
    }

    private func updateStatusBarLabel() {
        guard let button = statusItem.button else { return }

        let alertPrefix = (store.isThbLow && !store.apiKey.isEmpty) ? "⚠️ " : ""

        if store.barDisplayMode == 1 {
            // โหมดแสดงราคาวันนี้ (Market Price)
            if store.lastPrice > 0 {
                let sign = store.percentChange >= 0 ? "▲" : "▼"
                let pct = String(format: "%.1f", abs(store.percentChange))
                let priceStr = Int(store.lastPrice).formattedWithCommas()
                button.title = "\(alertPrefix)₿ ฿\(priceStr) \(sign)\(pct)%"
            } else {
                button.title = "\(alertPrefix)₿ ..."
            }
        } else {
            // โหมดแสดงจำนวนเงินในพอร์ต (Portfolio Value)
            let totalThb = store.totalPortfolioValue
            let thbStr = Int(totalThb).formattedWithCommas()

            if store.showDcaProfitOnBar && store.totalInvestedThb > 0 {
                let pct = store.dcaProfitPercent
                let sign = pct >= 0 ? "+" : ""
                button.title = "\(alertPrefix)₿ ฿\(thbStr) (\(sign)\(String(format: "%.1f", pct))%)"
            } else if store.effectiveBtc > 0 {
                let sign = store.percentChange >= 0 ? "▲" : "▼"
                let pct = String(format: "%.1f", abs(store.percentChange))
                button.title = "\(alertPrefix)₿ ฿\(thbStr) \(sign)\(pct)%"
            } else if store.lastPrice > 0 {
                let sign = store.percentChange >= 0 ? "▲" : "▼"
                let pct = String(format: "%.1f", abs(store.percentChange))
                let priceStr = Int(store.lastPrice).formattedWithCommas()
                button.title = "\(alertPrefix)₿ ฿\(priceStr) \(sign)\(pct)%"
            } else {
                button.title = "\(alertPrefix)₿ ..."
            }
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            updatePopoverSize()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

// MARK: - Main Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
