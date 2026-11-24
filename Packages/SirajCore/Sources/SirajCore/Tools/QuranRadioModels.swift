import Foundation

public enum QuranRadioKind: String, Codable, Sendable {
    case broadcast
    case channel
}

public enum QuranRadioFilter: String, CaseIterable, Sendable, Identifiable {
    case all
    case broadcasts
    case reciters
    case tafsirAndSunnah

    public var id: String { rawValue }

    public var titleKey: String {
        switch self {
        case .all: return "radio_filter_all"
        case .broadcasts: return "radio_filter_broadcasts"
        case .reciters: return "radio_filter_reciters"
        case .tafsirAndSunnah: return "radio_filter_tafsir_sunnah"
        }
    }
}

public struct QuranRadioStation: Sendable, Equatable, Hashable, Identifiable {
    public let id: String
    public let nameAr: String
    public let nameEn: String
    public let nameTr: String
    public let nameUr: String
    public let descriptionAr: String
    public let descriptionEn: String
    public let descriptionTr: String
    public let descriptionUr: String
    public let locationAr: String
    public let locationEn: String
    public let locationTr: String
    public let locationUr: String
    public let streamUrl: String
    public let kind: QuranRadioKind

    public static let noPlaceEn = "Live"
    private static let topicalIds: Set<String> = ["tafseer", "english", "sunnah"]
    private static let emblemAssets: Set<String> = ["radio_cairo", "radio_sharjah", "radio_quran", "radio_tarateel"]

    public func localizedName(language: String) -> String {
        if language.hasPrefix("ar") { return nameAr }
        if language.hasPrefix("ur") { return nameUr }
        if language.hasPrefix("tr") { return nameTr }
        return nameEn
    }

    public func localizedDescription(language: String) -> String {
        if language.hasPrefix("ar") { return descriptionAr }
        if language.hasPrefix("ur") { return descriptionUr }
        if language.hasPrefix("tr") { return descriptionTr }
        return descriptionEn
    }

    public func localizedLocation(language: String) -> String {
        if language.hasPrefix("ar") { return locationAr }
        if language.hasPrefix("ur") { return locationUr }
        if language.hasPrefix("tr") { return locationTr }
        return locationEn
    }

    public var hasPlace: Bool { locationEn != Self.noPlaceEn }
    public var isTopical: Bool { Self.topicalIds.contains(id) }
    public var isEmblemArtwork: Bool { Self.emblemAssets.contains(artworkAsset) }

    public var artworkAsset: String {
        switch id {
        case "quran_saudi": return "radio_saudi"
        case "quran_cairo": return "radio_cairo"
        case "quran_sharjah": return "radio_sharjah"
        case "quran_nablus": return "img_alaqsa"
        case "sunnah": return "img_madinah"
        case "damascus": return "radio_damascus"
        case "quran_algeria": return "radio_algeria"
        case "quran_bahrain": return "radio_bahrain"
        case "quran_qatar": return "radio_qatar"
        case "quran_qatar_2": return "radio_qatar_2"
        case "quran_oman": return "radio_oman"
        case "quran_jordan": return "radio_jordan"
        case "roqiah": return "radio_ruqyah"
        case "baqarah": return "radio_baqarah"
        case "english": return "radio_english"
        case "mishary": return "reciter_alafasy"
        case "abdulbasit": return "reciter_abdulbasit"
        case "quran_mix": return "radio_quran"
        case "tarateel": return "radio_tarateel"
        case "tafseer": return "radio_tafseer"
        case "maher": return "reciter_maher"
        case "sudais": return "reciter_sudais"
        case "shuraim": return "reciter_shuraym"
        case "dosari": return "reciter_dossari"
        case "ajmy": return "reciter_ajamy"
        default: return "radio_quran"
        }
    }

    public static func byId(_ id: String?) -> QuranRadioStation? {
        guard let id else { return nil }
        return stations.first { $0.id == id }
    }

