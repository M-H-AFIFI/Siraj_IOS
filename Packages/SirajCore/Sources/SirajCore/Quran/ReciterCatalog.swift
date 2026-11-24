import Foundation

public enum ReciterCategory: String, Codable, Sendable, Equatable {
    case quran
    case english
    case arabic
}

public enum ReciterPlaybackMode: String, Codable, Sendable, Equatable {
    case surahSegments
    case ayahByAyah
}

public struct Reciter: Codable, Sendable, Equatable, Hashable, Identifiable {
    public static let hafs = "حفص عن عاصم"
    public static let warsh = "ورش عن نافع"
    public static let qalun = "قالون عن نافع"

    public let id: String
    public let name: String
    public let englishName: String
    public let category: ReciterCategory
    public let subInfo: String?
    public let subInfoAr: String?
    public let playbackMode: ReciterPlaybackMode
    public let everyAyahFolder: String?
    public let quranComId: String?
    public let riwayah: String
    public let nameUr: String?
    public let nameTr: String?
    public let subInfoUr: String?
    public let subInfoTr: String?

    public init(
        id: String,
        name: String,
        englishName: String,
        category: ReciterCategory = .quran,
        subInfo: String? = "Murattal",
        subInfoAr: String? = "مرتل",
        playbackMode: ReciterPlaybackMode = .surahSegments,
        everyAyahFolder: String? = nil,
        quranComId: String? = nil,
        riwayah: String = Reciter.hafs,
        nameUr: String? = nil,
        nameTr: String? = nil,
        subInfoUr: String? = "مرتل",
        subInfoTr: String? = "Murattal"
    ) {
        self.id = id
        self.name = name
        self.englishName = englishName
        self.category = category
        self.subInfo = subInfo
        self.subInfoAr = subInfoAr
        self.playbackMode = playbackMode
        self.everyAyahFolder = everyAyahFolder
        self.quranComId = quranComId
        self.riwayah = riwayah
        self.nameUr = nameUr
        self.nameTr = nameTr
        self.subInfoUr = subInfoUr
        self.subInfoTr = subInfoTr
    }

    public func localizedName(language: String) -> String {
        switch SirajLocalizer.baseLanguage(language) {
        case "ar": return name
        case "ur": return nameUr ?? name
        case "tr": return nameTr ?? englishName
        default: return englishName
        }
    }

    public func localizedSubInfo(language: String) -> String? {
        switch SirajLocalizer.baseLanguage(language) {
        case "ar": return subInfoAr ?? subInfo
        case "ur": return subInfoUr ?? subInfoAr ?? subInfo
        case "tr": return subInfoTr ?? subInfo
        default: return subInfo
        }
    }

    public func shortDisplayName(language: String = "ar") -> String {
        let base = SirajLocalizer.baseLanguage(language)
        let isArUr = base == "ar" || base == "ur"
        switch id {
        case "ar.minshawikids": return isArUr ? "المنشاوي مع الأطفال" : "Minshawi with Kids"
        case "ar.abdulbasitmujawwad": return isArUr ? "عبد الباسط (مجود)" : "Abdul Basit (Mujawwad)"
        case "ar.husarymujawwad": return isArUr ? "الحصري (مجود)" : "Al-Husary (Mujawwad)"
        case "ar.hudhaify": return isArUr ? "علي الحذيفي" : "Ali Al-Huthaify"
        case "ar.ahmedajamy": return isArUr ? "أحمد العجمي" : "Ahmed Al-Ajmi"
        case "ar.tablawi": return isArUr ? "محمد الطبلاوي" : "Mohamed Al-Tablawi"
        default: return localizedName(language: language)
        }
    }

    public var photoAssetName: String? {
        ReciterPhotoCatalog.assetName(for: id)
    }

    public static let defaultReciter = readerReciters[0]

