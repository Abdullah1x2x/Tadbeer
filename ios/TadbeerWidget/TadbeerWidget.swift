import SwiftUI
import WidgetKit

// Home-screen widget: an ayah that changes every quarter hour, on frosted
// glass in the app's colour theme, and the khatma's progress.
// The app (HomeWidgetSync in Dart) stores an ayah for each quarter hour of
// the next two days in the shared app group, so the widget keeps changing
// without the app running.

private let appGroup = "group.com.tadbeer.app"
private let gold = Color(red: 0.89, green: 0.76, blue: 0.48)
private let navyTop = Color(red: 0.08, green: 0.15, blue: 0.25)

struct TadbeerEntry: TimelineEntry {
    let date: Date
    let title: String
    let ayah: String
    let reference: String
    /// The ayah drawn by the app in the Quranic font, when available.
    let image: UIImage?
    /// The tadbeer:// query naming the ayah ("s=2&a=255"). Links also carry
    /// `homeWidget`, which home_widget needs on iOS to report the tap.
    let verse: String
    let reflectLabel: String
    /// The app's colour theme, which tints the glass.
    let theme: String
    let khatma: (title: String, progress: Int, portion: String, readLabel: String)?
}

struct TadbeerProvider: TimelineProvider {
    private static let dayFormat: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func placeholder(in context: Context) -> TadbeerEntry {
        TadbeerEntry(
            date: Date(), title: "آية اليوم", ayah: "أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ",
            reference: "", image: nil, verse: "", reflectLabel: "تدبّرها", theme: "navy", khatma: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TadbeerEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TadbeerEntry>) -> Void) {
        // One entry now and one at the start of each of the next 24 quarter
        // hours; WidgetKit asks again when they run out.
        let calendar = Calendar.current
        let now = Date()
        var dates = [now]
        var start = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        start.minute = (start.minute ?? 0) / 15 * 15
        if let quarterStart = calendar.date(from: start) {
            for step in 1...24 {
                if let d = calendar.date(byAdding: .minute, value: 15 * step, to: quarterStart) {
                    dates.append(d)
                }
            }
        }
        completion(Timeline(entries: dates.map(entry(for:)), policy: .atEnd))
    }

    /// Quarter hours since 2020-01-01 in local time, as the app counts them
    /// (HomeWidgetSync.quarterOf).
    private static func quarter(of date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let day = utc.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day))!
        let epoch = utc.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        let days = utc.dateComponents([.day], from: epoch, to: day).day ?? 0
        return days * 96 + (parts.hour ?? 0) * 4 + (parts.minute ?? 0) / 15
    }

    private func entry(for date: Date) -> TadbeerEntry {
        let data = UserDefaults(suiteName: appGroup)
        let today = Self.dayFormat.string(from: date)
        var ayah: [String: Any] = [:]
        if let json = data?.string(forKey: "ayahs")?.data(using: .utf8),
           let list = try? JSONSerialization.jsonObject(with: json) as? [[String: Any]],
           !list.isEmpty {
            // This quarter's ayah, or past the stored quarters one of them in
            // turn, so the widget keeps changing until the app refreshes it.
            let quarter = Self.quarter(of: date)
            if let match = list.first(where: { $0["q"] as? Int == quarter }) {
                ayah = match
            } else {
                let first = list[0]["q"] as? Int ?? quarter
                let n = list.count
                ayah = list[((quarter - first) % n + n) % n]
            }
        }
        let image = (data?.string(forKey: "img_\(ayah["s"] as? Int ?? 0)_\(ayah["a"] as? Int ?? 0)"))
            .flatMap { UIImage(contentsOfFile: $0) }
        let arabic = (data?.string(forKey: "title") ?? "آ").unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) }
        let number = { (n: Int) -> String in
            let f = NumberFormatter()
            f.locale = Locale(identifier: arabic ? "ar" : "en")
            return f.string(from: NSNumber(value: n)) ?? "\(n)"
        }
        var khatma: (String, Int, String, String)?
        if data?.bool(forKey: "has_khatma") == true {
            let portion = data?.integer(forKey: "portion") ?? 0
            let read = data?.string(forKey: "read_day") == today ? (data?.integer(forKey: "read_today") ?? 0) : 0
            let left = max(portion - read, 0)
            var text = left == 0
                ? (data?.string(forKey: "portion_done") ?? "")
                : (data?.string(forKey: "portion_template") ?? "")
                    .replacingOccurrences(of: "{left}", with: number(left))
                    .replacingOccurrences(of: "{portion}", with: number(portion))
            if let page = data?.string(forKey: "khatma_page"), !page.isEmpty { text += " · \(page)" }
            khatma = (
                data?.string(forKey: "khatma_title") ?? "",
                data?.integer(forKey: "khatma_progress") ?? 0,
                text,
                data?.string(forKey: "read_label") ?? ""
            )
        }
        return TadbeerEntry(
            date: date,
            title: data?.string(forKey: "title") ?? "آية اليوم",
            ayah: ayah["t"] as? String ?? "",
            reference: ayah["r"] as? String ?? "",
            image: image,
            verse: "s=\(ayah["s"] as? Int ?? 0)&a=\(ayah["a"] as? Int ?? 0)",
            reflectLabel: data?.string(forKey: "reflect_label") ?? "تدبّرها",
            theme: data?.string(forKey: "theme") ?? "navy",
            khatma: khatma
        )
    }
}