    public static func filter(_ filter: QuranRadioFilter, query: String) -> [QuranRadioStation] {
        let base: [QuranRadioStation]
        switch filter {
        case .all:
            base = stations
        case .broadcasts:
            base = stations.filter { $0.kind == .broadcast }
        case .reciters:
            base = stations.filter { $0.kind == .channel && !$0.isTopical }
        case .tafsirAndSunnah:
            base = stations.filter { $0.isTopical }
        }
        let folded = ArabicSearchText.normalizeQuery(query)
        guard !folded.isEmpty else { return base }
        return base.filter { st in
            [
                st.nameAr, st.nameEn, st.nameTr, st.nameUr,
                st.descriptionAr, st.descriptionEn, st.descriptionTr, st.descriptionUr,
                st.locationAr, st.locationEn, st.locationTr, st.locationUr
            ].contains { ArabicSearchText.normalize($0).contains(folded) }
        }
    }

    private static func reciterStation(
        id: String,
        nameAr: String,
        nameEn: String,
        nameTr: String,
        nameUr: String,
        streamUrl: String
    ) -> QuranRadioStation {
        QuranRadioStation(
            id: id,
            nameAr: nameAr,
            nameEn: nameEn,
            nameTr: nameTr,
            nameUr: nameUr,
            descriptionAr: "المصحف المرتل كاملاً بصوت \(nameAr)",
            descriptionEn: "The complete Mushaf, recited by \(nameEn)",
            descriptionTr: "\(nameTr) sesinden Kur'an-ı Kerîm'in tamamı",
            descriptionUr: "\(nameUr) کی آواز میں مکمل قرآن مجید",
            locationAr: "بث مباشر",
            locationEn: noPlaceEn,
            locationTr: "Canlı",
            locationUr: "لائیو",
            streamUrl: streamUrl,
            kind: .channel
        )
    }