    public static let readerReciters: [Reciter] = [
        Reciter(id: "ar.alafasy", name: "مشاري راشد العفاسي", englishName: "Mishary Rashid Alafasy", playbackMode: .ayahByAyah, everyAyahFolder: "Alafasy_128kbps", quranComId: "7", nameUr: "مشاری راشد العفاسی", nameTr: "Mişari Raşid el-Afasi"),
        Reciter(id: "ar.abdulbasitmurattal", name: "عبد الباسط عبد الصمد", englishName: "Abdul Basit Abdul Samad", playbackMode: .ayahByAyah, everyAyahFolder: "Abdul_Basit_Murattal_192kbps", quranComId: "2", nameUr: "عبد الباسط عبد الصمد", nameTr: "Abdülbasit Abdüssamed"),
        Reciter(id: "ar.abdulbasitmujawwad", name: "عبد الباسط (مجود)", englishName: "Abdul Basit Mujawwad", subInfo: "Mujawwad", subInfoAr: "مجود", playbackMode: .ayahByAyah, everyAyahFolder: "Abdul_Basit_Mujawwad_128kbps", quranComId: "1", nameUr: "عبد الباسط (تجوید)", nameTr: "Abdülbasit Abdüssamed (Mücevved)", subInfoUr: "تجوید", subInfoTr: "Mücevved"),
        Reciter(id: "ar.husary", name: "محمود خليل الحصري", englishName: "Mahmoud Khalil Al-Husary", playbackMode: .ayahByAyah, everyAyahFolder: "Husary_128kbps", quranComId: "6", nameUr: "محمود خلیل الحصری", nameTr: "Mahmud Halil el-Husari"),
        Reciter(id: "ar.husarymujawwad", name: "الحصري (مجود)", englishName: "Mahmoud Al-Husary Mujawwad", subInfo: "Mujawwad", subInfoAr: "مجود", playbackMode: .ayahByAyah, everyAyahFolder: "Husary_Mujawwad_64kbps", nameUr: "الحصری (تجوید)", nameTr: "Mahmud Halil el-Husari (Mücevved)", subInfoUr: "تجوید", subInfoTr: "Mücevved"),
        Reciter(id: "ar.minshawi", name: "محمد صديق المنشاوي", englishName: "Muhammad Siddiq Al-Minshawi", playbackMode: .ayahByAyah, everyAyahFolder: "Minshawy_Murattal_128kbps", quranComId: "9", nameUr: "محمد صدیق المنشاوی", nameTr: "Muhammed Sıddık el-Minşavi"),
        Reciter(id: "ar.minshawikids", name: "المنشاوي مع الأطفال", englishName: "Minshawi with Kids", subInfo: "Teacher / With Kids", subInfoAr: "المصحف المعلم", playbackMode: .ayahByAyah, everyAyahFolder: "Minshawy_Teacher_128kbps", riwayah: "معلم / حفص", nameUr: "المنشاوی (مع اطفال)", nameTr: "Muhammed Sıddık el-Minşavi (Çocuklarla)", subInfoUr: "تعلیمی مصحف", subInfoTr: "Öğretici / Çocuklarla"),
        Reciter(id: "ar.abdurrahmaansudais", name: "عبد الرحمن السديس", englishName: "Abdur-Rahman as-Sudais", playbackMode: .ayahByAyah, everyAyahFolder: "Abdurrahmaan_As-Sudais_192kbps", quranComId: "3", nameUr: "عبد الرحمن السدیس", nameTr: "Abdurrahman es-Sudeys"),
        Reciter(id: "ar.shuraym", name: "سعود الشريم", englishName: "Saud Al-Shuraim", playbackMode: .ayahByAyah, everyAyahFolder: "Saood_ash-Shuraym_128kbps", quranComId: "10", nameUr: "سعود الشریم", nameTr: "Suud eş-Şuraym"),
        Reciter(id: "ar.mahermuaiqly", name: "ماهر المعيقلي", englishName: "Maher Al-Mu'aiqly", playbackMode: .ayahByAyah, everyAyahFolder: "Maher_AlMuaiqly_64kbps", nameUr: "ماہر المعیقلی", nameTr: "Mahir el-Muaykili"),
        Reciter(id: "ar.saadghamidi", name: "سعد الغامدي", englishName: "Saad al Ghamdi", playbackMode: .ayahByAyah, everyAyahFolder: "Ghamadi_40kbps", nameUr: "سعد الغامدی", nameTr: "Saad el-Gamidi"),
        Reciter(id: "ar.yasseraldossari", name: "ياسر الدوسري", englishName: "Yasser ad-Dussary", playbackMode: .ayahByAyah, everyAyahFolder: "Yasser_Ad-Dussary_128kbps", nameUr: "یاسر الدوسری", nameTr: "Yaser ed-Devseri"),
        Reciter(id: "ar.abubakralshatri", name: "أبو بكر الشاطري", englishName: "Abu Bakr al-Shatri", playbackMode: .ayahByAyah, everyAyahFolder: "Abu_Bakr_Ash-Shaatree_128kbps", quranComId: "4", nameUr: "ابو بکر الشاطری", nameTr: "Ebu Bekir eş-Şatri"),
        Reciter(id: "ar.ahmedalnufeis", name: "أحمد النفيس", englishName: "Ahmed Alnufais", playbackMode: .surahSegments, quranComId: "ar.ahmedalnafis", nameUr: "احمد النفیس", nameTr: "Ahmed en-Nufeyis"),
        Reciter(id: "ar.bandarbaleela", name: "بندر بليلة", englishName: "Bandar Baleela", playbackMode: .ayahByAyah, everyAyahFolder: "Bandar_Balila_64kbps", quranComId: "bandar_baleela", nameUr: "بندر بلیلۃ", nameTr: "Bender Belile"),
        Reciter(id: "ar.hanirifai", name: "هاني الرفاعي", englishName: "Hani ar-Rifai", playbackMode: .ayahByAyah, everyAyahFolder: "Hani_Rifai_192kbps", quranComId: "5", nameUr: "ہانی الرفاعی", nameTr: "Hani er-Rifai"),
        Reciter(id: "ar.khalidaljalil", name: "خالد الجليل", englishName: "Khalid Al-Jalil", playbackMode: .surahSegments, quranComId: "khalid_jaleel", nameUr: "خالد الجلیل", nameTr: "Halid el-Celil"),
        Reciter(id: "ar.abdullahbasfar", name: "عبد الله بصفر", englishName: "Abdullah Basfar", playbackMode: .ayahByAyah, everyAyahFolder: "Abdullah_Basfar_192kbps", nameUr: "عبد اللہ بصفر", nameTr: "Abdullah Basfar"),
        Reciter(id: "ar.abdullahmatroud", name: "عبد الله مطرود", englishName: "Abdullah Matroud", playbackMode: .ayahByAyah, everyAyahFolder: "Abdullah_Matroud_128kbps", quranComId: "matroud", nameUr: "عبد اللہ مطرود", nameTr: "Abdullah Matrud"),
        Reciter(id: "ar.alihajjajalsouasi", name: "علي حجاج السويسي", englishName: "Ali Hajjaj Alsouasi", playbackMode: .ayahByAyah, everyAyahFolder: "Ali_Hajjaj_AlSuesy_128kbps", quranComId: "suwaisi", nameUr: "علی حجاج السویسی", nameTr: "Ali Haccac es-Suveysi"),
        Reciter(id: "ar.azizalili", name: "عزيز عليلي", englishName: "Aziz Alili", playbackMode: .ayahByAyah, everyAyahFolder: "aziz_alili_128kbps", quranComId: "alili", nameUr: "عزیز علیلی", nameTr: "Aziz Alili"),
        Reciter(id: "ar.mahmoodalibana", name: "محمود علي البنا", englishName: "Mahmood Ali Al-Bana", playbackMode: .ayahByAyah, everyAyahFolder: "mahmoud_ali_al_banna_32kbps", quranComId: "banna", nameUr: "محمود علی البنا", nameTr: "Mahmud Ali el-Benna"),
        Reciter(id: "ar.tablawi", name: "محمد الطبلاوي", englishName: "Mohamed al-Tablawi", playbackMode: .ayahByAyah, everyAyahFolder: "Mohammad_al_Tablaway_128kbps", nameUr: "محمد الطبلاوی", nameTr: "Muhammed Mahmud et-Tablavi"),
        Reciter(id: "ar.mostafaismaeel", name: "مصطفى إسماعيل", englishName: "Mostafa Ismaeel", playbackMode: .ayahByAyah, everyAyahFolder: "Mustafa_Ismail_48kbps", quranComId: "ismail", nameUr: "مصطفیٰ اسماعیل", nameTr: "Mustafa İsmail"),
        Reciter(id: "ar.muhammadjibreel", name: "محمد جبريل", englishName: "Muhammad Jibreel", playbackMode: .ayahByAyah, everyAyahFolder: "Muhammad_Jibreel_128kbps", quranComId: "jibreel", nameUr: "محمد جبریل", nameTr: "Muhammed Cibril"),
        Reciter(id: "ar.qatami", name: "ناصر القطامي", englishName: "Nasser Al Qatami", playbackMode: .ayahByAyah, everyAyahFolder: "Nasser_Alqatami_128kbps", quranComId: "qatami", nameUr: "ناصر القطامی", nameTr: "Nasır el-Kıtami"),
        Reciter(id: "ar.sahlyasin", name: "سهل ياسين", englishName: "Sahl Yasin", playbackMode: .ayahByAyah, everyAyahFolder: "Sahl_Yassin_128kbps", quranComId: "yasin", nameUr: "سہل یاسین", nameTr: "Sehl Yasin"),
        Reciter(id: "ar.alijaber", name: "علي جابر", englishName: "Ali Jaber", playbackMode: .ayahByAyah, everyAyahFolder: "Ali_Jaber_64kbps", quranComId: "jaber", nameUr: "علی جابر", nameTr: "Ali Cabir"),
        Reciter(id: "ar.hudhaify", name: "علي الحذيفي", englishName: "Ali Al-Huthaify", playbackMode: .ayahByAyah, everyAyahFolder: "Hudhaify_128kbps", quranComId: "hudhaify", nameUr: "علی الحذیفی", nameTr: "Ali Abdurrahman el-Huzeyfi"),
        Reciter(id: "ar.ahmedajamy", name: "أحمد العجمي", englishName: "Ahmed Al-Ajmi", playbackMode: .ayahByAyah, everyAyahFolder: "ahmed_ibn_ali_al_ajamy_128kbps", quranComId: "ajamy", nameUr: "احمد العجمی", nameTr: "Ahmed el-Acemi"),
        Reciter(id: "ar.abdurrashidsufi", name: "عبد الرشيد صوفي", englishName: "Abdul Rashid Ali Sufi", playbackMode: .surahSegments, quranComId: "soufi", riwayah: "حفص / السوسي", nameUr: "عبد الرشید صوفی", nameTr: "Abdürreşid Sufi"),
        Reciter(id: "ar.muhammadayyoub", name: "محمد أيوب", englishName: "Muhammad Ayyub", playbackMode: .ayahByAyah, everyAyahFolder: "Muhammad_Ayyoub_128kbps", quranComId: "ayyoub", nameUr: "محمد ایوب", nameTr: "Muhammed Eyyub"),
        Reciter(id: "ar.muhammadalluhaidan", name: "محمد اللحيدان", englishName: "Muhammad Al-Luhaidan", playbackMode: .surahSegments, quranComId: "luhaidan", nameUr: "محمد اللحیدان", nameTr: "Muhammed el-Luhaydan"),
        Reciter(id: "ar.abdallahkamel", name: "عبد الله كامل", englishName: "Abdallah Kamel", playbackMode: .surahSegments, quranComId: "kamel", nameUr: "عبد اللہ کامل", nameTr: "Abdullah Kamil")
    ]

