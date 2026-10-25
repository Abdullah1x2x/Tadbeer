import SwiftUI
import WidgetKit

// Home-screen widget: the ayah of the day and the khatma's progress.
// The app (HomeWidgetSync in Dart) stores the next 30 days of ayahs in the
// shared app group, so the widget shows today's without the app running.

private let appGroup = "group.com.tadbeer.app"
private let gold = Color(red: 0.89, green: 0.76, blue: 0.48)
private let navyTop = Color(red: 0.08, green: 0.15, blue: 0.25)
private let navyBottom = Color(red: 0.12, green: 0.23, blue: 0.37)

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
            reference: "", image: nil, verse: "", reflectLabel: "تدبّرها", khatma: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TadbeerEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TadbeerEntry>) -> Void) {
        // One entry now and one at each of the next midnights.
        let calendar = Calendar.current
        var dates = [Date()]
        for day in 1...7 {
            if let d = calendar.date(byAdding: .day, value: day, to: calendar.startOfDay(for: Date())) {
                dates.append(d)
            }
        }
        completion(Timeline(entries: dates.map(entry(for:)), policy: .atEnd))
    }

    private func entry(for date: Date) -> TadbeerEntry {
        let data = UserDefaults(suiteName: appGroup)
        let today = Self.dayFormat.string(from: date)
        var ayah: [String: Any] = [:]
        if let json = data?.string(forKey: "ayahs")?.data(using: .utf8),
           let list = try? JSONSerialization.jsonObject(with: json) as? [[String: Any]] {
            // Today's ayah, or the latest stored one past the stored days.
            ayah = list.first { $0["d"] as? String == today }
                ?? list.last { ($0["d"] as? String ?? "") < today }
                ?? list.first ?? [:]
        }
        let image = (data?.string(forKey: "img_\(today)")).flatMap { UIImage(contentsOfFile: $0) }
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
        .widgetBackground(Glass())
    }
}

/// Frosted glass: a translucent navy tint, a sheen across the top and a thin
/// light edge. WidgetKit cannot blur the wallpaper, so depth comes from these.
struct Glass: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [navyTop.opacity(0.92), navyBottom.opacity(0.85)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
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