    public static let stations: [QuranRadioStation] = [
        QuranRadioStation(
            id: "quran_saudi",
            nameAr: "إذاعة القرآن الكريم - السعودية",
            nameEn: "Saudi Quran Radio",
            nameTr: "Suudi Arabistan Kur'an Radyosu",
            nameUr: "سعودی قرآن ریڈیو",
            descriptionAr: "البث المباشر لإذاعة القرآن الكريم من المملكة العربية السعودية: تلاوات وبرامج علمية",
            descriptionEn: "The Kingdom's Holy Quran Radio, live: recitation and scholarly programmes",
            descriptionTr: "Suudi Arabistan Kur'an-ı Kerîm Radyosu canlı: tilavetler ve ilmî programlar",
            descriptionUr: "سعودی عرب کے قرآن ریڈیو کی براہ راست نشریات: تلاوت اور علمی پروگرام",
            locationAr: "السعودية",
            locationEn: "Saudi Arabia",
            locationTr: "Suudi Arabistan",
            locationUr: "سعودی عرب",
            streamUrl: "https://stream.radiojar.com/0tpy1h0kxtzuv",
            kind: .broadcast
        ),
        QuranRadioStation(
            id: "quran_cairo",
            nameAr: "إذاعة القرآن الكريم - القاهرة",
            nameEn: "Cairo Quran Radio",
            nameTr: "Kahire Kur'an Radyosu",
            nameUr: "قاہرہ قرآن ریڈیو",
            descriptionAr: "إذاعة القرآن الكريم من القاهرة على الهواء منذ ١٩٦٤ بأصوات كبار قراء مصر",
            descriptionEn: "Egypt's Holy Quran Radio, on air since 1964 with the great Egyptian reciters",
            descriptionTr: "1964'ten beri yayında olan Mısır Kur'an Radyosu, büyük Mısırlı kârilerle",
            descriptionUr: "مصر کا قرآن ریڈیو، ۱۹۶۴ سے نشر، عظیم مصری قراء کی آواز میں",
            locationAr: "القاهرة - مصر",
            locationEn: "Cairo, Egypt",
            locationTr: "Kahire, Mısır",
            locationUr: "قاہرہ، مصر",
            streamUrl: "https://stream.radiojar.com/8s5u5tpdtwzuv",
            kind: .broadcast
        ),
        QuranRadioStation(
            id: "quran_sharjah",
            nameAr: "إذاعة القرآن الكريم - الشارقة",
            nameEn: "Sharjah Quran Radio",
            nameTr: "Şarika Kur'an Radyosu",
            nameUr: "شارجہ قرآن ریڈیو",
            descriptionAr: "بث إذاعي للقرآن الكريم من إمارة الشارقة بنخبة من كبار القراء",
            descriptionEn: "Quran broadcast from the Emirate of Sharjah featuring renowned reciters",
            descriptionTr: "Şarika Emirliği'nden seçkin kârilerle Kur'an-ı Kerîm yayını",
            descriptionUr: "امارت شارجہ سے ممتاز قراء کی تلاوت کے ساتھ قرآن نشریات",
            locationAr: "الشارقة - الإمارات",
            locationEn: "Sharjah, UAE",
            locationTr: "Şarika, BAE",
            locationUr: "شارجہ، متحدہ عرب امارات",
            streamUrl: "https://l3.itworkscdn.net/smcquranlive/quranradiolive/icecast.audio",
            kind: .broadcast
        ),
        QuranRadioStation(
            id: "quran_nablus",
            nameAr: "إذاعة القرآن الكريم - نابلس",
            nameEn: "Nablus Quran Radio",
            nameTr: "Nablus Kur'an Radyosu",
            nameUr: "نابلس قرآن ریڈیو",
            descriptionAr: "بث مباشر لإذاعة القرآن الكريم من مدينة نابلس في فلسطين",
            descriptionEn: "Quran radio broadcast live from the Palestinian city of Nablus",
            descriptionTr: "Filistin'in Nablus şehrinden canlı Kur'an-ı Kerîm yayını",
            descriptionUr: "فلسطینی شہر نابلس سے براہ راست قرآن ریڈیو نشریات",
            locationAr: "نابلس - فلسطين",
            locationEn: "Nablus, Palestine",
            locationTr: "Nablus, Filistin",
            locationUr: "نابلس، فلسطین",
            streamUrl: "https://quran-radio.org:8899/;",
            kind: .broadcast
        ),
        QuranRadioStation(
            id: "sunnah",
            nameAr: "إذاعة السنة النبوية",
            nameEn: "Sunnah Radio",
            nameTr: "Sünnet Radyosu",
            nameUr: "سنت ریڈیو",
            descriptionAr: "إذاعة متخصصة في نشر أحاديث النبي ﷺ والدروس النبوية الشريفة",
            descriptionEn: "A station dedicated to the Prophetic Sunnah and Hadith studies",
            descriptionTr: "Peygamber Efendimiz'in (s.a.v) sünnetine ve hadis derslerine adanmış radyo",
            descriptionUr: "سنت نبوی ﷺ اور احادیث کے دروس کے لیے مخصوص ریڈیو",
            locationAr: "بث مباشر",
            locationEn: noPlaceEn,
            locationTr: "Canlı",
            locationUr: "لائیو",
            streamUrl: "https://radiosunna.radioca.st/stream",
            kind: .broadcast
        ),
        QuranRadioStation(
            id: "quran_algeria",
            nameAr: "إذاعة القرآن الكريم - الجزائر",
            nameEn: "Algeria Quran Radio",
            nameTr: "Cezayir Kur'an Radyosu",
            nameUr: "الجزائر قرآن ریڈیو",
            descriptionAr: "قناة القرآن الكريم في الإذاعة الجزائرية: تلاوات ودروس وبرامج دينية",
            descriptionEn: "Algerian national radio's Holy Quran channel: recitation, lessons and religious programmes",
            descriptionTr: "Cezayir ulusal radyosunun Kur'an kanalı: tilavet, dersler ve dinî programlar",
            descriptionUr: "الجزائر کے قومی ریڈیو کا قرآن چینل: تلاوت، دروس اور دینی پروگرام",
            locationAr: "الجزائر",
            locationEn: "Algeria",
            locationTr: "Cezayir",
            locationUr: "الجزائر",
            streamUrl: "https://webradio1.tda.dz:8001/Coran_64K.mp3",
            kind: .broadcast
        ),
        QuranRadioStation(
            id: "quran_bahrain",
            nameAr: "إذاعة القرآن الكريم - البحرين",
            nameEn: "Bahrain Quran Radio",
            nameTr: "Bahreyn Kur'an Radyosu",
            nameUr: "بحرین قرآن ریڈیو",
            descriptionAr: "إذاعة القرآن الكريم من مملكة البحرين على ١٠٦٫١ إف إم",
            descriptionEn: "The Kingdom of Bahrain's Holy Quran Radio, on 106.1 FM",
            descriptionTr: "Bahreyn Krallığı'nın Kur'an Radyosu, 106.1 FM",
            descriptionUr: "مملکتِ بحرین کا قرآن ریڈیو، ۱۰۶٫۱ ایف ایم",
            locationAr: "المنامة - البحرين",
            locationEn: "Manama, Bahrain",
            locationTr: "Manama, Bahreyn",
            locationUr: "منامہ، بحرین",
            streamUrl: "https://5c7b683162943.streamlock.net/live/ngrp:radio-106-1_all/playlist.m3u8",
            kind: .broadcast
        ),
        QuranRadioStation(
            id: "quran_qatar",
            nameAr: "إذاعة القرآن الكريم - قطر",
            nameEn: "Qatar Quran Radio",
            nameTr: "Katar Kur'an Radyosu",
            nameUr: "قطر قرآن ریڈیو",
            descriptionAr: "إذاعة القرآن الكريم من الدوحة، على الهواء منذ ١٩٩٢",
            descriptionEn: "Qatar's Holy Quran Radio from Doha, on air since 1992",
            descriptionTr: "1992'den beri yayında, Doha'dan Katar Kur'an Radyosu",
            descriptionUr: "دوحہ سے قطر کا قرآن ریڈیو، ۱۹۹۲ سے نشر",
            locationAr: "الدوحة - قطر",
            locationEn: "Doha, Qatar",
            locationTr: "Doha, Katar",
            locationUr: "دوحہ، قطر",
            streamUrl: "https://live.kwikmotion.com/qmcquranradiolive/quranradio/playlist.m3u8",
            kind: .broadcast
        ),
        QuranRadioStation(
            id: "quran_qatar_2",
            nameAr: "إذاعة القرآن الكريم ٢ - قطر",
            nameEn: "Qatar Quran Radio 2",
            nameTr: "Katar Kur'an Radyosu 2",
            nameUr: "قطر قرآن ریڈیو ۲",
            descriptionAr: "القناة الثانية لإذاعة القرآن الكريم من الدوحة",
            descriptionEn: "The second channel of Qatar's Holy Quran Radio, from Doha",
            descriptionTr: "Katar Kur'an Radyosu'nun Doha'dan ikinci kanalı",
            descriptionUr: "دوحہ سے قطر قرآن ریڈیو کا دوسرا چینل",
            locationAr: "الدوحة - قطر",
            locationEn: "Doha, Qatar",
            locationTr: "Doha, Katar",
            locationUr: "دوحہ، قطر",
            streamUrl: "https://live.kwikmotion.com/qmcquranradio2live/quranradio2/playlist.m3u8",
            kind: .broadcast
        ),
        QuranRadioStation(
            id: "quran_oman",
            nameAr: "إذاعة القرآن الكريم - عُمان",
            nameEn: "Oman Quran Radio",
            nameTr: "Umman Kur'an Radyosu",
            nameUr: "عمان قرآن ریڈیو",
            descriptionAr: "إذاعة القرآن الكريم من سلطنة عُمان",
            descriptionEn: "The Sultanate of Oman's Holy Quran Radio",
            descriptionTr: "Umman Sultanlığı'nın Kur'an Radyosu",
            descriptionUr: "سلطنتِ عمان کا قرآن ریڈیو",
            locationAr: "مسقط - عُمان",
            locationEn: "Muscat, Oman",
            locationTr: "Maskat, Umman",
            locationUr: "مسقط، عمان",
            streamUrl: "https://partwota.cdn.mgmlcdn.com/quranrdoorg/quranrdo.stream_aac/chunklist.m3u8",
            kind: .broadcast
        ),
        QuranRadioStation(
            id: "quran_jordan",
            nameAr: "إذاعة القرآن الكريم - الأردن",
            nameEn: "Jordan Quran Radio",
            nameTr: "Ürdün Kur'an Radyosu",
            nameUr: "اردن قرآن ریڈیو",
            descriptionAr: "إذاعة القرآن الكريم من مؤسسة الإذاعة والتلفزيون الأردني",
            descriptionEn: "Jordan Radio and Television's Holy Quran Radio",
            descriptionTr: "Ürdün Radyo ve Televizyonu'nun Kur'an Radyosu",
            descriptionUr: "اردن ریڈیو و ٹیلی وژن کا قرآن ریڈیو",
            locationAr: "عمّان - الأردن",
            locationEn: "Amman, Jordan",
            locationTr: "Amman, Ürdün",
            locationUr: "عمّان، اردن",
            streamUrl: "https://jrtv-live.ercdn.net/jrradio/quranradio.m3u8",
            kind: .broadcast
        ),
        QuranRadioStation(
            id: "quran_mix",
            nameAr: "إذاعة القرآن الكريم",
            nameEn: "Quran Radio",
            nameTr: "Kur'an Radyosu",
            nameUr: "قرآن ریڈیو",
            descriptionAr: "تلاوات متنوعة لكبار القراء على مدار الساعة",
            descriptionEn: "Recitations from many of the great reciters, around the clock",
            descriptionTr: "Büyük kârilerden 7/24 çeşitli tilavetler",
            descriptionUr: "عظیم قراء کی متنوع تلاوتیں، چوبیس گھنٹے",
            locationAr: "بث مباشر",
            locationEn: noPlaceEn,
            locationTr: "Canlı",
            locationUr: "لائیو",
            streamUrl: "https://qurango.net/radio/mix",
            kind: .channel
        ),
        QuranRadioStation(
            id: "tarateel",
            nameAr: "تراتيل",
            nameEn: "Tarateel",
            nameTr: "Teratîl",
            nameUr: "تراتیل",
            descriptionAr: "تلاوات خاشعة هادئة للتدبر والسكينة",
            descriptionEn: "Still, reverent recitation for reflection",
            descriptionTr: "Tefekkür için sakin, huşu dolu tilavetler",
            descriptionUr: "غور و فکر کے لیے پرسکون تلاوت",
            locationAr: "بث مباشر",
            locationEn: noPlaceEn,
            locationTr: "Canlı",
            locationUr: "لائیو",
            streamUrl: "https://qurango.net/radio/tarateel",
            kind: .channel
        ),
        QuranRadioStation(
            id: "tafseer",
            nameAr: "إذاعة التفسير",
            nameEn: "Tafsir Radio",
            nameTr: "Tefsir Radyosu",
            nameUr: "تفسیر ریڈیو",
            descriptionAr: "شرح وبيان معاني آيات القرآن الكريم",
            descriptionEn: "The meanings of the verses, explained",
            descriptionTr: "Âyetlerin manalarının açıklaması",
            descriptionUr: "قرآنی آیات کے معانی کی تشریح",
            locationAr: "بث مباشر",
            locationEn: noPlaceEn,
            locationTr: "Canlı",
            locationUr: "لائیو",
            streamUrl: "https://qurango.net/radio/tafseer",
            kind: .channel
        ),
        QuranRadioStation(
            id: "roqiah",
            nameAr: "الرقية الشرعية",
            nameEn: "Ruqyah",
            nameTr: "Rukye",
            nameUr: "رقیہ شرعیہ",
            descriptionAr: "آيات الرقية والأدعية النبوية على مدار الساعة",
            descriptionEn: "The verses and prophetic supplications of ruqyah, around the clock",
            descriptionTr: "Rukye âyetleri ve nebevî dualar, 7/24",
            descriptionUr: "رقیہ کی آیات اور مسنون دعائیں، چوبیس گھنٹے",
            locationAr: "بث مباشر",
            locationEn: noPlaceEn,
            locationTr: "Canlı",
            locationUr: "لائیو",
            streamUrl: "https://qurango.net/radio/roqiah",
            kind: .channel
        ),
        QuranRadioStation(
            id: "baqarah",
            nameAr: "سورة البقرة",
            nameEn: "Surat al-Baqarah",
            nameTr: "Bakara Sûresi",
            nameUr: "سورۂ بقرہ",
            descriptionAr: "سورة البقرة متواصلة بأصوات عدد من القراء",
            descriptionEn: "Al-Baqarah without pause, in the voices of many reciters",
            descriptionTr: "Bakara Sûresi, birçok kârinin sesinden, aralıksız",
            descriptionUr: "سورۂ بقرہ، متعدد قراء کی آواز میں، مسلسل",
            locationAr: "بث مباشر",
            locationEn: noPlaceEn,
            locationTr: "Canlı",
            locationUr: "لائیو",
            streamUrl: "https://qurango.net/radio/albaqarah",
            kind: .channel
        ),
        QuranRadioStation(
            id: "english",
            nameAr: "القرآن مع الترجمة الإنجليزية",
            nameEn: "Quran in English",
            nameTr: "İngilizce Mealli Kur'an",
            nameUr: "انگریزی ترجمے کے ساتھ قرآن",
            descriptionAr: "تلاوة عبدالباسط عبدالصمد تتبعها ترجمة المعاني بالإنجليزية (صحيح إنترناشونال)",
            descriptionEn: "Abdul Basit's recitation, each verse followed by its meaning in English (Saheeh International)",
            descriptionTr: "Abdülbâsıt'ın tilaveti, her âyetin ardından İngilizce meali (Saheeh International)",
            descriptionUr: "عبدالباسط کی تلاوت، ہر آیت کے بعد اس کا انگریزی ترجمہ (صحیح انٹرنیشنل)",
            locationAr: "بث مباشر",
            locationEn: noPlaceEn,
            locationTr: "Canlı",
            locationUr: "لائیو",
            streamUrl: "https://qurango.net/radio/translation_quran_english_walk_basit",
            kind: .channel
        ),
        reciterStation(id: "maher", nameAr: "ماهر المعيقلي", nameEn: "Maher Al-Muaiqly", nameTr: "Mâhir el-Muaykılî", nameUr: "ماہر المعیقلی", streamUrl: "https://qurango.net/radio/maher"),
        reciterStation(id: "sudais", nameAr: "عبدالرحمن السديس", nameEn: "Abdurrahman As-Sudais", nameTr: "Abdurrahman es-Sûdeys", nameUr: "عبدالرحمن السدیس", streamUrl: "https://qurango.net/radio/abdulrahman_alsudaes"),
        reciterStation(id: "shuraim", nameAr: "سعود الشريم", nameEn: "Saud Al-Shuraim", nameTr: "Sûd eş-Şûreym", nameUr: "سعود الشریم", streamUrl: "https://qurango.net/radio/saud_alshuraim"),
        reciterStation(id: "dosari", nameAr: "ياسر الدوسري", nameEn: "Yasser Al-Dosari", nameTr: "Yasir ed-Dûserî", nameUr: "یاسر الدوسری", streamUrl: "https://qurango.net/radio/yasser_aldosari"),
        reciterStation(id: "ajmy", nameAr: "أحمد العجمي", nameEn: "Ahmad Al-Ajmy", nameTr: "Ahmed el-Acemî", nameUr: "احمد العجمی", streamUrl: "https://qurango.net/radio/ahmad_alajmy"),
        reciterStation(id: "mishary", nameAr: "مشاري العفاسي", nameEn: "Mishary Alafasy", nameTr: "Mişârî el-Afâsî", nameUr: "مشاری العفاسی", streamUrl: "https://qurango.net/radio/mishary_alafasi"),
        QuranRadioStation(
            id: "abdulbasit",
            nameAr: "عبدالباسط عبدالصمد",
            nameEn: "Abdul Basit Abdus Samad",
            nameTr: "Abdülbâsıt Abdüssamed",
            nameUr: "عبدالباسط عبدالصمد",
            descriptionAr: "المصحف المجوّد بصوت عبدالباسط عبدالصمد",
            descriptionEn: "The Mushaf in the mujawwad style, recited by Abdul Basit Abdus Samad",
            descriptionTr: "Abdülbâsıt Abdüssamed'in sesinden mücevved Kur'an",
            descriptionUr: "عبدالباسط عبدالصمد کی آواز میں مجوّد قرآن",
            locationAr: "بث مباشر",
            locationEn: noPlaceEn,
            locationTr: "Canlı",
            locationUr: "لائیو",
            streamUrl: "https://qurango.net/radio/abdulbasit_abdulsamad_mojawwad",
            kind: .channel
        )
    ]
}

public struct QuranRadioPrefs: Codable, Sendable, Equatable {
    public var lastStationId: String?
    public var pinnedStationIds: [String]

    public init(lastStationId: String? = nil, pinnedStationIds: [String] = []) {
        self.lastStationId = lastStationId
        self.pinnedStationIds = pinnedStationIds
    }
}
