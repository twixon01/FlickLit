//
//  StatsView.swift
//  FlickLit21-l
//
//  Created by Ilya Nestrogaev on 05.03.2025.
//

import SwiftUI
import Charts

struct StatsView: View {
    @StateObject private var vm = StatsViewModel()
    @State private var availableYears: [Int] = []
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private let monthAbbr = ["J","F","M","A","M","J","J","A","S","O","N","D"]

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vm.nickname)'S")
                    .font(.custom("SFProDisplay-Black", size: 40))
                Text("STATS")
                    .font(.custom("SFProDisplay-Black", size: 40))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("BackgroundGray"))

            VStack(alignment: .leading, spacing: 2) {
                Text("By month")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(selectedYear)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Диаграмма по годам
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(height: 208)
                } else if let err = vm.error {
                    Text("Ошибка: \(err)")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, minHeight: 208)
                } else if let stats = vm.stats {
                    TabView(selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            ChartViewForYear(
                                year: year,
                                countsByWeek: stats.countsByWeek,
                                monthAbbr: monthAbbr
                            )
                            .tag(year)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 208)
                    .onAppear {
                        let years = Set(stats.countsByWeek.keys.compactMap { key in
                            key.split(separator: "-W").first.flatMap { Int($0) }
                        })
                        availableYears = years.sorted(by: >)
                        if !availableYears.contains(selectedYear) {
                            selectedYear = availableYears.first ?? selectedYear
                        }
                    }
                }
            }

            // Pie chart по типам
            if let stats = vm.stats {
                Text("By type")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                Chart {
                    ForEach(sortedTypes(from: stats.countsByType), id: \.type) { entry in
                        SectorMark(
                            angle: .value(entry.type, entry.count),
                            innerRadius: .ratio(0.5),
                            outerRadius: .ratio(1.0)
                        )
                        .foregroundStyle(color(for: entry.type))
                    }
                }
                .frame(height: 180)
                .padding(.horizontal, 16)

                HStack {
                    VStack(spacing: 4) {
                        Text("\(stats.countsByType.values.reduce(0, +))")
                            .font(.title2).bold().foregroundColor(.white)
                        Text("All")
                            .font(.caption2).foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)

                    ForEach(["movie","tv","book"], id: \.self) { key in
                        PieLegendTile(
                            label: key.capitalized,
                            color: color(for: key),
                            value: stats.countsByType[key] ?? 0
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            Spacer()
        }
        .background(Color("BackgroundGray").ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { Task { await vm.load() } }
    }

    // MARK: Helpers
    private func sortedTypes(from dict: [String:Int]) -> [(type: String, count: Int)] {
        dict.map { (type: $0.key, count: $0.value) }
            .sorted { $0.type < $1.type }
    }

    private func color(for type: String) -> Color {
        switch type {
        case "movie": return .blue
        case "tv": return .green
        case "book": return .orange
        default: return .gray
        }
    }
}

// View для одного года
private struct ChartViewForYear: View {
    let year: Int
    let countsByWeek: [String: Int]
    let monthAbbr: [String]

    var body: some View {
        let entries = monthEntries(for: year, from: countsByWeek)

        Chart {
            ForEach(Array(entries.enumerated()), id: \.offset) { idx, element in
                let (_, value) = element
                BarMark(
                    x: .value("MonthIndex", idx),
                    y: .value("Count", value)
                )
                .cornerRadius(4)
                .foregroundStyle(Color("AccentYellow"))
            }
        }
        .chartXScale(domain: -0.5...(Double(entries.count) - 0.5))
        .chartXAxis {
            AxisMarks(values: Array(entries.indices)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel {
                    if let idx = value.as(Int.self), monthAbbr.indices.contains(idx) {
                        Text(monthAbbr[idx])
                    }
                }
                .foregroundStyle(.white)
                .font(.caption)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(.white)
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }

    private func monthEntries(for year: Int, from dict: [String: Int]) -> [(String, Int)] {
        var monthAcc = Array(repeating: 0, count: 12)
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2 // понедельник

        for (key, val) in dict {
            let parts = key.split(separator: "-W")
            guard parts.count == 2,
                  let yr = Int(parts[0]), yr == year,
                  let wk = Int(parts[1])
            else { continue }
            let components = DateComponents(
                weekday: 2,
                weekOfYear: wk,
                yearForWeekOfYear: yr
            )
            if let date = cal.date(from: components) {
                let month = cal.component(.month, from: date)
                monthAcc[month - 1] += val
            }
        }
        return zip(monthAbbr, monthAcc).map { ($0, $1) }
    }
}

struct PieLegendTile: View {
    let label: String
    let color: Color
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text("\(value)")
                .font(.caption2)
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}