    public static let listeningOnlyReciters: [Reciter] = [
        Reciter(id: "ar.alaaaql", name: "علاء عقل", englishName: "Alaa Aql", nameUr: "علاء عقل", nameTr: "Alâ Akl"),
        Reciter(id: "ar.husarywarsh", name: "الحصري (ورش)", englishName: "Al-Husary (Warsh)", riwayah: warsh, nameUr: "الحصری (ورش)", nameTr: "el-Husari (Verş)"),
        Reciter(id: "ar.husaryqalun", name: "الحصري (قالون)", englishName: "Al-Husary (Qalun)", riwayah: qalun, nameUr: "الحصری (قالون)", nameTr: "el-Husari (Kalun)"),
        Reciter(id: "ar.abdulbasitwarsh", name: "عبد الباسط (ورش)", englishName: "Abdul Basit (Warsh)", riwayah: warsh, nameUr: "عبد الباسط (ورش)", nameTr: "Abdülbasit (Verş)"),
        Reciter(id: "ar.hudhaifyqalun", name: "علي الحذيفي (قالون)", englishName: "Ali Al-Huthaify (Qalun)", riwayah: qalun, nameUr: "علی الحذیفی (قالون)", nameTr: "Ali el-Huzeyfi (Kalun)"),
        Reciter(id: "ar.idreesabkar", name: "إدريس أبكر", englishName: "Idris Abkar", nameUr: "ادریس ابکر", nameTr: "İdris Ebker"),
        Reciter(id: "ar.muhaisni", name: "محمد المحيسني", englishName: "Muhammad al-Muhaisni", nameUr: "محمد المحیسنی", nameTr: "Muhammed el-Muhaysini"),
        Reciter(id: "ar.faresabbad", name: "فارس عباد", englishName: "Fares Abbad", nameUr: "فارس عباد", nameTr: "Faris Abbad"),
        Reciter(id: "ar.juhany", name: "عبد الله الجهني", englishName: "Abdullah al-Juhany", nameUr: "عبد اللہ الجہنی", nameTr: "Abdullah el-Cüheni"),
        Reciter(id: "ar.salahbukhatir", name: "صلاح بو خاطر", englishName: "Salah Bukhatir", nameUr: "صلاح بو خاطر", nameTr: "Salah Buhatır"),
        Reciter(id: "ar.thubaity", name: "عبد الباري الثبيتي", englishName: "Abdul Bari ath-Thubaity", nameUr: "عبد الباری الثبیتی", nameTr: "Abdülbari es-Sübeyti"),
        Reciter(id: "ar.budair", name: "صلاح البدير", englishName: "Salah al-Budair", nameUr: "صلاح البدیر", nameTr: "Salah el-Budeyr"),
        Reciter(id: "ar.khalidqahtani", name: "خالد القحطاني", englishName: "Khalid al-Qahtani", nameUr: "خالد القحطانی", nameTr: "Halid el-Kahtani"),
        Reciter(id: "ar.mansoursalimi", name: "منصور السالمي", englishName: "Mansour as-Salimi", nameUr: "منصور السالمی", nameTr: "Mansur es-Salimi"),
        Reciter(id: "ar.raadkurdi", name: "رعد محمد الكردي", englishName: "Raad Muhammad al-Kurdi", nameUr: "رعد محمد الکردی", nameTr: "Rad Muhammed el-Kürdi"),
        Reciter(id: "ar.kalbani", name: "عادل الكلباني", englishName: "Adel al-Kalbani", nameUr: "عادل الکلبانی", nameTr: "Adil el-Kelbani"),
        Reciter(id: "ar.abdulazizahmad", name: "عبد العزيز الأحمد", englishName: "Abdulaziz al-Ahmad", nameUr: "عبد العزیز الاحمد", nameTr: "Abdülaziz el-Ahmed"),
        Reciter(id: "ar.hawashi", name: "أحمد الحواشي", englishName: "Ahmad al-Hawashi", nameUr: "احمد الحواشی", nameTr: "Ahmed el-Havaşi"),
        Reciter(id: "ar.wadeeyamani", name: "وديع اليمني", englishName: "Wadee al-Yamani", nameUr: "ودیع الیمنی", nameTr: "Vedi el-Yemeni"),
        Reciter(id: "ar.oosi", name: "عبد الرحمن العوسي", englishName: "Abdulrahman al-Ossi", nameUr: "عبد الرحمن العوسی", nameTr: "Abdurrahman el-Avsi"),
        Reciter(id: "ar.yasserqurashi", name: "ياسر القرشي", englishName: "Yasser al-Qurashi", nameUr: "یاسر القرشی", nameTr: "Yasir el-Kureşi"),
        Reciter(id: "ar.abdulmohsenqasim", name: "عبد المحسن القاسم", englishName: "Abdulmohsen al-Qasim", nameUr: "عبد المحسن القاسم", nameTr: "Abdülmuhsin el-Kasım"),
        Reciter(id: "ar.khayyat", name: "عبد الله خياط", englishName: "Abdullah Khayyat", nameUr: "عبد اللہ خیاط", nameTr: "Abdullah Hayyat"),
        Reciter(id: "ar.obaikan", name: "عبد المحسن العبيكان", englishName: "Abdulmohsen al-Obaikan", nameUr: "عبد المحسن العبیکان", nameTr: "Abdülmuhsin el-Ubeykan"),
        Reciter(id: "ar.abdulazizzahrani", name: "عبد العزيز الزهراني", englishName: "Abdulaziz az-Zahrani", nameUr: "عبد العزیز الزہرانی", nameTr: "Abdülaziz ez-Zehrani"),
        Reciter(id: "ar.alaqmi", name: "أكرم العلاقمي", englishName: "Akram al-Alaqmi", nameUr: "اکرم العلاقمی", nameTr: "Ekrem el-Alakmi"),
        Reciter(id: "ar.abdulrahmanmajed", name: "عبد الرحمن الماجد", englishName: "Abdulrahman al-Majed", nameUr: "عبد الرحمن الماجد", nameTr: "Abdurrahman el-Mâcid"),
        Reciter(id: "ar.ibrahimdosari", name: "إبراهيم الدوسري", englishName: "Ibrahim ad-Dosari", nameUr: "ابراہیم الدوسری", nameTr: "İbrahim ed-Devseri"),
        Reciter(id: "ar.hatemwaer", name: "حاتم فريد الواعر", englishName: "Hatem Fareed al-Waer", nameUr: "حاتم فرید الواعر", nameTr: "Hatim Ferid el-Vair"),
        Reciter(id: "ar.rashadshareef", name: "محمد رشاد الشريف", englishName: "Muhammad Rashad ash-Shareef", nameUr: "محمد رشاد الشریف", nameTr: "Muhammed Reşad eş-Şerif"),
        Reciter(id: "ar.daghistani", name: "زكي داغستاني", englishName: "Zaki Daghistani", nameUr: "زکی داغستانی", nameTr: "Zeki Dağıstani"),
        Reciter(id: "ar.habdan", name: "صالح الهبدان", englishName: "Saleh al-Habdan", nameUr: "صالح الہبدان", nameTr: "Salih el-Habdan"),
        Reciter(id: "ar.sayegh", name: "توفيق الصايغ", englishName: "Tawfeeq as-Sayegh", nameUr: "توفیق الصایغ", nameTr: "Tevfik es-Sayığ"),
        Reciter(id: "ar.saltani", name: "مفتاح السلطني", englishName: "Muftah as-Saltani", nameUr: "مفتاح السلطنی", nameTr: "Miftah es-Saltani"),
        Reciter(id: "ar.yassersalama", name: "ياسر سلامة", englishName: "Yasser Salama", nameUr: "یاسر سلامہ", nameTr: "Yasir Selame"),
        Reciter(id: "ar.nassermajed", name: "ناصر الماجد", englishName: "Nasser al-Majed", nameUr: "ناصر الماجد", nameTr: "Nasır el-Mâcid"),
        Reciter(id: "ar.arkani", name: "عبد الولي الأركاني", englishName: "Abdulwali al-Arkani", nameUr: "عبد الولی الارکانی", nameTr: "Abdülveli el-Erkani"),
        Reciter(id: "ar.abdulwadoodhaneef", name: "عبد الودود حنيف", englishName: "Abdulwadood Haneef", nameUr: "عبد الودود حنیف", nameTr: "Abdülvedud Hanif"),
        Reciter(id: "ar.shoaey", name: "يوسف الشويعي", englishName: "Yousef ash-Shoaey", nameUr: "یوسف الشویعی", nameTr: "Yusuf eş-Şuveyi"),
        Reciter(id: "ar.majedzamil", name: "ماجد الزامل", englishName: "Majed az-Zamil", nameUr: "ماجد الزامل", nameTr: "Mâcid ez-Zâmil"),
        Reciter(id: "ar.kandari", name: "عبد الله الكندري", englishName: "Abdullah al-Kandari", nameUr: "عبد اللہ الکندری", nameTr: "Abdullah el-Kenderi")
    ]

    public static let allListeningReciters: [Reciter] = readerReciters + listeningOnlyReciters

    public static func byId(_ id: String) -> Reciter {
        allListeningReciters.first(where: { $0.id == id }) ?? defaultReciter
    }
}

public enum ReciterPhotoCatalog {
    private static let map: [String: String] = [
        "ar.alafasy": "reciter_alafasy",
        "ar.abdulbasitmurattal": "reciter_abdulbasit",
        "ar.abdulbasitmujawwad": "reciter_abdulbasit",
        "ar.abdulbasitwarsh": "reciter_abdulbasit",
        "ar.husary": "reciter_husary",
        "ar.husarymujawwad": "reciter_husary",
        "ar.husarywarsh": "reciter_husary",
        "ar.husaryqalun": "reciter_husary",
        "ar.minshawi": "reciter_minshawi",
        "ar.minshawikids": "reciter_minshawi",
        "ar.abdurrahmaansudais": "reciter_sudais",
        "ar.shuraym": "reciter_shuraym",
        "ar.mahermuaiqly": "reciter_maher",
        "ar.saadghamidi": "reciter_ghamidi",
        "ar.yasseraldossari": "reciter_dossari",
        "ar.abubakralshatri": "reciter_shatri",
        "ar.ahmedalnufeis": "reciter_nufeis",
        "ar.bandarbaleela": "reciter_baleela",
        "ar.hanirifai": "reciter_rifai",
        "ar.khalidaljalil": "reciter_jalil",
        "ar.abdullahbasfar": "reciter_basfar",
        "ar.abdullahmatroud": "reciter_matroud",
        "ar.alihajjajalsouasi": "reciter_souasi",
        "ar.azizalili": "reciter_alili",
        "ar.mahmoodalibana": "reciter_bana",
        "ar.tablawi": "reciter_tablawi",
        "ar.mostafaismaeel": "reciter_ismaeel",
        "ar.muhammadjibreel": "reciter_jibreel",
        "ar.qatami": "reciter_qatami",
        "ar.sahlyasin": "reciter_yasin",
        "ar.alijaber": "reciter_alijaber",
        "ar.hudhaify": "reciter_hudhaify",
        "ar.hudhaifyqalun": "reciter_hudhaify",
        "ar.ahmedajamy": "reciter_ajamy",
        "ar.abdurrashidsufi": "reciter_sufi",
        "ar.muhammadayyoub": "reciter_ayyoub",
        "ar.muhammadalluhaidan": "reciter_luhaidan",
        "ar.abdallahkamel": "reciter_kamel",
        "ar.mansourzahrani": "reciter_mansour_zahrani",
        "ar.naqshbandi": "reciter_naqshbandi",
        "en.yusufislam": "reciter_yusuf_islam",
        "ar.alaaaql": "reciter_alaa_aql",
        "ar.idreesabkar": "reciter_idrees_abkar",
        "ar.muhaisni": "reciter_muhaisni",
        "ar.faresabbad": "reciter_fares_abbad",
        "ar.juhany": "reciter_juhany",
        "ar.salahbukhatir": "reciter_salah_bukhatir",
        "ar.thubaity": "reciter_thubaity",
        "ar.budair": "reciter_budair",
        "ar.khalidqahtani": "reciter_khalid_qahtani",
        "ar.raadkurdi": "reciter_raad_kurdi",
        "ar.kalbani": "reciter_kalbani",
        "ar.abdulazizahmad": "reciter_abdulaziz_ahmad",
        "ar.hawashi": "reciter_hawashi",
        "ar.wadeeyamani": "reciter_wadee_yamani",
        "ar.oosi": "reciter_oosi",
        "ar.yasserqurashi": "reciter_yasser_qurashi",
        "ar.abdulmohsenqasim": "reciter_abdulmohsen_qasim",
        "ar.khayyat": "reciter_khayyat",
        "ar.abdulazizzahrani": "reciter_abdulaziz_zahrani",
        "ar.alaqmi": "reciter_alaqmi",
        "ar.ibrahimdosari": "reciter_ibrahim_dosari",
        "ar.hatemwaer": "reciter_hatem_waer",
        "ar.rashadshareef": "reciter_rashad_shareef",
        "ar.daghistani": "reciter_daghistani",
        "ar.sayegh": "reciter_sayegh",
        "ar.yassersalama": "reciter_yasser_salama",
        "ar.arkani": "reciter_arkani",
        "ar.abdulwadoodhaneef": "reciter_abdulwadood_haneef",
        "ar.shoaey": "reciter_shoaey",
        "ar.kandari": "reciter_kandari",
        "ar.obaikan": "reciter_obaikan",
        "ar.habdan": "reciter_habdan",
        "ar.mansoursalimi": "reciter_mansour_salimi",
        "ar.majedzamil": "reciter_majed_zamil",
        "ar.saltani": "reciter_saltani",
        "ar.nassermajed": "reciter_nasser_majed",
        "ar.abdulrahmanmajed": "reciter_abdulrahman_majed",
        "abdul-azim-zaher": "reciter_abdul_azim_zaher",
        "abdul-rahman-mosad": "reciter_abdulrahman_mosad",
        "omar-diaa-al-din": "reciter_omar_diaa",
        "islam-sobhi": "reciter_islam_sobhi",
        "muhammad-refaat": "reciter_refaat",
        "younes-souilass": "reciter_souilass"
    ]

