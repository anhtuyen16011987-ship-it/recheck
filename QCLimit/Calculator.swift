import Foundation

typealias Pairs = [(Double, Double)]

struct LimitRow: Identifiable {
    let id: Int
    let name: String
    let role: String
    let minV: Double
    let maxV: Double
}

enum Calc {
    static let stages = [("cutting", "Sau Cutting"), ("rw", "Sau RW là")]
    static let yarns = ["Nylon - FI", "Nylon - RO", "Pet FI & RO"]
    static let dirs = ["Warp", "Weft"]
    static let kinds = ["CUT", "DỆT"]

    private static func e(_ cut: Pairs, _ det: Pairs? = nil) -> [String: Pairs] {
        ["CUT": cut, "DỆT": det ?? cut]
    }

    // [stage][yarn][direction][kind] -> hệ số (trừ, cộng) cho A, B, C
    static let table: [String: [String: [String: [String: Pairs]]]] = [
        "cutting": [
            "Nylon - FI": [
                "Warp": e([(0.5, 0.9), (0.6, 1)], [(0.5, 0.9), (0.7, 1)]),
                "Weft": e([(0.8, 0.7), (1, 0.8)], [(0.9, 0.7), (1, 0.8)])
            ],
            "Nylon - RO": [
                "Warp": e([(0.5, 0.9), (0.5, 1)], [(0.5, 0.9), (0.7, 1)]),
                "Weft": e([(0.8, 0.7), (1, 0.8)])
            ],
            "Pet FI & RO": [
                "Warp": e([(0.5, 0.9), (0.9, 1)]),
                "Weft": e([(0.8, 0.8), (1, 0.9)], [(0.9, 0.8), (1, 0.9)])
            ]
        ],
        "rw": [
            "Nylon - FI": [
                "Warp": e([(0.5, 0.8), (0.6, 0.9), (0.7, 1)]),
                "Weft": e([(0.8, 0.6), (1, 0.7), (1, 0.8)])
            ],
            "Nylon - RO": [
                "Warp": e([(0.5, 0.8), (0.6, 0.9), (0.7, 1)]),
                "Weft": e([(0.8, 0.6), (0.9, 0.7), (1, 0.8)])
            ],
            "Pet FI & RO": [
                "Warp": e([(0.5, 0.8), (0.8, 0.9), (0.9, 1)]),
                "Weft": e([(0.8, 0.8), (0.9, 0.9), (1, 1)])
            ]
        ]
    ]

    // Làm tròn như Excel: phần lẻ 0-0.3 -> .0 ; 0.4-0.6 -> .5 ; 0.7-0.9 -> +1
    static func roundExcel(_ v: Double) -> Double {
        let r = (v * 1000).rounded() / 1000
        let n = r.rounded(.towardZero)
        let d = Int(((r - n) * 10 + 1e-6).rounded(.down))
        return n + (d <= 3 ? 0 : (d <= 6 ? 0.5 : 1))
    }

    static func limits(std s: Double, tol t: Double, stage: String, yarn: String, dir: String, kind: String) -> [LimitRow] {
        guard let pairs = table[stage]?[yarn]?[dir]?[kind] else { return [] }
        let names = ["A", "B", "C"]
        let roles = ["Worker", "Subleader", "Section Leader"]
        return pairs.enumerated().map { i, p in
            LimitRow(id: i, name: names[i], role: roles[i],
                     minV: roundExcel(s - t * p.0), maxV: roundExcel(s + t * p.1))
        }
    }

    static func fmt(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}
