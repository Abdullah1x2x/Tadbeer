/// قرّاء التلاوة المسموعة: ملف لكل آية من شبكة Islamic Network.
///
/// لكل تلاوة ملف لكل آية برقمها في المصحف (1..6236)، وهو نفس رقمها في التطبيق؛ فيمكن البدء من أي آية وتكرارها والتوقف بعدها.
library;

/// قارئ وموضع تلاوته.
class Reciter {
  /// اسم التلاوة في المصدر، كما في مسارات ملفاتها.
  final String id;

  final String name;

  /// معدّل بت ملفاته، بالكيلوبت في الثانية.
  final int bitrate;

  const Reciter({required this.id, required this.name, required this.bitrate});

  /// هل جودة ملفاته أقل بوضوح من غيره.
  bool get lowQuality => bitrate < 64;

  /// ملف الآية [ayahId] (1..6236).
  Uri urlFor(int ayahId) => Uri.parse(
    'https://cdn.islamic.network/quran/audio/$bitrate/$id/$ayahId.mp3',
  );
}

/// القرّاء المعروضون، بترتيب ظهورهم.
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

/// القارئ [id]، أو الأول إن لم يعد موجوداً.
Reciter reciterById(String? id) =>
    reciters.firstWhere((r) => r.id == id, orElse: () => reciters.first);