    public static func assetName(for id: String) -> String? {
        map[id]
    }
}

public enum ReciterAudioURLs {
    private static let everyAyahFolders: [String: String] = [
        "ar.alafasy": "Alafasy_128kbps",
        "ar.abdulbasitmurattal": "Abdul_Basit_Murattal_192kbps",
        "ar.abdulbasitmujawwad": "Abdul_Basit_Mujawwad_128kbps",
        "ar.husary": "Husary_128kbps",
        "ar.husarymujawwad": "Husary_Mujawwad_64kbps",
        "ar.minshawi": "Minshawy_Murattal_128kbps",
        "ar.minshawikids": "Minshawy_Teacher_128kbps",
        "ar.abdurrahmaansudais": "Abdurrahmaan_As-Sudais_192kbps",
        "ar.shuraym": "Saood_ash-Shuraym_128kbps",
        "ar.mahermuaiqly": "Maher_AlMuaiqly_64kbps",
        "ar.saadghamidi": "Ghamadi_40kbps",
        "ar.yasseraldossari": "Yasser_Ad-Dussary_128kbps",
        "ar.abubakralshatri": "Abu_Bakr_Ash-Shaatree_128kbps",
        "ar.bandarbaleela": "Bandar_Balila_64kbps",
        "ar.hanirifai": "Hani_Rifai_192kbps",
        "ar.abdullahbasfar": "Abdullah_Basfar_192kbps",
        "ar.abdullahmatroud": "Abdullah_Matroud_128kbps",
        "ar.alihajjajalsouasi": "Ali_Hajjaj_AlSuesy_128kbps",
        "ar.azizalili": "aziz_alili_128kbps",
        "ar.mahmoodalibana": "mahmoud_ali_al_banna_32kbps",
        "ar.tablawi": "Mohammad_al_Tablaway_128kbps",
        "ar.mostafaismaeel": "Mustafa_Ismail_48kbps",
        "ar.muhammadjibreel": "Muhammad_Jibreel_128kbps",
        "ar.qatami": "Nasser_Alqatami_128kbps",
        "ar.sahlyasin": "Sahl_Yassin_128kbps",
        "ar.alijaber": "Ali_Jaber_64kbps",
        "ar.hudhaify": "Hudhaify_128kbps",
        "ar.ahmedajamy": "ahmed_ibn_ali_al_ajamy_128kbps",
        "ar.muhammadayyoub": "Muhammad_Ayyoub_128kbps"
    ]

    private static let surahServers: [String: String] = [
        "ar.alafasy": "https://audio-cdn.tarteel.ai/quran/surah/alafasy/murattal/mp3/",
        "ar.abdulbasitmurattal": "https://audio-cdn.tarteel.ai/quran/surah/abdulBasit/murattal/mp3/",
        "ar.abdulbasitmujawwad": "https://server7.mp3quran.net/basit/Almusshaf-Al-Mojawwad/",
        "ar.husary": "https://download.quranicaudio.com/quran/mahmood_khaleel_al-husaree/",
        "ar.husarymujawwad": "https://audio-cdn.tarteel.ai/quran/surah/husary/mujawwad/mp3/",
        "ar.minshawi": "https://download.quranicaudio.com/quran/muhammad_siddeeq_al-minshaawee/",
        "ar.minshawikids": "https://download.quranicaudio.com/qdc/siddiq_minshawi/kids_repeat/",
        "ar.abdurrahmaansudais": "https://download.quranicaudio.com/quran/abdurrahmaan_as-sudays/",
        "ar.shuraym": "https://download.quranicaudio.com/quran/sa3ood_al-shuraym/",
        "ar.mahermuaiqly": "https://download.quranicaudio.com/quran/maher_almu3aiqly/year1440/",
        "ar.saadghamidi": "https://download.quranicaudio.com/quran/sa3d_al-ghaamidi/complete/",
        "ar.yasseraldossari": "https://audio-cdn.tarteel.ai/quran/surah/yasserAlDosari/murattal/mp3/",
        "ar.abubakralshatri": "https://download.quranicaudio.com/quran/abu_bakr_ash-shaatree/",
        "ar.ahmedalnufeis": "https://audio-cdn.tarteel.ai/quran/surah/alnufais/murattal/mp3/",
        "ar.bandarbaleela": "https://download.quranicaudio.com/quran/bandar_baleela/complete/",
        "ar.hanirifai": "https://server8.mp3quran.net/hani/",
        "ar.khalidaljalil": "https://download.quranicaudio.com/qdc/khalid_jalil/murattal/mp3/",
        "ar.abdullahbasfar": "https://download.quranicaudio.com/quran/abdullaah_basfar/",
        "ar.abdullahmatroud": "https://download.quranicaudio.com/quran/abdullah_matroud/",
        "ar.alihajjajalsouasi": "https://download.quranicaudio.com/quran/ali_hajjaj_alsouasi/",
        "ar.azizalili": "https://download.quranicaudio.com/quran/aziz_alili/",
        "ar.mahmoodalibana": "https://download.quranicaudio.com/quran/mahmood_ali_albana/",
        "ar.tablawi": "https://server12.mp3quran.net/tblawi/",
        "ar.mostafaismaeel": "https://download.quranicaudio.com/quran/mostafa_ismaeel/",
        "ar.muhammadjibreel": "https://download.quranicaudio.com/quran/muhammad_jibreel/complete/",
        "ar.qatami": "https://download.quranicaudio.com/quran/nasser_bin_ali_alqatami/",
        "ar.sahlyasin": "https://download.quranicaudio.com/quran/sahl_yaaseen/",
        "ar.alijaber": "https://server11.mp3quran.net/a_jbr/",
        "ar.hudhaify": "https://download.quranicaudio.com/quran/huthayfi/",
        "ar.ahmedajamy": "https://download.quranicaudio.com/quran/ahmed_ibn_3ali_al-3ajamy/",
        "ar.abdurrashidsufi": "https://server16.mp3quran.net/soufi/Rewayat-Hafs-A-n-Assem/",
        "ar.muhammadayyoub": "https://download.quranicaudio.com/quran/muhammad_ayyoob/",
        "ar.muhammadalluhaidan": "https://server8.mp3quran.net/lhdan/",
        "ar.abdallahkamel": "https://server16.mp3quran.net/kamel/Rewayat-Hafs-A-n-Assem/",
        "ar.alaaaql": "https://media.way2quran.com/alaa-aql/hafs-an-asim/",
        "ar.husarywarsh": "https://cdn.mp3quran.net/audio/mahmoud-husary/r3/",
        "ar.husaryqalun": "https://cdn.mp3quran.net/audio/mahmoud-husary/r5/",
        "ar.abdulbasitwarsh": "https://cdn.mp3quran.net/audio/abdulbasit-abdulsamad/r2/",
        "ar.hudhaifyqalun": "https://cdn.mp3quran.net/audio/ali-hudhaifi/r2/",
        "ar.idreesabkar": "https://cdn.mp3quran.net/audio/idrees-abkar/r1/",
        "ar.muhaisni": "https://cdn.mp3quran.net/audio/muhammad-muhaisni/r1/",
        "ar.faresabbad": "https://cdn.mp3quran.net/audio/fares-abbad/r1/",
        "ar.juhany": "https://cdn.mp3quran.net/audio/abdullah-juhani/r1/",
        "ar.salahbukhatir": "https://cdn.mp3quran.net/audio/salah-bukhatir/r1/",
        "ar.thubaity": "https://cdn.mp3quran.net/audio/abdulbari-thubaiti/r1/",
        "ar.budair": "https://cdn.mp3quran.net/audio/salah-budair/r1/",
        "ar.khalidqahtani": "https://cdn.mp3quran.net/audio/khalid-qahtani/r1/",
        "ar.mansoursalimi": "https://cdn.mp3quran.net/audio/mansour-salimi/r1/",
        "ar.raadkurdi": "https://cdn.mp3quran.net/audio/raad-kurdi/r1/",
        "ar.kalbani": "https://cdn.mp3quran.net/audio/adel-kalbani/r1/",
        "ar.abdulazizahmad": "https://cdn.mp3quran.net/audio/abdulaziz-ahmad/r1/",
        "ar.hawashi": "https://cdn.mp3quran.net/audio/ahmad-hawashi/r1/",
        "ar.wadeeyamani": "https://cdn.mp3quran.net/audio/wadee-yamani/r1/",
        "ar.oosi": "https://cdn.mp3quran.net/audio/abdulrahman-oosi/r1/",
        "ar.yasserqurashi": "https://cdn.mp3quran.net/audio/yasser-qurashi/r1/",
        "ar.abdulmohsenqasim": "https://cdn.mp3quran.net/audio/abdulmohsen-qasim/r1/",
        "ar.khayyat": "https://cdn.mp3quran.net/audio/abdullah-khayyat/r1/",
        "ar.obaikan": "https://cdn.mp3quran.net/audio/abdulmohsen-obaikan/r1/",
        "ar.abdulazizzahrani": "https://cdn.mp3quran.net/audio/abdulaziz-zahrani/r1/",
        "ar.alaqmi": "https://cdn.mp3quran.net/audio/akram-alaqmi/r1/",
        "ar.abdulrahmanmajed": "https://cdn.mp3quran.net/audio/abdulrahman-majed/r1/",
        "ar.ibrahimdosari": "https://cdn.mp3quran.net/audio/ibrahim-dosari/r2/",
        "ar.hatemwaer": "https://cdn.mp3quran.net/audio/hatem-waer/r1/",
        "ar.rashadshareef": "https://cdn.mp3quran.net/audio/muhammad-shareef/r1/",
        "ar.daghistani": "https://cdn.mp3quran.net/audio/zaki-daghistani/r1/",
        "ar.habdan": "https://cdn.mp3quran.net/audio/saleh-habdan/r1/",
        "ar.sayegh": "https://cdn.mp3quran.net/audio/tawfeeq-sayegh/r1/",
        "ar.saltani": "https://cdn.mp3quran.net/audio/muftah-saltani/r3/",
        "ar.yassersalama": "https://cdn.mp3quran.net/audio/yasser-salama/r1/",
        "ar.nassermajed": "https://cdn.mp3quran.net/audio/nasser-majed/r1/",
        "ar.arkani": "https://cdn.mp3quran.net/audio/abdulwali-arkani/r1/",
        "ar.abdulwadoodhaneef": "https://cdn.mp3quran.net/audio/abdulwadood-haneef/r1/",
        "ar.shoaey": "https://cdn.mp3quran.net/audio/yousef-shoaey/r1/",
        "ar.majedzamil": "https://cdn.mp3quran.net/audio/majed-zamil/r1/",
        "ar.kandari": "https://cdn.mp3quran.net/audio/abdullah-kandari/r1/"
    ]

