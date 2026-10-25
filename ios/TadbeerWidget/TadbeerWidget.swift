import SwiftUI
import WidgetKit

// Home-screen widget: the ayah of the day and the khatma's progress.
// The app (HomeWidgetSync in Dart) stores the next 30 days of ayahs in the
// shared app group, so the widget shows today's without the app running.

private let appGroup = "group.com.tadbeer.app"
private let gold = Color(red: 0.79, green: 0.64, blue: 0.35)
private let navyTop = Color(red: 0.08, green: 0.15, blue: 0.25)
private let navyBottom = Color(red: 0.12, green: 0.23, blue: 0.37)

struct TadbeerEntry: TimelineEntry {
    let date: Date
    let title: String
    let ayah: String
    let reference: String
    let khatma: (title: String, progress: Int, left: Int, portion: Int, label: String)?
}

struct TadbeerProvider: TimelineProvider {
    private static let dayFormat: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func placeholder(in context: Context) -> TadbeerEntry {
        TadbeerEntry(date: Date(), title: "آية اليوم", ayah: "", reference: "", khatma: nil)
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
        var ayah = ("", "")
        if let json = data?.string(forKey: "ayahs")?.data(using: .utf8),
           let list = try? JSONSerialization.jsonObject(with: json) as? [[String: String]] {
            // Today's ayah, or the latest stored one past the stored days.
            let match = list.first { $0["d"] == today } ?? list.last { ($0["d"] ?? "") < today } ?? list.first
            ayah = (match?["t"] ?? "", match?["r"] ?? "")
        }
        var khatma: (String, Int, Int, Int, String)?
        if data?.bool(forKey: "has_khatma") == true {
            let portion = data?.integer(forKey: "portion") ?? 0
            let read = data?.string(forKey: "read_day") == today ? (data?.integer(forKey: "read_today") ?? 0) : 0
            khatma = (
                data?.string(forKey: "khatma_title") ?? "",
                data?.integer(forKey: "khatma_progress") ?? 0,
                max(portion - read, 0),
                portion,
                data?.string(forKey: "portion_label") ?? ""
            )
        }
        return TadbeerEntry(
            date: date,
            title: data?.string(forKey: "title") ?? "آية اليوم",
            ayah: ayah.0,
            reference: ayah.1,
            khatma: khatma
        )
    }
}

struct TadbeerWidgetView: View {
    let entry: TadbeerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.title).font(.caption.bold()).foregroundColor(gold)
            Text(entry.ayah)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(5)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(entry.reference).font(.caption2).foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
            if let k = entry.khatma {
                HStack {
                    Text(k.title).font(.caption2.bold()).foregroundColor(.white)
                    Spacer()
                    Text("\(k.progress)٪").font(.caption2.bold()).foregroundColor(gold)
                }
                ProgressView(value: Double(k.progress), total: 100).tint(gold)
                Text("\(k.label): \(k.left) / \(k.portion)").font(.caption2).foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(14)
        .environment(\.layoutDirection, .rightToLeft)
        .widgetBackground(LinearGradient(colors: [navyTop, navyBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
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
