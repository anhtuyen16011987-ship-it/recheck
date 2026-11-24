import Foundation

enum Parser {
    static let U: [String: Int] = ["khong": 0, "mot": 1, "hai": 2, "ba": 3, "bon": 4, "tu": 4,
                                   "nam": 5, "lam": 5, "sau": 6, "bay": 7, "tam": 8, "chin": 9]

    static func normalize(_ s: String) -> String {
        var x = s.lowercased().replacingOccurrences(of: "đ", with: "d")
        x = x.folding(options: .diacriticInsensitive, locale: Locale(identifier: "vi"))
        for sym in ["±", "+/-", "+-"] { x = x.replacingOccurrences(of: sym, with: " tru ") }
        // "19 chấm 5" / "19 phẩy 5" -> "19.5"
        x = x.replacingOccurrences(of: "(\\d)\\s*(?:cham|phay)\\s*(\\d)", with: "$1.$2", options: .regularExpression)
        return x
    }

    static func words(_ w: [String]) -> Double? {
        if w.isEmpty { return nil }
        // "mười chín chấm năm" / "hai mươi phẩy năm"
        if let i = w.firstIndex(where: { $0 == "cham" || $0 == "phay" }) {
            guard i > 0, let ip = words(Array(w[..<i])) else { return nil }
            let fr: [String] = w[(i + 1)...].compactMap { t in
                if let u = U[t] { return String(u) }
                return t.allSatisfy({ $0.isNumber }) ? t : nil
            }
            guard !fr.isEmpty, fr.count == w.count - i - 1 else { return nil }
            return Double("\(Int(ip)).\(fr.joined())")
        }
        if w.count > 1, w.allSatisfy({ U[$0] != nil }) {
            return Double(w.map { String(U[$0]!) }.joined())
        }
        var total = 0.0, group = 0.0, cur = 0.0, seen = false
        for x in w {
            switch x {
            case "muoi": group += (cur == 0 ? 1 : cur) * 10; cur = 0; seen = true
            case "tram": group += cur * 100; cur = 0; seen = true
            case "nghin", "ngan":
                let g = group + cur
                total += (g == 0 ? 1 : g) * 1000; group = 0; cur = 0; seen = true
            case "le", "linh", "va": break
            case "ruoi": cur += 0.5
            default:
                if let u = U[x] { cur = Double(u); seen = true } else { return nil }
            }
        }
        return seen ? total + group + cur : nil
    }

    static func fix(_ n: String, thousands: Bool) -> String {
        var s = n
        if thousands, s.range(of: "^[1-9]\\d{0,2}[.,]\\d{3}$", options: .regularExpression) != nil {
            s = s.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")
        }
        return s.replacingOccurrences(of: ",", with: ".")
    }

    static func clean(_ d: Double) -> String {
        d == d.rounded() ? String(Int(d)) : String(d)
    }

    /// Trả về (STD, dung sai) nếu nhận ra được.
    static func parse(_ text: String) -> (String, String)? {
        let x = normalize(text)

        // 1) Điện thoại đã đổi thành chữ số: "1914 cộng trừ 20"
        if let re = try? NSRegularExpression(pattern: "\\d+(?:[.,]\\d+)?") {
            let ns = x as NSString
            let m = re.matches(in: x, range: NSRange(location: 0, length: ns.length))
                .map { ns.substring(with: $0.range) }
            if m.count >= 2 { return (fix(m[0], thousands: true), fix(m[1], thousands: false)) }
        }

        // 2) Đọc bằng chữ: "một chín một bốn trừ hai mươi"
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789., ")
        let cleaned = String(x.map { allowed.contains($0) ? $0 : " " })
        let tk = cleaned.split(separator: " ").map(String.init)
        var sp = tk.indices.first(where: { $0 > 0 && tk[$0] == "tru" })
        if sp == nil { sp = tk.indices.first(where: { $0 > 0 && tk[$0] == "cong" }) }
        guard let k = sp else { return nil }
        let skip: Set<String> = ["std", "kich", "thuoc", "chuan", "dung", "sai", "cong", "tru"]
        let left = tk[..<k].filter { !skip.contains($0) }
        let right = tk[(k + 1)...].filter { !skip.contains($0) }
        if let a = words(Array(left)), let b = words(Array(right)) {
            return (clean(a), clean(b))
        }
        return nil
    }
}