struct TadbeerWidgetView: View {
    let entry: TadbeerEntry

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(entry.title).font(.caption.bold()).foregroundColor(gold)
                Spacer()
                Link(destination: URL(string: "tadbeer://reflect?\(entry.verse)&homeWidget")!) {
                    Text(entry.reflectLabel).font(.caption2).foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.15)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                }
            }
            Link(destination: URL(string: "tadbeer://ayah?\(entry.verse)&homeWidget")!) {
                Group {
                    if let image = entry.image {
                        Image(uiImage: image).resizable().scaledToFit()
                    } else {
                        Text(entry.ayah).font(.system(size: 16)).foregroundColor(.white)
                            .multilineTextAlignment(.center).minimumScaleFactor(0.6)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Text(entry.reference).font(.caption2).foregroundColor(.white.opacity(0.7))
            if let k = entry.khatma {
                Ornament().frame(height: 10).padding(.vertical, 2)
                HStack(spacing: 10) {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 4)
                        Circle().trim(from: 0, to: CGFloat(k.progress) / 100)
                            .stroke(gold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(k.progress)٪").font(.system(size: 10, weight: .bold)).foregroundColor(gold)
                    }
                    .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(k.title).font(.caption2.bold()).foregroundColor(.white)
                        Text(k.portion).font(.system(size: 10)).foregroundColor(.white.opacity(0.8)).lineLimit(2)
                    }
                    Spacer()
                    Link(destination: URL(string: "tadbeer://khatma?homeWidget")!) {
                        Text(k.readLabel).font(.caption2.bold()).foregroundColor(navyTop)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(LinearGradient(colors: [gold.opacity(0.85), gold], startPoint: .leading, endPoint: .trailing)))
                    }
                }
            }
        }
        .padding(14)
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "tadbeer://home?homeWidget"))
        .widgetBackground(Glass(theme: entry.theme))
    }
}

/// Frosted glass in the app's colour theme: the theme's dark hero colours
/// (lib/app/theme.dart), a sheen across the top and a thin light edge.
/// WidgetKit cannot blur the wallpaper, so depth comes from these.
struct Glass: View {
    let theme: String

    private static let colours: [String: (Color, Color)] = [
        "navy": (Color(hex: 0x1E3A5F), Color(hex: 0x0F1D33)),
        "emerald": (Color(hex: 0x1E5B47), Color(hex: 0x0E2A20)),
        "burgundy": (Color(hex: 0x6A2633), Color(hex: 0x2E1218)),
        "brown": (Color(hex: 0x5E442C), Color(hex: 0x261B12)),
        "teal": (Color(hex: 0x115E67), Color(hex: 0x08282C)),
    ]

    var body: some View {
        let (start, end) = Self.colours[theme] ?? Self.colours["navy"]!
        ZStack {
            LinearGradient(colors: [end, start],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [gold.opacity(0.35), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 160)
            LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.05), .clear],
                           startPoint: .top, endPoint: .center)
            RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.28), lineWidth: 1)
        }
    }
}

/// Gold line with an eight-pointed star in the middle, as in the app.
struct Ornament: View {
    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(gold.opacity(0.5)).frame(height: 0.8)
            Image(systemName: "staroflife.fill").font(.system(size: 8)).foregroundColor(gold)
            Rectangle().fill(gold.opacity(0.5)).frame(height: 0.8)
        }
        .frame(maxWidth: 160)
    }
}

private extension View {
    @ViewBuilder
    func widgetBackground<B: View>(_ background: B) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { background }
        } else {
            self.background(background)
        }
    }
}

@main
struct TadbeerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TadbeerWidget", provider: TadbeerProvider()) { entry in
            TadbeerWidgetView(entry: entry)
        }
        .configurationDisplayName("تَدْبِير")
        .description("آية اليوم وتقدّم ختمتك")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
