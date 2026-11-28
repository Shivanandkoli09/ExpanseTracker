//
//  HomeCards.swift
//  ExpanseTracker
//

import SwiftUI
import Charts

// MARK: - Month Overview

struct MonthOverviewCard: View {
    let summary: SpendingSummary
    let budget: Double?
    let onEditBudget: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(summary.monthStart.formatted(.dateTime.month(.wide))) spending")
                    .font(.subheadline.weight(.medium))
                    .opacity(0.9)
                Spacer()
                Button(action: onEditBudget) {
                    Label(budget == nil ? "Set budget" : "Budget", systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.2), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Text(Currency.string(summary.monthExpense))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            if let budget, budget > 0 {
                budgetSection(summary.budgetStatus(budget: budget))
            }

            Rectangle()
                .fill(.white.opacity(0.25))
                .frame(height: 1)

            HStack {
                stat(title: "Income this month", value: summary.monthIncome, icon: "arrow.down.left.circle.fill")
                Spacer()
                stat(title: "Total balance", value: summary.allTimeBalance, icon: "indianrupeesign.circle.fill")
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Brand.gradient)
        )
        .animation(.spring(duration: 0.4), value: summary.monthExpense)
    }

    private func budgetSection(_ status: SpendingSummary.BudgetStatus) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.25))
                        Capsule()
                            .fill(barColor(status))
                            .frame(width: proxy.size.width * min(1, status.progress))
                    }
                }
                .frame(height: 8)
                .accessibilityHidden(true)

                HStack {
                    Text(status.isOver
                         ? "\(Currency.string(-status.remaining)) over budget"
                         : "\(Currency.string(status.remaining)) left of \(Currency.string(status.budget))")
                    Spacer()
                    Text("\(summary.daysLeftInMonth) \(summary.daysLeftInMonth == 1 ? "day" : "days") left")
                }
                .font(.caption)
                .opacity(0.9)
            }

            HStack(spacing: 8) {
                Image(systemName: status.isOver ? "exclamationmark.triangle.fill" : "sun.max.fill")
                if status.isOver {
                    Text("Over budget — a no-spend day would help.")
                } else {
                    Text("Safe to spend today: **\(Currency.string(status.safeToSpendToday.rounded(.down)))**")
                }
            }
            .font(.footnote)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func barColor(_ status: SpendingSummary.BudgetStatus) -> Color {
        switch status.progress {
        case ..<0.8: return .white
        case ..<1.0: return .yellow
        default:     return Color(red: 1, green: 0.55, blue: 0.55)
        }
    }

    private func stat(title: String, value: Double, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption)
            .opacity(0.85)
            Text(Currency.string(value))
                .font(.headline)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Saving Goal

struct SavingGoalCard: View {
    let goal: SavingGoal?
    let target: Double?
    let summary: SpendingSummary
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                ring
                VStack(alignment: .leading, spacing: 4) {
                    content
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
    }

    @ViewBuilder
    private var content: some View {
        if let goal, let target, target > 0 {
            let progress = summary.goalProgress(target: target)
            Text(goal.title)
                .font(.headline)
            Text("\(Currency.string(progress.saved)) of \(Currency.string(target))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Text(paceText(progress))
                .font(.caption)
                .foregroundStyle(progress.isReached ? .green : .secondary)
        } else if let goal {
            Text(goal.title)
                .font(.headline)
            Text("Set a target amount to track your progress.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Text("What are you saving for?")
                .font(.headline)
            Text("Pick a goal and we'll show how close you are.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var ring: some View {
        let progress = (target.map { summary.goalProgress(target: $0).progress }) ?? 0
        return ZStack {
            Circle()
                .stroke(Brand.primary.opacity(0.15), lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Brand.gradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.6), value: progress)
            Text(goal?.emoji ?? "🎯")
                .font(.title2)
        }
        .frame(width: 58, height: 58)
        .accessibilityLabel(goal == nil ? "No goal" : "\(Int(progress * 100)) percent of goal")
    }

    private func paceText(_ progress: SpendingSummary.GoalProgress) -> String {
        if progress.isReached { return "🎉 Goal reached — amazing!" }
        guard let months = progress.monthsToGo,
              let date = Calendar.current.date(byAdding: .month, value: months, to: Date()) else {
            return "Save a little this month to start moving."
        }
        return "At this month's pace: \(date.formatted(.dateTime.month(.abbreviated).year()))"
    }
}

// MARK: - Spending Chart

struct SpendingChartCard: View {
    let summary: SpendingSummary

    private enum Mode: String, CaseIterable, Identifiable {
        case categories = "Categories"
        case trend = "6 Months"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .categories

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Where it went")
                .font(.headline)
            Picker("Chart", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            switch mode {
            case .categories: categoryChart
            case .trend: trendChart
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .animation(.easeInOut(duration: 0.25), value: mode)
    }

    @ViewBuilder
    private var categoryChart: some View {
        if summary.categoryTotals.isEmpty {
            Text("No expenses yet this month.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            HStack(spacing: 18) {
                Chart(summary.categoryTotals) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(item.category.color)
                }
                .chartLegend(.hidden)
                .frame(width: 128, height: 128)
                .overlay {
                    VStack(spacing: 0) {
                        Text("Total").font(.caption2).foregroundStyle(.secondary)
                        Text(Currency.compact(summary.monthExpense)).font(.subheadline.weight(.bold))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(summary.categoryTotals.prefix(4)) { item in
                        HStack(spacing: 8) {
                            Circle().fill(item.category.color).frame(width: 8, height: 8)
                            Text(item.category.displayName)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Text("\(percent(item.amount))%")
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private var trendChart: some View {
        let average = summary.trend.map(\.expense).reduce(0, +) / Double(max(1, summary.trend.count))
        return Chart {
            ForEach(summary.trend) { month in
                BarMark(
                    x: .value("Month", month.month, unit: .month),
                    y: .value("Spent", month.expense)
                )
                .cornerRadius(6)
                .foregroundStyle(month.month == summary.monthStart
                                 ? AnyShapeStyle(Brand.gradient)
                                 : AnyShapeStyle(Brand.primary.opacity(0.3)))
            }
            if average > 0 {
                RuleMark(y: .value("Average", average))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary)
                    .annotation(position: .top, alignment: .leading) {
                        Text("avg \(Currency.compact(average))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(Currency.compact(amount))
                    }
                }
            }
        }
        .frame(height: 170)
    }

    private func percent(_ amount: Double) -> Int {
        guard summary.monthExpense > 0 else { return 0 }
        return Int((amount / summary.monthExpense * 100).rounded())
    }
}

// MARK: - Insights

struct InsightsScrollView: View {
    let insights: [Insight]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(insights) { insight in
                    InsightCardView(insight: insight)
                        .frame(width: 230)
                }
            }
        }
        .scrollClipDisabled()
    }
}