    // Continuous recordings for reciters whose reader files are stitched per ayah with silent gaps.
    private static let listeningServers: [String: [String]] = [
        "ar.alafasy": [
            "https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/",
            "https://cdn.mp3quran.net/audio/mishary-alafasy/r1/"
        ],
        "ar.mahermuaiqly": [
            "https://audio-cdn.tarteel.ai/quran/surah/maherAlMuaiqly/murattal/mp3/",
            "https://cdn.mp3quran.net/audio/maher-muaiqly/r1/"
        ]
    ]

    public static func hasAyahAudio(_ reciterId: String) -> Bool {
        everyAyahFolders[reciterId] != nil
    }

    public static func ayahAudioURL(reciterId: String, surah: Int, ayah: Int) -> String {
        if let folder = everyAyahFolders[reciterId] {
            let s3 = String(format: "%03d", surah)
            let a3 = String(format: "%03d", ayah)
            return "https://everyayah.com/data/\(folder)/\(s3)\(a3).mp3"
        }
        return surahAudioURL(reciterId: reciterId, surah: surah)
    }

    public static func surahAudioURL(reciterId: String, surah: Int) -> String {
        surahFile(server: surahServers[reciterId] ?? "https://server8.mp3quran.net/afs/", surah: surah)
    }

    public static func listeningSurahURLs(reciterId: String, surah: Int) -> [String] {
        if let list = listeningServers[reciterId] {
            return list.map { surahFile(server: $0, surah: surah) }
        }
        return [surahAudioURL(reciterId: reciterId, surah: surah)]
    }

    private static func surahFile(server: String, surah: Int) -> String {
        // quranicaudio's qdc/ tree uses unpadded filenames (1.mp3, not 001.mp3).
        let name = server.contains("quranicaudio.com/qdc/") ? "\(surah)" : String(format: "%03d", surah)
        return "\(server)\(name).mp3"
    }
}

public enum AmbientSound: String, CaseIterable, Codable, Sendable, Identifiable {
    case rain
    case waves
    case stream
    case birds
    case night
    case wind

    public var id: String { rawValue }

    public var fileName: String { "\(rawValue).m4a" }

    public var bytes: Int64 {
        switch self {
        case .rain: return 531_333
        case .waves: return 734_293
        case .stream: return 686_241
        case .birds: return 733_508
        case .night: return 675_879
        case .wind: return 445_779
        }
    }

    public var assetPath: String { "ambient/\(fileName)" }
    public var cdnURL: String { SirajAssetURLs.cdn(assetPath).absoluteString }
    public var rawURL: String { SirajAssetURLs.raw(assetPath).absoluteString }
    public var iconAssetName: String { "ic_ambient_\(rawValue)" }
    public var labelKey: String { "ambient_\(rawValue)" }
}

public struct RareTrack: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let collectionId: String
    public let surahs: [Int]
    public let isWholeSurah: Bool
    public let path: String
    public let bytes: Int64
    public let durationSec: Int
    public let part: Int
    public let externalUrl: String?

    public init(
        collectionId: String,
        surahs: [Int],
        isWholeSurah: Bool,
        path: String,
        bytes: Int64,
        durationSec: Int,
        part: Int = 0,
        externalUrl: String? = nil
    ) {
        self.collectionId = collectionId
        self.surahs = surahs
        self.isWholeSurah = isWholeSurah
        self.path = path
        self.bytes = bytes
        self.durationSec = durationSec
        self.part = part
        self.externalUrl = externalUrl
    }

    private var remoteName: String {
        path.split(separator: "/").last.map(String.init) ?? path
    }

    public var fileName: String { "\(collectionId)-\(remoteName)" }
    public var id: String {
        let stem = remoteName.hasSuffix(".mp3") ? String(remoteName.dropLast(4)) : remoteName
        return "\(collectionId)/\(stem)"
    }
    public var url: String { externalUrl ?? SirajAssetURLs.cdn(path).absoluteString }
    public var fallbackUrl: String { externalUrl ?? SirajAssetURLs.raw(path).absoluteString }
}

public struct RareCollection: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let id: String
    public let nameAr: String
    public let nameEn: String
    public let nameTr: String
    public let nameUr: String
    public let photoAsset: String
    public let tracks: [RareTrack]
    public let isRare: Bool
    public let riwayah: String

    public init(
        id: String,
        nameAr: String,
        nameEn: String,
        nameTr: String,
        nameUr: String,
        photoAsset: String,
        tracks: [RareTrack],
        isRare: Bool = true,
        riwayah: String = Reciter.hafs
    ) {
        self.id = id
        self.nameAr = nameAr
        self.nameEn = nameEn
        self.nameTr = nameTr
        self.nameUr = nameUr
        self.photoAsset = photoAsset
        self.tracks = tracks
        self.isRare = isRare
        self.riwayah = riwayah
    }

    public func localizedName(language: String) -> String {
        switch SirajLocalizer.baseLanguage(language) {
        case "ar": return nameAr
        case "tr": return nameTr
        case "ur": return nameUr
        default: return nameEn
        }
    }

    public var totalSeconds: Int { tracks.reduce(0) { $0 + $1.durationSec } }
    public var totalBytes: Int64 { tracks.reduce(0) { $0 + $1.bytes } }
    public var surahCount: Int { Set(tracks.flatMap(\.surahs)).count }
}

