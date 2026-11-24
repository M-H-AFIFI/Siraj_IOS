import Foundation

public struct ZakatAssets: Sendable, Equatable {
    public var cash: Double
    public var goldGrams: Double
    public var goldPricePerGram: Double
    public var silverGrams: Double
    public var silverPricePerGram: Double
    public var stocks: Double
    public var businessAssets: Double
    public var debts: Double

    public init(
        cash: Double = 0,
        goldGrams: Double = 0,
        goldPricePerGram: Double = 0,
        silverGrams: Double = 0,
        silverPricePerGram: Double = 0,
        stocks: Double = 0,
        businessAssets: Double = 0,
        debts: Double = 0
    ) {
        self.cash = cash
        self.goldGrams = goldGrams
        self.goldPricePerGram = goldPricePerGram
        self.silverGrams = silverGrams
        self.silverPricePerGram = silverPricePerGram
        self.stocks = stocks
        self.businessAssets = businessAssets
        self.debts = debts
    }
}

public struct ZakatResult: Sendable, Equatable {
    public let totalAssets: Double
    public let totalDeductible: Double
    public let netWealth: Double
    public let zakatDue: Double
    public let isEligible: Bool
    public let nisabValue: Double
}

public struct ZakatCurrency: Sendable, Equatable, Identifiable {
    public let code: String
    public let symbol: String
    public let label: String
    public let name: String
    public let defaultGoldPrice: Double
    public let defaultSilverPrice: Double

    public var id: String { code }
}

public enum ZakatCalculator {
    public static let zakatRate: Double = 0.025
    public static let goldNisabGrams: Double = 85.0
    public static let silverNisabGrams: Double = 595.0

    public static func calculate(_ assets: ZakatAssets) -> ZakatResult {
        let totalAssets = assets.cash
            + (assets.goldGrams * assets.goldPricePerGram)
            + (assets.silverGrams * assets.silverPricePerGram)
            + assets.stocks
            + assets.businessAssets
        let netWealth = max(0.0, totalAssets - assets.debts)

        // Silver nisab is used when available (lower threshold); gold is fallback.
        // Zero prices produce zero nisab and never mark eligibility true.
        let nisabValue: Double
        if assets.silverPricePerGram > 0 {
            nisabValue = assets.silverPricePerGram * silverNisabGrams
        } else if assets.goldPricePerGram > 0 {
            nisabValue = assets.goldPricePerGram * goldNisabGrams
        } else {
            nisabValue = 0.0
        }

        let isEligible = nisabValue > 0 && netWealth >= nisabValue
        let zakatDue = isEligible ? netWealth * zakatRate : 0.0

        return ZakatResult(
            totalAssets: totalAssets,
            totalDeductible: assets.debts,
            netWealth: netWealth,
            zakatDue: zakatDue,
            isEligible: isEligible,
            nisabValue: nisabValue
        )
    }

