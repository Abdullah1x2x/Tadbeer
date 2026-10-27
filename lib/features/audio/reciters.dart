/// قرّاء التلاوة المسموعة: ملف لكل آية من شبكة Islamic Network.
///
/// Every recitation here has one file per ayah, numbered by the ayah's
/// place in the Mushaf (1 to 6236), the same number the app gives it. That
/// lets playback start at any ayah, repeat it and pause after it.
library;

/// قارئ واحد وموضع تلاوته.
class Reciter {
  /// The recitation's name at the source, as in its file paths.
  final String id;

  /// الاسم كما يُعرض.
  final String name;

  /// Bit rate of its files, in kbit/s.
  final int bitrate;

  const Reciter({required this.id, required this.name, required this.bitrate});

  /// Whether its files are of noticeably lower quality than the others'.
  bool get lowQuality => bitrate < 64;

  /// The file of the ayah numbered [ayahId] in the Mushaf (1 to 6236).
  Uri urlFor(int ayahId) => Uri.parse(
    'https://cdn.islamic.network/quran/audio/$bitrate/$id/$ayahId.mp3',
  );
}

/// The reciters offered, in the order they are listed.
const reciters = <Reciter>[
  Reciter(id: 'ar.husary', name: 'محمود خليل الحصري', bitrate: 128),
  Reciter(id: 'ar.minshawi', name: 'محمد صديق المنشاوي', bitrate: 128),
  Reciter(
    id: 'ar.abdulbasitmurattal',
    name: 'عبد الباسط عبد الصمد',
    bitrate: 192,
  ),
  Reciter(id: 'ar.alafasy', name: 'مشاري العفاسي', bitrate: 128),
  Reciter(id: 'ar.mahermuaiqly', name: 'ماهر المعيقلي', bitrate: 128),
  Reciter(id: 'ar.shaatree', name: 'أبو بكر الشاطري', bitrate: 128),
  Reciter(id: 'ar.parhizgar', name: 'شهريار پرهيزگار', bitrate: 48),
];

/// The reciter with [id], or the first one if it is no longer offered.
Reciter reciterById(String? id) =>
    reciters.firstWhere((r) => r.id == id, orElse: () => reciters.first);
