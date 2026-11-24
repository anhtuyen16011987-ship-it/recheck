import SwiftUI

struct ContentView: View {
    @StateObject private var speech = SpeechManager()
    @AppStorage("std") private var std = "1914"
    @AppStorage("tol") private var tol = "20"
    @AppStorage("stage") private var stage = "cutting"
    @AppStorage("yarn") private var yarn = "Nylon - FI"
    @AppStorage("dir") private var dir = "Warp"
    @AppStorage("kind") private var kind = "CUT"

    private var rows: [LimitRow] {
        guard let s = Double(std.replacingOccurrences(of: ",", with: ".")),
              let t = Double(tol.replacingOccurrences(of: ",", with: ".")),
              s > 0, t >= 0 else { return [] }
        return Calc.limits(std: s, tol: t, stage: stage, yarn: yarn, dir: dir, kind: kind)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("QC LIMIT").font(.title2.bold()).frame(maxWidth: .infinity, alignment: .leading)

                Button { speech.toggle() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: speech.isListening ? "waveform" : "mic.fill").font(.title2)
                        Text(speech.isListening ? "ĐANG NGHE… CHẠM ĐỂ DỪNG" : "CHẠM ĐỂ ĐỌC STD + DUNG SAI")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(speech.isListening ? Color.red : Color(red: 0.06, green: 0.16, blue: 0.26))
                    .foregroundColor(.white).cornerRadius(14)
                }
                Text(speech.status).font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center)

                HStack(spacing: 10) {
                    field("STD", $std)
                    field("Dung sai ±", $tol)
                }

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        picker("Công đoạn", $stage, Calc.stages.map { ($0.0, $0.1) })
                        picker("Yarn Group", $yarn, Calc.yarns.map { ($0, $0) })
                    }
                    HStack(spacing: 10) {
                        picker("Hướng sợi", $dir, Calc.dirs.map { ($0, $0) })
                        picker("Kiểu", $kind, Calc.kinds.map { ($0, $0) })
                    }
                }

                VStack(spacing: 8) {
                    ForEach(rows) { r in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(r.name).font(.title2.bold())
                                Text(r.role).font(.caption2).foregroundColor(.secondary)
                            }.frame(width: 90, alignment: .leading)
                            value("MIN (−)", r.minV)
                            value("MAX (+)", r.maxV)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground)).cornerRadius(12)
                    }
                    if rows.isEmpty {
                        Text("Nhập STD lớn hơn 0 và dung sai không âm.").font(.footnote).foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            speech.onText = { text in
                if let (a, b) = Parser.parse(text) { std = a; tol = b; return true }
                return false
            }
        }
    }

    private func field(_ title: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundColor(.secondary)
            TextField("", text: text).keyboardType(.decimalPad).font(.title.bold())
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground)).cornerRadius(12)
    }

    private func picker(_ title: String, _ sel: Binding<String>, _ items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Picker(title, selection: sel) {
                ForEach(items, id: \.0) { Text($0.1).tag($0.0) }
            }
            .pickerStyle(.menu).labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground)).cornerRadius(12)
    }

    private func value(_ title: String, _ v: Double) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption2).foregroundColor(.secondary)
            Text(Calc.fmt(v)).font(.title2.bold()).foregroundColor(.green)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