public enum ListeningCatalog {
    private static func zaher(_ surahs: [Int], _ file: String, _ bytes: Int64, _ sec: Int, whole: Bool = false) -> RareTrack {
        RareTrack(collectionId: "abdul-azim-zaher", surahs: surahs, isWholeSurah: whole, path: "audio/recitations/abdul-azim-zaher/\(file)", bytes: bytes, durationSec: sec)
    }

    private static func w2q(_ cid: String, _ slug: String, _ surah: Int, _ name: String, _ bytes: Int64, _ sec: Int, whole: Bool = false, part: Int = 0) -> RareTrack {
        RareTrack(collectionId: cid, surahs: [surah], isWholeSurah: whole, path: "way2quran/\(slug)/\(name).mp3", bytes: bytes, durationSec: sec, part: part, externalUrl: "https://media.way2quran.com/\(slug)/hafs-an-asim/\(name).mp3")
    }

    private static func mp3q(_ cid: String, _ server: String, _ surah: Int, _ bytes: Int64, _ sec: Int) -> RareTrack {
        let name = String(format: "%03d", surah)
        return RareTrack(collectionId: cid, surahs: [surah], isWholeSurah: true, path: "mp3quran/\(cid)/\(name).mp3", bytes: bytes, durationSec: sec, externalUrl: "\(server)\(name).mp3")
    }

    public static let abdulAzimZaher = RareCollection(
        id: "abdul-azim-zaher",
        nameAr: "الشيخ عبد العظيم زاهر",
        nameEn: "Sheikh Abdul Azim Zaher",
        nameTr: "Şeyh Abdülazim Zahir",
        nameUr: "شیخ عبد العظیم زاہر",
        photoAsset: "reciter_abdul_azim_zaher",
        tracks: [
            zaher([16], "016-an-nahl.mp3", 11_886_549, 1486),
            zaher([19], "019-maryam.mp3", 6_485_262, 811),
            zaher([20], "020-taha.mp3", 4_764_524, 596),
            zaher([24], "024-an-nur.mp3", 13_825_879, 1728),
            zaher([27], "027-an-naml.mp3", 2_691_447, 336),
            zaher([28], "028-al-qasas.mp3", 2_573_164, 322),
            zaher([47], "047-muhammad.mp3", 2_472_854, 309),
            zaher([48], "048-al-fath.mp3", 7_105_096, 888),
            zaher([54], "054-al-qamar.mp3", 2_457_390, 307),
            zaher([54, 55], "054-055-al-qamar-ar-rahman.mp3", 5_381_850, 673),
            zaher([58], "058-al-mujadila.mp3", 2_557_700, 320),
            zaher([75], "075-al-qiyamah.mp3", 4_731_088, 591, whole: true),
            zaher([86], "086-at-tariq.mp3", 1_603_499, 200, whole: true)
        ],
        isRare: true
    )