    public static func sanitizeAmount(_ raw: String) -> String {
        let stripped = raw.replacingOccurrences(of: "٬", with: "").replacingOccurrences(of: " ", with: "")
        let western = DigitFormatter.toWestern(stripped)
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "٫", with: ".")
            .replacingOccurrences(of: "،", with: ".")
        var out = ""
        var seenDot = false
        for ch in western {
            if ch.isNumber {
                out.append(ch)
            } else if ch == "." && !seenDot {
                seenDot = true
                out.append(ch)
            }
        }
        return out
    }

    public static func amountText(_ value: Double) -> String {
        if value == 0 { return "" }
        if value == floor(value) && abs(value) < 1e15 {
            return String(Int64(value))
        }
        return String(value)
    }

    public static let supportedCurrencies: [ZakatCurrency] = [
        ZakatCurrency(code: "SAR", symbol: "ر.س", label: "SAR (ر.س)", name: "Saudi Riyal - ريال سعودي", defaultGoldPrice: 280.0, defaultSilverPrice: 3.75),
        ZakatCurrency(code: "AED", symbol: "د.إ", label: "AED (د.إ)", name: "UAE Dirham - درهم إماراتي", defaultGoldPrice: 275.0, defaultSilverPrice: 3.70),
        ZakatCurrency(code: "KWD", symbol: "د.ك", label: "KWD (د.ك)", name: "Kuwaiti Dinar - دينار كويتي", defaultGoldPrice: 23.0, defaultSilverPrice: 0.31),
        ZakatCurrency(code: "QAR", symbol: "ر.ق", label: "QAR (ر.ق)", name: "Qatari Riyal - ريال قطري", defaultGoldPrice: 273.0, defaultSilverPrice: 3.65),
        ZakatCurrency(code: "OMR", symbol: "ر.ع", label: "OMR (ر.ع)", name: "Omani Rial - ريال عماني", defaultGoldPrice: 29.0, defaultSilverPrice: 0.39),
        ZakatCurrency(code: "BHD", symbol: "د.ب", label: "BHD (د.ب)", name: "Bahraini Dinar - دينار بحريني", defaultGoldPrice: 28.0, defaultSilverPrice: 0.38),
        ZakatCurrency(code: "EGP", symbol: "ج.م", label: "EGP (ج.م)", name: "Egyptian Pound - جنيه مصري", defaultGoldPrice: 3650.0, defaultSilverPrice: 49.0),
        ZakatCurrency(code: "JOD", symbol: "د.أ", label: "JOD (د.أ)", name: "Jordanian Dinar - دينار أردني", defaultGoldPrice: 53.0, defaultSilverPrice: 0.71),
        ZakatCurrency(code: "USD", symbol: "$", label: "USD ($)", name: "US Dollar - دولار أمريكي", defaultGoldPrice: 75.0, defaultSilverPrice: 1.0),
        ZakatCurrency(code: "EUR", symbol: "€", label: "EUR (€)", name: "Euro - يورو", defaultGoldPrice: 70.0, defaultSilverPrice: 0.95),
        ZakatCurrency(code: "GBP", symbol: "£", label: "GBP (£)", name: "British Pound - جنيه إسترليني", defaultGoldPrice: 60.0, defaultSilverPrice: 0.80),
        ZakatCurrency(code: "CAD", symbol: "C$", label: "CAD (C$)", name: "Canadian Dollar - دولار كندي", defaultGoldPrice: 102.0, defaultSilverPrice: 1.35),
        ZakatCurrency(code: "AUD", symbol: "A$", label: "AUD (A$)", name: "Australian Dollar - دولار أسترالي", defaultGoldPrice: 114.0, defaultSilverPrice: 1.50),
        ZakatCurrency(code: "TRY", symbol: "₺", label: "TRY (₺)", name: "Turkish Lira - Türk Lirası", defaultGoldPrice: 2550.0, defaultSilverPrice: 34.0),
        ZakatCurrency(code: "PKR", symbol: "Rs", label: "PKR (Rs)", name: "Pakistani Rupee - پاکستانی روپیہ", defaultGoldPrice: 21000.0, defaultSilverPrice: 280.0),
        ZakatCurrency(code: "INR", symbol: "₹", label: "INR (₹)", name: "Indian Rupee - भारतीय रुपया", defaultGoldPrice: 6250.0, defaultSilverPrice: 85.0),
        ZakatCurrency(code: "BDT", symbol: "৳", label: "BDT (৳)", name: "Bangladeshi Taka - বাংলাদেশ টাকা", defaultGoldPrice: 8900.0, defaultSilverPrice: 120.0),
        ZakatCurrency(code: "IDR", symbol: "Rp", label: "IDR (Rp)", name: "Indonesian Rupiah - Rupiah Indonesia", defaultGoldPrice: 1180000.0, defaultSilverPrice: 16000.0),
        ZakatCurrency(code: "MYR", symbol: "RM", label: "MYR (RM)", name: "Malaysian Ringgit - Ringgit Malaysia", defaultGoldPrice: 355.0, defaultSilverPrice: 4.70),
        ZakatCurrency(code: "SGD", symbol: "S$", label: "SGD (S$)", name: "Singapore Dollar - دولار سنغافوري", defaultGoldPrice: 101.0, defaultSilverPrice: 1.35),
        ZakatCurrency(code: "MAD", symbol: "د.م.", label: "MAD (د.م.)", name: "Moroccan Dirham - درهم مغربي", defaultGoldPrice: 750.0, defaultSilverPrice: 10.0),
        ZakatCurrency(code: "DZD", symbol: "د.ج", label: "DZD (د.ج)", name: "Algerian Dinar - دينار جزائري", defaultGoldPrice: 10100.0, defaultSilverPrice: 135.0),
        ZakatCurrency(code: "TND", symbol: "د.ت", label: "TND (د.ت)", name: "Tunisian Dinar - دينار تونسي", defaultGoldPrice: 235.0, defaultSilverPrice: 3.10),
        ZakatCurrency(code: "LYD", symbol: "د.ل", label: "LYD (د.ل)", name: "Libyan Dinar - دينار ليبي", defaultGoldPrice: 365.0, defaultSilverPrice: 4.90),
        ZakatCurrency(code: "SDG", symbol: "ج.س", label: "SDG (ج.س)", name: "Sudanese Pound - جنيه سوداني", defaultGoldPrice: 45000.0, defaultSilverPrice: 600.0),
        ZakatCurrency(code: "SYP", symbol: "ل.س", label: "SYP (ل.س)", name: "Syrian Pound - ليرة سورية", defaultGoldPrice: 1000000.0, defaultSilverPrice: 13500.0),
        ZakatCurrency(code: "LBP", symbol: "ل.ل", label: "LBP (ل.ل)", name: "Lebanese Pound - ليرة لبنانية", defaultGoldPrice: 6700000.0, defaultSilverPrice: 90000.0),
        ZakatCurrency(code: "YER", symbol: "ر.ي", label: "YER (ر.ي)", name: "Yemeni Rial - ريال يمني", defaultGoldPrice: 18750.0, defaultSilverPrice: 250.0),
        ZakatCurrency(code: "IQD", symbol: "د.ع", label: "IQD (د.ع)", name: "Iraqi Dinar - دينار عراقي", defaultGoldPrice: 98000.0, defaultSilverPrice: 1310.0),
        ZakatCurrency(code: "NGN", symbol: "₦", label: "NGN (₦)", name: "Nigerian Naira - نيرة نيجيرية", defaultGoldPrice: 115000.0, defaultSilverPrice: 1550.0),
        ZakatCurrency(code: "ZAR", symbol: "R", label: "ZAR (R)", name: "South African Rand - راند جنوب أفريقي", defaultGoldPrice: 1380.0, defaultSilverPrice: 18.5),
        ZakatCurrency(code: "KZT", symbol: "₸", label: "KZT (₸)", name: "Kazakhstani Tenge - كازاخستاني تينغ", defaultGoldPrice: 36000.0, defaultSilverPrice: 480.0),
        ZakatCurrency(code: "UZS", symbol: "so'm", label: "UZS (so'm)", name: "Uzbekistani Som - سوم أوزبكستاني", defaultGoldPrice: 950000.0, defaultSilverPrice: 12500.0),
        ZakatCurrency(code: "AZN", symbol: "₼", label: "AZN (₼)", name: "Azerbaijani Manat - مانات أذربيجاني", defaultGoldPrice: 128.0, defaultSilverPrice: 1.70),
        ZakatCurrency(code: "AFN", symbol: "؋", label: "AFN (؋)", name: "Afghan Afghani - أفغاني", defaultGoldPrice: 5300.0, defaultSilverPrice: 71.0),
        ZakatCurrency(code: "SOS", symbol: "Sh", label: "SOS (Sh)", name: "Somali Shilling - شلن صومالي", defaultGoldPrice: 43000.0, defaultSilverPrice: 570.0)
    ]
}
