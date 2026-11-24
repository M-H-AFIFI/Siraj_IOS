import SwiftUI
import UIKit
import SirajCore

struct ZakatView: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let appState: AppState

    @State private var step = 1
    @State private var currency: ZakatCurrency = ZakatCalculator.supportedCurrencies[0]
    @State private var cashText = ""
    @State private var goldGramsText = ""
    @State private var silverGramsText = ""
    @State private var goldPriceText = ZakatCalculator.amountText(ZakatCalculator.supportedCurrencies[0].defaultGoldPrice)
    @State private var silverPriceText = ZakatCalculator.amountText(ZakatCalculator.supportedCurrencies[0].defaultSilverPrice)
    @State private var showPriceEditor = false
    @State private var showCurrencyPicker = false

    private let quickCurrencyCodes = ["SAR", "AED", "EGP", "USD", "EUR", "GBP", "TRY", "PKR"]

    private var assets: ZakatAssets {
        ZakatAssets(
            cash: Double(ZakatCalculator.sanitizeAmount(cashText)) ?? 0,
            goldGrams: Double(ZakatCalculator.sanitizeAmount(goldGramsText)) ?? 0,
            goldPricePerGram: Double(ZakatCalculator.sanitizeAmount(goldPriceText)) ?? 0,
            silverGrams: Double(ZakatCalculator.sanitizeAmount(silverGramsText)) ?? 0,
            silverPricePerGram: Double(ZakatCalculator.sanitizeAmount(silverPriceText)) ?? 0
        )
    }

    private var result: ZakatResult {
        ZakatCalculator.calculate(assets)
    }

    private var hasValidPrices: Bool {
        assets.goldPricePerGram > 0 || assets.silverPricePerGram > 0
    }

    private var hasAnyAmount: Bool {
        assets.cash > 0 || assets.goldGrams > 0 || assets.silverGrams > 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                stepProgressBar

                if step == 1 {
                    stepOneCashAndCurrency
                } else if step == 2 {
                    stepTwoMetalsAndNisab
                } else {
                    stepThreeSummary
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 124)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear)
        .navigationTitle(theme.t("zakat_calculator_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(theme.t("reset")) {
                    resetAll()
                }
                .font(theme.scaledFont(size: 13.5, weight: .semibold))
                .foregroundStyle(theme.primary)
            }
        }
        .sheet(isPresented: $showCurrencyPicker) {
            ZakatCurrencyPickerSheet(selected: currency) { picked in
                selectCurrency(picked)
            }
        }
    }

    private var stepProgressBar: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { idx in
                Capsule()
                    .fill(idx <= step ? theme.primary : theme.outlineVariant.opacity(0.45))
                    .frame(height: 5)
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Step 1: Currency & Cash

    private var stepOneCashAndCurrency: some View {
        let quickList = quickCurrencyCodes.compactMap { code in
            ZakatCalculator.supportedCurrencies.first(where: { $0.code == code })
        }
        let extraCount = max(0, ZakatCalculator.supportedCurrencies.count - quickList.count)

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.t("zakat_total_cash"))
                    .font(theme.scaledFont(size: 22, weight: .black))
                    .foregroundStyle(theme.onBackground)
                Text(theme.t("zakat_cash_desc"))
                    .font(theme.scaledFont(size: 13.5))
                    .foregroundStyle(theme.onSurfaceVariant)
            }

            // Currency card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(theme.t("zakat_select_currency"))
                        .font(theme.scaledFont(size: 13.5, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                    Spacer()
                    Button {
                        showCurrencyPicker = true
                    } label: {
                        Text(theme.t("tools_zakat_more_currencies", theme.digits(String(extraCount))))
                            .font(theme.scaledFont(size: 12, weight: .bold))
                            .foregroundStyle(theme.primary)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showCurrencyPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Text(currency.symbol)
                            .font(theme.scaledFont(size: 18, weight: .black))
                            .foregroundStyle(theme.onPrimary)
                            .frame(width: 44, height: 44)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.primary))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.label)
                                .font(theme.scaledFont(size: 15, weight: .bold))
                                .foregroundStyle(theme.onSurface)
                            Text(currency.name)
                                .font(theme.scaledFont(size: 12))
                                .foregroundStyle(theme.onSurfaceVariant)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.outline)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.primary.opacity(theme.isDark ? 0.14 : 0.08))
                    )
                }
                .buttonStyle(.plain)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickList) { item in
                            let selected = item.code == currency.code
                            Button {
                                selectCurrency(item)
                            } label: {
                                Text(item.code)
                                    .font(theme.scaledFont(size: 12.5, weight: .bold))
                                    .foregroundStyle(selected ? theme.onPrimary : theme.onSurface)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule().fill(selected ? theme.primary : theme.surfaceContainerHigh.opacity(0.75))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
            .sirajCardSurface(cornerRadius: 22)

            // Cash input
            amountField(
                label: theme.t("zakat_cash_label"),
                suffix: currency.symbol,
                text: $cashText
            )

            Button {
                withAnimation(theme.motionEnabled ? .easeInOut(duration: 0.2) : nil) {
                    step = 2
                }
            } label: {
                HStack(spacing: 8) {
                    Text(theme.t("next_gold_silver"))
                        .font(theme.scaledFont(size: 15.5, weight: .black))
                    Image(systemName: theme.isRTL ? "arrow.left" : "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(theme.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(theme.primary))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Step 2: Gold & Silver + Nisab

    private var stepTwoMetalsAndNisab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.t("zakat_gold_silver"))
                    .font(theme.scaledFont(size: 22, weight: .black))
                    .foregroundStyle(theme.onBackground)
                Text(theme.t("zakat_metals_desc"))
                    .font(theme.scaledFont(size: 13.5))
                    .foregroundStyle(theme.onSurfaceVariant)
            }

            Button {
                showCurrencyPicker = true
            } label: {
                HStack {
                    Text(currency.label)
                        .font(theme.scaledFont(size: 13.5, weight: .bold))
                        .foregroundStyle(theme.primary)
                    Spacer()
                    Text(currency.name)
                        .font(theme.scaledFont(size: 12))
                        .foregroundStyle(theme.onSurfaceVariant)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .sirajCardSurface(cornerRadius: 16)
            }
            .buttonStyle(.plain)

            amountField(
                label: theme.t("zakat_gold_grams_label"),
                suffix: theme.t("tools_zakat_grams"),
                text: $goldGramsText
            )

            amountField(
                label: theme.t("zakat_silver_grams_label"),
                suffix: theme.t("tools_zakat_grams"),
                text: $silverGramsText
            )

            // Nisab explainer
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(theme.gold)
                    Text(theme.t("tools_zakat_nisab_title"))
                        .font(theme.scaledFont(size: 14, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                }
                Text(theme.t("tools_zakat_nisab_body"))
                    .font(theme.scaledFont(size: 12.5))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .lineSpacing(3)
            }
            .padding(14)
            .sirajCardSurface(cornerRadius: 18)

            // Collapsible price adjustments
            VStack(spacing: 12) {
                Button {
                    withAnimation(theme.motionEnabled ? .easeInOut(duration: 0.2) : nil) {
                        showPriceEditor.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(theme.primary)
                        Text(theme.t("zakat_adjust_prices"))
                            .font(theme.scaledFont(size: 14, weight: .bold))
                            .foregroundStyle(theme.onSurface)
                        Spacer()
                        Image(systemName: showPriceEditor ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.outline)
                    }
                }
                .buttonStyle(.plain)

                if showPriceEditor {
                    amountField(
                        label: theme.t("zakat_gold_price_label"),
                        suffix: currency.symbol,
                        text: $goldPriceText
                    )
                    amountField(
                        label: theme.t("zakat_silver_price_label"),
                        suffix: currency.symbol,
                        text: $silverPriceText
                    )
                }
            }
            .padding(14)
            .sirajCardSurface(cornerRadius: 18)

            if !hasValidPrices {
                Text(theme.t("tools_zakat_need_price"))
                    .font(theme.scaledFont(size: 12.5, weight: .semibold))
                    .foregroundStyle(theme.error)
            } else if !hasAnyAmount {
                Text(theme.t("tools_zakat_need_amount"))
                    .font(theme.scaledFont(size: 12.5))
                    .foregroundStyle(theme.onSurfaceVariant)
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation(theme.motionEnabled ? .easeInOut(duration: 0.2) : nil) { step = 1 }
                } label: {
                    Text(theme.t("back"))
                        .font(theme.scaledFont(size: 14.5, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .sirajCardSurface(cornerRadius: 18)
                }
                .buttonStyle(.plain)

                Button {
                    if appState.settings.isHapticEnabled {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    withAnimation(theme.motionEnabled ? .easeInOut(duration: 0.2) : nil) { step = 3 }
                } label: {
                    Text(theme.t("zakat_calc_ready"))
                        .font(theme.scaledFont(size: 14.5, weight: .black))
                        .foregroundStyle(theme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(hasValidPrices && hasAnyAmount ? theme.primary : theme.outlineVariant)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!hasValidPrices || !hasAnyAmount)
            }
        }
    }

    // MARK: - Step 3: Result Summary

    private var stepThreeSummary: some View {
        let res = result
        return VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 10) {
                Text(theme.t("zakat_total_due"))
                    .font(theme.scaledFont(size: 13.5, weight: .bold))
                    .foregroundStyle(theme.primary)

                if res.isEligible {
                    Text(formatCurrency(res.zakatDue))
                        .font(theme.scaledFont(size: 34, weight: .black))
                        .foregroundStyle(theme.onSurface)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                } else {
                    Text(theme.t("tools_zakat_not_due"))
                        .font(theme.scaledFont(size: 24, weight: .black))
                        .foregroundStyle(theme.onSurface)
                }

                Text(theme.t("tools_zakat_rate_note"))
                    .font(theme.scaledFont(size: 12))
                    .foregroundStyle(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(22)
            .sirajCardSurface(cornerRadius: 26, isElevated: true)

            VStack(spacing: 12) {
                summaryRow(label: theme.t("zakat_total_assets"), value: formatCurrency(res.totalAssets))
                Divider().opacity(0.45)
                summaryRow(label: theme.t("zakat_net_wealth"), value: formatCurrency(res.netWealth))
                Divider().opacity(0.45)
                summaryRow(label: theme.t("zakat_nisab_value"), value: formatCurrency(res.nisabValue))
            }
            .padding(16)
            .sirajCardSurface(cornerRadius: 22)

            if !res.isEligible {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(theme.gold)
                    Text(theme.t("zakat_below_nisab"))
                        .font(theme.scaledFont(size: 13))
                        .foregroundStyle(theme.onSurfaceVariant)
                }
                .padding(14)
                .sirajCardSurface(cornerRadius: 18)
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation(theme.motionEnabled ? .easeInOut(duration: 0.2) : nil) { step = 2 }
                } label: {
                    Text(theme.t("back"))
                        .font(theme.scaledFont(size: 14.5, weight: .bold))
                        .foregroundStyle(theme.onSurface)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .sirajCardSurface(cornerRadius: 18)
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Text(theme.t("finish"))
                        .font(theme.scaledFont(size: 14.5, weight: .black))
                        .foregroundStyle(theme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(theme.primary))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func amountField(label: String, suffix: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(theme.scaledFont(size: 13, weight: .bold))
                .foregroundStyle(theme.onSurface)
            HStack(spacing: 10) {
                TextField("0", text: Binding(
                    get: { text.wrappedValue },
                    set: { text.wrappedValue = ZakatCalculator.sanitizeAmount($0) }
                ))
                .keyboardType(.decimalPad)
                .font(theme.scaledFont(size: 18, weight: .bold))
                .foregroundStyle(theme.onSurface)

                Text(suffix)
                    .font(theme.scaledFont(size: 13.5, weight: .bold))
                    .foregroundStyle(theme.primary)
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .sirajCardSurface(cornerRadius: 16)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(theme.scaledFont(size: 14))
                .foregroundStyle(theme.onSurfaceVariant)
            Spacer()
            Text(value)
                .font(theme.scaledFont(size: 15, weight: .bold))
                .foregroundStyle(theme.onSurface)
        }
    }

    private func selectCurrency(_ picked: ZakatCurrency) {
        currency = picked
        goldPriceText = ZakatCalculator.amountText(picked.defaultGoldPrice)
        silverPriceText = ZakatCalculator.amountText(picked.defaultSilverPrice)
    }

    private func resetAll() {
        step = 1
        cashText = ""
        goldGramsText = ""
        silverGramsText = ""
        selectCurrency(ZakatCalculator.supportedCurrencies[0])
        showPriceEditor = false
    }

    private func formatCurrency(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 2
        nf.maximumFractionDigits = 2
        let raw = nf.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "\(theme.digits(raw)) \(currency.symbol)"
    }
}

private struct ZakatCurrencyPickerSheet: View {
    @Environment(\.sirajTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let selected: ZakatCurrency
    let onSelect: (ZakatCurrency) -> Void

    @State private var query = ""

    private var filtered: [ZakatCurrency] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return ZakatCalculator.supportedCurrencies }
        return ZakatCalculator.supportedCurrencies.filter {
            $0.code.lowercased().contains(q) || $0.name.lowercased().contains(q) || $0.symbol.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { item in
                Button {
                    onSelect(item)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label)
                                .font(theme.scaledFont(size: 15, weight: .bold))
                                .foregroundStyle(theme.onSurface)
                            Text(item.name)
                                .font(theme.scaledFont(size: 12))
                                .foregroundStyle(theme.onSurfaceVariant)
                        }
                        Spacer()
                        if item.code == selected.code {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.primary)
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: theme.t("zakat_search_currency"))
            .navigationTitle(theme.t("zakat_select_currency"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(theme.t("close")) { dismiss() }
                }
            }
        }
    }
}