    public static let abdulRahmanMosad = RareCollection(
        id: "abdul-rahman-mosad",
        nameAr: "عبد الرحمن مسعد",
        nameEn: "Abdul Rahman Mossad",
        nameTr: "Abdurrahman Mosad",
        nameUr: "عبد الرحمٰن مسعد",
        photoAsset: "reciter_abdulrahman_mosad",
        tracks: [
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 2, "002-001", 1_246_740, 63, part: 1),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 2, "002-002", 2_245_142, 186, part: 2),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 2, "002-003", 19_687_725, 820, part: 3),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 3, "003-001", 4_068_708, 331, part: 1),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 3, "003-002", 8_260_986, 516, part: 2),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 3, "003-003", 6_369_790, 398, part: 3),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 5, "005-001", 8_958_803, 435),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 7, "007-001", 2_319_977, 195),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 10, "010-001", 17_098_107, 1068),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 11, "011", 57_813_736, 3613, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 13, "013-001", 149_880, 22, part: 1),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 13, "013-002", 261_450, 21, part: 2),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 13, "013-003", 548_353, 48, part: 3),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 14, "014-001", 2_051_842, 143),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 15, "015", 24_903_755, 1289, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 16, "016-001", 2_839_041, 256, part: 1),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 16, "016-002", 702_553, 61, part: 2),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 17, "017", 75_809_420, 2893, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 19, "019-001", 4_835_249, 399, part: 1),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 19, "019-002", 1_754_215, 148, part: 2),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 19, "019-003", 928_047, 75, part: 3),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 21, "021-001", 19_427_587, 718),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 23, "023-001", 15_193_774, 731),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 24, "024-001", 841_947, 68),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 25, "025-001", 1_355_990, 224, part: 1),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 25, "025-002", 2_198_174, 365, part: 2),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 25, "025", 53_038_075, 1996, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 27, "027-001", 16_271_397, 407),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 29, "029-001", 5_931_039, 499, part: 1),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 29, "029-002", 593_870, 52, part: 2),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 30, "030-001", 485_577, 37),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 32, "032", 9_888_577, 614, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 39, "039-001", 48_461_925, 1212),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 49, "049", 9_947_564, 622, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 67, "067", 12_267_384, 650, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 73, "073", 4_002_215, 343, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 78, "078", 3_781_301, 327, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 87, "087", 1_311_581, 110, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 88, "088", 1_797_067, 155, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 93, "093", 1_776_045, 111, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 94, "094", 945_069, 59, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 95, "095", 1_125_933, 70, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 100, "100", 991_493, 87, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 101, "101", 1_346_733, 84, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 107, "107", 505_828, 44, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 112, "112", 377_226, 17, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 113, "113", 634_454, 30, whole: true),
            w2q("abdul-rahman-mosad", "abdul-rahman-musaad", 114, "114", 714_110, 35, whole: true)
        ],
        isRare: false
    )

    public static let omarDiaaAlDin = RareCollection(
        id: "omar-diaa-al-din",
        nameAr: "عمر ضياء الدين",
        nameEn: "Omar Diaa al-Din",
        nameTr: "Ömer Ziyaüddin",
        nameUr: "عمر ضیاء الدین",
        photoAsset: "reciter_omar_diaa",
        tracks: [
            (2, 181_199_853, 7550), (3, 103_453_677, 4311), (4, 108_979_821, 4541), (5, 72_774_717, 3600),
            (6, 108_049_005, 4502), (8, 30_284_832, 1893), (9, 89_501_805, 3729), (10, 47_085_141, 2248),
            (12, 38_722_592, 2420), (15, 19_358_781, 951), (17, 47_834_733, 2463), (18, 55_024_749, 2293),
            (19, 29_746_989, 1552), (20, 35_204_685, 1930), (23, 28_526_517, 1565), (24, 45_989_037, 1916),
            (25, 22_144_077, 1294), (29, 21_020_767, 1314), (31, 12_970_037, 811), (32, 8_921_266, 558),
            (33, 30_799_340, 1925), (34, 18_639_235, 1165), (35, 22_670_013, 1227), (40, 30_723_717, 1758),
            (44, 9_575_085, 564), (47, 18_715_437, 780), (49, 10_929_645, 455), (50, 14_262_381, 594),
            (53, 9_055_413, 488), (55, 15_088_965, 717), (56, 13_353_285, 719), (57, 16_442_589, 930),
            (58, 12_877_250, 805), (59, 11_994_102, 750), (60, 7_962_050, 498), (62, 4_153_606, 260),
            (63, 5_317_622, 332), (64, 5_817_919, 364), (66, 6_153_541, 385), (67, 8_025_645, 502),
            (68, 11_590_317, 483), (69, 9_258_813, 447), (70, 8_644_557, 379), (71, 8_008_029, 381),
            (72, 8_870_349, 428), (73, 7_320_813, 335), (74, 9_178_989, 438), (75, 5_545_677, 260),
            (76, 8_982_477, 420), (77, 7_381_509, 349), (78, 5_030_066, 314)
        ].map { s, b, sec in
            w2q("omar-diaa-al-din", "omar-diaa-al-din", s, String(format: "%03d", s), Int64(b), sec, whole: true)
        },
        isRare: false
    )

    public static let islamSobhi = RareCollection(
        id: "islam-sobhi",
        nameAr: "إسلام صبحي",
        nameEn: "Islam Sobhi",
        nameTr: "İslam Subhi",
        nameUr: "اسلام صبحی",
        photoAsset: "reciter_islam_sobhi",
        tracks: [
            (1, 869_230, 53), (2, 115_820_372, 7237), (3, 107_095_845, 4462), (4, 64_847_099, 4051),
            (5, 68_272_230, 3412), (6, 56_740_055, 3544), (7, 61_197_086, 3823), (8, 22_591_393, 1411),
            (9, 46_084_076, 2879), (10, 35_271_226, 2202), (11, 51_387_204, 2568), (12, 34_522_446, 2156),
            (13, 18_491_880, 1154), (14, 16_353_574, 1020), (15, 15_702_017, 980), (16, 36_148_315, 2259),
            (17, 37_920_330, 2041), (18, 30_477_970, 1903), (19, 17_627_947, 1100), (20, 36_909_201, 1537),
            (21, 28_734_345, 1426), (22, 25_022_654, 1562), (23, 28_250_384, 1367), (24, 37_858_408, 1754),
            (25, 24_483_474, 1055), (26, 27_582_125, 1723), (27, 22_688_161, 1416), (28, 27_706_864, 1730),
            (29, 25_223_760, 1198), (30, 21_088_015, 996), (31, 10_457_714, 653), (32, 8_011_407, 500),
            (33, 28_518_355, 1780), (34, 19_118_386, 1193), (35, 15_958_186, 996), (36, 15_707_847, 980),
            (38, 21_671_652, 959), (41, 17_111_795, 1068), (42, 17_468_306, 1090), (43, 18_317_401, 1143),
            (44, 6_639_247, 414), (46, 13_228_941, 825), (47, 12_757_750, 618), (48, 14_058_188, 671),
            (49, 10_526_881, 477), (50, 7_373_579, 460), (51, 8_222_218, 512), (52, 7_993_474, 418),
            (53, 7_458_859, 466), (54, 13_412_836, 837), (55, 10_268_134, 640), (56, 7_712_864, 641),
            (57, 13_726_004, 685), (58, 10_614_640, 662), (59, 8_680_138, 542), (60, 7_835_466, 390),
            (61, 4_603_511, 286), (62, 4_922_407, 236), (63, 4_280_047, 266), (64, 5_367_850, 334),
            (66, 5_423_406, 338), (67, 5_448_596, 452), (68, 6_556_220, 408), (69, 5_749_807, 358),
            (70, 7_885_842, 327), (71, 6_825_576, 283), (72, 5_597_209, 357), (73, 4_219_878, 262),
            (74, 7_477_780, 313), (75, 3_990_395, 248), (76, 6_518_037, 406), (77, 4_780_760, 297),
            (78, 4_245_338, 264), (79, 4_557_398, 284), (80, 3_373_875, 209), (81, 2_471_135, 153),
            (82, 2_034_758, 126), (83, 4_146_316, 258), (84, 2_497_459, 154), (85, 2_491_418, 155),
            (86, 1_665_280, 102), (87, 1_731_311, 107), (88, 2_242_742, 140), (89, 3_007_329, 186),
            (90, 1_980_823, 122), (91, 1_404_039, 86), (92, 1_654_815, 102), (93, 1_009_494, 61),
            (94, 733_233, 44), (95, 1_311_091, 58), (96, 1_794_413, 111), (97, 998_847, 41),
            (98, 2_447_825, 107), (99, 1_158_761, 46), (100, 1_234_326, 50), (101, 1_135_864, 47),
            (102, 1_155_581, 47), (103, 577_520, 23), (104, 1_008_824, 40), (105, 699_157, 32),
            (106, 653_694, 27), (107, 990_821, 40), (108, 419_131, 17), (109, 1_063_866, 42),
            (110, 577_448, 23), (111, 624_726, 27), (112, 615_057, 36), (113, 434_610, 26),
            (114, 849_609, 34)
        ].map { s, b, sec in
            mp3q("islam-sobhi", "https://cdn.mp3quran.net/audio/islam-sobhi/r1/", s, Int64(b), sec)
        },
        isRare: false
    )

    public static let muhammadRefaat = RareCollection(
        id: "muhammad-refaat",
        nameAr: "محمد رفعت",
        nameEn: "Muhammad Refaat",
        nameTr: "Muhammed Rıfat",
        nameUr: "محمد رفعت",
        photoAsset: "reciter_refaat",
        tracks: [
            (1, 3_519_158, 219), (10, 79_461_907, 4966), (11, 66_136_109, 4133), (12, 46_667_994, 2916),
            (17, 40_176_682, 2510), (18, 82_704_023, 5168), (19, 37_648_019, 2352), (20, 39_838_955, 2489),
            (48, 28_189_607, 1761), (54, 27_221_615, 1701), (55, 27_940_509, 1746), (56, 10_006_720, 625),
            (69, 11_155_686, 697), (72, 25_569_000, 1598), (73, 14_455_898, 903), (75, 13_040_686, 814),
            (76, 22_444_764, 1402), (77, 5_973_000, 373), (78, 20_453_602, 1278), (79, 13_381_743, 836),
            (81, 7_182_986, 448), (82, 10_173_070, 635), (83, 19_137_882, 1196), (85, 8_127_988, 507),
            (86, 4_745_862, 296), (87, 10_181_419, 636), (88, 14_543_253, 908), (89, 11_641_409, 726),
            (96, 5_916_982, 369), (98, 5_726_818, 357), (100, 4_462_912, 278)
        ].map { s, b, sec in
            mp3q("muhammad-refaat", "https://cdn.mp3quran.net/audio/muhammad-refaat/r1/", s, Int64(b), sec)
        },
        isRare: false
    )

    public static let younesSouilass = RareCollection(
        id: "younes-souilass",
        nameAr: "يونس اسويلص",
        nameEn: "Younes Souilass",
        nameTr: "Yunus Esuveylis",
        nameUr: "یونس اسویلص",
        photoAsset: "reciter_souilass",
        tracks: [
            (1, 826_250, 51), (2, 137_679_413, 8604), (10, 39_418_937, 2463), (11, 41_952_171, 2621),
            (12, 40_560_645, 2534), (13, 19_536_725, 1220), (14, 18_590_686, 1161), (15, 17_356_773, 1084),
            (16, 40_263_671, 2516), (17, 33_560_312, 2097), (18, 31_386_161, 1961), (19, 19_402_014, 1212),
            (20, 28_190_593, 1761), (21, 26_647_631, 1664), (22, 29_797_426, 1862), (23, 21_320_145, 1331),
            (24, 25_704_668, 1605), (25, 21_746_700, 1359), (26, 26_390_198, 1649), (27, 23_952_685, 1496),
            (28, 27_532_089, 1720), (29, 18_521_731, 1157), (30, 18_128_646, 1132), (31, 12_032_399, 751),
            (32, 8_848_248, 552), (33, 29_734_443, 1857), (34, 18_028_539, 1126), (35, 19_502_670, 1218),
            (36, 15_216_917, 950), (37, 21_009_301, 1312), (38, 14_236_199, 889), (39, 21_603_756, 1350),
            (40, 26_849_490, 1677), (41, 19_107_626, 1193), (42, 20_476_109, 1279), (43, 17_125_778, 1069),
            (45, 10_009_591, 625), (46, 13_878_499, 866), (47, 11_369_072, 709), (48, 11_137_638, 696),
            (50, 7_530_289, 470), (51, 8_842_295, 552), (52, 6_697_655, 418), (53, 6_549_282, 409),
            (54, 7_995_722, 499), (56, 11_002_302, 687), (57, 11_290_270, 705), (67, 7_418_292, 463),
            (71, 5_056_255, 315), (73, 5_786_173, 361), (76, 5_676_167, 1456), (77, 3_746_039, 234),
            (78, 4_187_799, 261), (79, 3_659_537, 152), (80, 2_714_087, 169), (81, 1_863_547, 116),
            (82, 1_520_405, 94), (86, 3_342_453, 208), (89, 13_586_833, 848), (90, 2_104_080, 130),
            (91, 1_434_374, 89), (93, 1_635_281, 101), (95, 1_438_683, 89), (97, 1_050_266, 65),
            (112, 410_378, 25)
        ].map { s, b, sec in
            mp3q("younes-souilass", "https://cdn.mp3quran.net/audio/younes-souilass/r1/", s, Int64(b), sec)
        },
        isRare: false,
        riwayah: Reciter.warsh
    )

    public static let rareCollections: [RareCollection] = [
        abdulAzimZaher,
        abdulRahmanMosad,
        omarDiaaAlDin,
        islamSobhi,
        muhammadRefaat,
        younesSouilass
    ]

    public static func rare(id: String) -> RareCollection? {
        rareCollections.first { $0.id == id }
    }
}

public enum ListeningKind: String, Codable, Sendable, Equatable {
    case surah
    case rare
}

public struct ListeningTrack: Codable, Sendable, Equatable, Hashable, Identifiable {
    public let id: String
    public let kind: ListeningKind
    public let sourceId: String
    public let title: String
    public let artist: String
    public let artworkAsset: String?
    public let streamUrl: String
    public let fallbackUrl: String?
    public let surahNumber: Int
    public let fileName: String?

    public init(
        id: String,
        kind: ListeningKind,
        sourceId: String,
        title: String,
        artist: String,
        artworkAsset: String?,
        streamUrl: String,
        fallbackUrl: String?,
        surahNumber: Int,
        fileName: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.sourceId = sourceId
        self.title = title
        self.artist = artist
        self.artworkAsset = artworkAsset
        self.streamUrl = streamUrl
        self.fallbackUrl = fallbackUrl
        self.surahNumber = surahNumber
        self.fileName = fileName
    }
}

public struct ListeningSession: Codable, Sendable, Equatable {
    public let kind: ListeningKind
    public let sourceId: String
    public let trackId: String
    public let title: String
    public let artist: String
    public let positionMs: Int64
    public let durationMs: Int64

