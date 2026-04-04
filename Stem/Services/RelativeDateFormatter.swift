import Foundation

enum RelativeDate {
    // Cached formatters (DateFormatter is expensive to create)
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatterBasic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let monthDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let monthDayYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private static let dayNameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    static func format(_ dateString: String) -> String {
        guard let date = parse(dateString) else { return dateString }
        return format(date)
    }

    static func format(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)

        if seconds < 60 { return "just now" }
        if seconds < 3600 {
            let m = Int(seconds / 60)
            return "\(m)m ago"
        }
        if seconds < 86400 {
            let h = Int(seconds / 3600)
            return "\(h)h ago"
        }
        if seconds < 172800 { return "yesterday" }
        if seconds < 604800 {
            let d = Int(seconds / 86400)
            return "\(d)d ago"
        }

        let formatter = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? monthDayFormatter
            : monthDayYearFormatter
        return formatter.string(from: date)
    }

    static func timePeriod(for dateString: String) -> String {
        guard let date = parse(dateString) else { return "Earlier" }
        return timePeriod(for: date)
    }

    static func timePeriod(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day ?? 999
        if daysAgo < 7 {
            return dayNameFormatter.string(from: date)
        }
        return "Earlier"
    }

    private static func parse(_ string: String) -> Date? {
        isoFormatter.date(from: string) ?? isoFormatterBasic.date(from: string)
    }
}