    public init(
        kind: ListeningKind,
        sourceId: String,
        trackId: String,
        title: String,
        artist: String,
        positionMs: Int64,
        durationMs: Int64
    ) {
        self.kind = kind
        self.sourceId = sourceId
        self.trackId = trackId
        self.title = title
        self.artist = artist
        self.positionMs = positionMs
        self.durationMs = durationMs
    }
}

public struct ReciterVersion: Sendable, Equatable, Hashable, Identifiable {
    public let id: String
    public let isCollection: Bool
    public let style: String?
    public let riwayah: String
    public let offlineCount: Int
    public let total: Int

    public init(id: String, isCollection: Bool, style: String?, riwayah: String, offlineCount: Int, total: Int) {
        self.id = id
        self.isCollection = isCollection
        self.style = style
        self.riwayah = riwayah
        self.offlineCount = offlineCount
        self.total = total
    }
}

public struct ReciterGroup: Sendable, Equatable, Hashable, Identifiable {
    public var id: String { key }
    public let key: String
    public let name: String
    public let photoAsset: String?
    public let versions: [ReciterVersion]
    public let letter: String

    public var primary: ReciterVersion { versions[0] }
    public var offlineCount: Int { versions.reduce(0) { $0 + $1.offlineCount } }

    public func matches(foldedQuery: String) -> Bool {
        if foldedQuery.isEmpty { return true }
        if ArabicSearchText.normalize(name).contains(foldedQuery) { return true }
        for v in versions {
            if v.isCollection, let col = ListeningCatalog.rare(id: v.id) {
                if [col.nameAr, col.nameEn, col.nameTr, col.nameUr].contains(where: { ArabicSearchText.normalize($0).contains(foldedQuery) }) {
                    return true
                }
            } else {
                let rec = Reciter.byId(v.id)
                let names = [rec.name, rec.englishName, rec.nameTr ?? "", rec.nameUr ?? ""]
                if names.contains(where: { ArabicSearchText.normalize($0).contains(foldedQuery) }) {
                    return true
                }
            }
        }
        return false
    }
}

public enum ListenTitles {
    private static let versionOf: [String: String] = [
        "ar.abdulbasitmujawwad": "ar.abdulbasitmurattal",
        "ar.husarymujawwad": "ar.husary",
        "ar.minshawikids": "ar.minshawi",
        "ar.abdulbasitwarsh": "ar.abdulbasitmurattal",
        "ar.husarywarsh": "ar.husary",
        "ar.husaryqalun": "ar.husary",
        "ar.hudhaifyqalun": "ar.hudhaify"
    ]

    private static let titles = ["الشيخ ", "شیخ ", "Sheikh ", "Şeyh "]

    public static func surah(_ surah: Surah, language: String) -> String {
        let name = SurahNames.forLanguage(surah, language: language)
        switch SirajLocalizer.baseLanguage(language) {
        case "ar": return "سورة \(name)"
        case "ur": return "سورۂ \(name)"
        case "tr": return "\(name) Suresi"
        default: return "Surah \(name)"
        }
    }

    public static func rare(_ track: RareTrack, surahs: [Surah], language: String) -> String {
        let base = SirajLocalizer.baseLanguage(language)
        let names = track.surahs.map { num in
            surahs.first(where: { $0.number == num }).map { SurahNames.forLanguage($0, language: base) } ?? "\(num)"
        }
        if track.isWholeSurah, let first = track.surahs.first {
            if let s = surahs.first(where: { $0.number == first }) {
                return surah(s, language: base)
            }
            return names.first ?? ""
        }
        let passage: String
        if names.count == 1 {
            switch base {
            case "ar": passage = "ما تيسّر من سورة \(names[0])"
            case "ur": passage = "سورۂ \(names[0]) سے"
            case "tr": passage = "\(names[0]) suresinden"
            default: passage = "\(names[0]) · selected passages"
            }
        } else {
            switch base {
            case "ar": passage = "ما تيسّر من سورتي \(names[0]) و\(names[1])"
            case "ur": passage = "سورۂ \(names[0]) اور \(names[1]) سے"
            case "tr": passage = "\(names[0]) ve \(names[1]) surelerinden"
            default: passage = "\(names[0]) and \(names[1]) · selected passages"
            }
        }
        if track.part <= 0 { return passage }
        let numStr = (base == "ar" || base == "ur")
            ? DigitFormatter.localizeDigits(String(track.part), eastern: true, lang: base)
            : String(track.part)
        return "\(passage) (\(numStr))"
    }

    public static func surahTrackId(reciterId: String, surahNumber: Int) -> String {
        "surah/\(reciterId)/\(surahNumber)"
    }

    public static func reciterQueue(reciterId: String, surahs: [Surah], language: String) -> [ListeningTrack] {
        let reciter = Reciter.byId(reciterId)
        let artist = reciter.shortDisplayName(language: language)
        let artwork = reciter.photoAssetName
        return surahs.map { s in
            let urls = ReciterAudioURLs.listeningSurahURLs(reciterId: reciter.id, surah: s.number)
            let primary = urls.first ?? ReciterAudioURLs.surahAudioURL(reciterId: reciter.id, surah: s.number)
            let fallback = urls.count > 1 ? urls[1] : nil
            return ListeningTrack(
                id: surahTrackId(reciterId: reciter.id, surahNumber: s.number),
                kind: .surah,
                sourceId: reciter.id,
                title: surah(s, language: language),
                artist: artist,
                artworkAsset: artwork,
                streamUrl: primary,
                fallbackUrl: fallback,
                surahNumber: s.number,
                fileName: nil
            )
        }
    }

    public static func rareQueue(collection: RareCollection, surahs: [Surah], language: String) -> [ListeningTrack] {
        let artist = collection.localizedName(language: language)
        return collection.tracks.map { t in
            ListeningTrack(
                id: t.id,
                kind: .rare,
                sourceId: collection.id,
                title: rare(t, surahs: surahs, language: language),
                artist: artist,
                artworkAsset: collection.photoAsset,
                streamUrl: t.url,
                fallbackUrl: t.fallbackUrl,
                surahNumber: t.surahs.first ?? 1,
                fileName: t.fileName
            )
        }
    }

    public static func buildReciterGroups(
        language: String,
        offlineSurahs: [String: Int] = [:],
        offlineRare: [String: Int] = [:]
    ) -> [ReciterGroup] {
        let base = SirajLocalizer.baseLanguage(language)
        var order: [String] = []
        var grouped: [String: [Reciter]] = [:]

        for rec in Reciter.allListeningReciters {
            let leadId = versionOf[rec.id] ?? rec.id
            if grouped[leadId] == nil {
                order.append(leadId)
                grouped[leadId] = []
            }
            grouped[leadId]?.append(rec)
        }

        var result: [ReciterGroup] = []
        for leadId in order {
            guard let list = grouped[leadId], !list.isEmpty else { continue }
            let lead = list.first(where: { $0.id == leadId }) ?? list[0]
            let ordered = [lead] + list.filter { $0.id != lead.id }
            let displayName = lead.localizedName(language: base)
            let versions = ordered.map { r in
                ReciterVersion(
                    id: r.id,
                    isCollection: false,
                    style: r.subInfo,
                    riwayah: r.riwayah,
                    offlineCount: offlineSurahs[r.id] ?? 0,
                    total: 114
                )
            }
            result.append(ReciterGroup(
                key: leadId,
                name: displayName,
                photoAsset: lead.photoAssetName,
                versions: versions,
                letter: letterOf(displayName, language: base)
            ))
        }

        for col in ListeningCatalog.rareCollections where !col.isRare {
            let displayName = col.localizedName(language: base)
            let version = ReciterVersion(
                id: col.id,
                isCollection: true,
                style: nil,
                riwayah: col.riwayah,
                offlineCount: offlineRare[col.id] ?? 0,
                total: col.tracks.count
            )
            result.append(ReciterGroup(
                key: col.id,
                name: displayName,
                photoAsset: col.photoAsset,
                versions: [version],
                letter: letterOf(displayName, language: base)
            ))
        }

        let locale = Locale(identifier: base == "ur" ? "ar" : base)
        return result.sorted { a, b in
            filingName(a.name).compare(filingName(b.name), options: [.caseInsensitive, .diacriticInsensitive], locale: locale) == .orderedAscending
        }
    }

    public static func filingName(_ name: String) -> String {
        var s = name.trimmingCharacters(in: .whitespacesAndNewlines)
        for t in titles where s.hasPrefix(t) {
            s = String(s.dropFirst(t.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return s
    }

    public static func letterOf(_ name: String, language: String) -> String {
        let clean = filingName(name)
        guard let first = clean.first(where: { $0.isLetter }) else { return "#" }
        switch first {
        case "أ", "إ", "آ", "ٱ": return "ا"
        case "ى": return "ي"
        case "ة": return "ه"
        default:
            if let scalar = first.unicodeScalars.first, scalar.value >= 0x0600 && scalar.value <= 0x06FF {
                return String(first)
            }
            let base = SirajLocalizer.baseLanguage(language)
            let upper = String(first).uppercased(with: Locale(identifier: base))
            if base == "tr" { return upper }
            return upper.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en"))
        }
    }
}
