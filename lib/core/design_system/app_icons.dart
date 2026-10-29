import 'package:flutter/widgets.dart';

/// كل أيقونات التطبيق، من مجموعة Phosphor.
///
/// تقلب Phosphor كل أيقوناتها في النص من اليمين لليسار، فتنعكس الحروف والساعات
/// والعدسات. هنا تُقلب فقط الأيقونات التي تشير إلى اتجاه: الأسهم والأقواس
/// والقوائم.
abstract final class AppIcons {
  static const _regular = 'PhosphorRegular';
  static const _fill = 'PhosphorFill';
  static const _package = 'phosphor_flutter';

  static const IconData alarm = IconData(
    0xe006,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData alarmFill = IconData(
    0xe006,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData arrowClockwise = IconData(
    0xe036,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData arrowCounterClockwise = IconData(
    0xe038,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData arrowLeft = IconData(
    0xe058,
    fontFamily: _regular,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData arrowRight = IconData(
    0xe06c,
    fontFamily: _regular,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData arrowSquareOut = IconData(
    0xe5de,
    fontFamily: _regular,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData arrowsClockwise = IconData(
    0xe094,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData bell = IconData(
    0xe0ce,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData bellRinging = IconData(
    0xe5e8,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData bellRingingFill = IconData(
    0xe5e8,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData bookOpen = IconData(
    0xe0e6,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData bookOpenFill = IconData(
    0xe0e6,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData bookOpenText = IconData(
    0xe8f2,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData bookOpenTextFill = IconData(
    0xe8f2,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData bookmarkSimple = IconData(
    0xe0ea,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData bookmarkSimpleFill = IconData(
    0xe0ea,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData bookmarks = IconData(
    0xe0ec,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData books = IconData(
    0xe758,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData brain = IconData(
    0xe74e,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData brainFill = IconData(
    0xe74e,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData calendarCheck = IconData(
    0xe712,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData caretDown = IconData(
    0xe136,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData caretLeft = IconData(
    0xe138,
    fontFamily: _regular,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData caretRight = IconData(
    0xe13a,
    fontFamily: _regular,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData caretUp = IconData(
    0xe13c,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData chartLineUp = IconData(
    0xe156,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData check = IconData(
    0xe182,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData checkCircle = IconData(
    0xe184,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData checkCircleFill = IconData(
    0xe184,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData circle = IconData(
    0xe18a,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData circleHalf = IconData(
    0xe18c,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData clipboardText = IconData(
    0xe198,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData clock = IconData(
    0xe19a,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData cloudArrowDown = IconData(
    0xe1ac,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData cloudArrowUp = IconData(
    0xe1ae,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData cloudSlash = IconData(
    0xe1b6,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData code = IconData(
    0xe1bc,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData coffee = IconData(
    0xe1c2,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData compass = IconData(
    0xe1c8,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData compassFill = IconData(
    0xe1c8,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData copy = IconData(
    0xe1ca,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData crosshair = IconData(
    0xe1d6,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData dotsThreeVertical = IconData(
    0xe208,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData downloadSimple = IconData(
    0xe20c,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData export = IconData(
    0xeaf0,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData eye = IconData(
    0xe220,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData filePdf = IconData(
    0xe702,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData filePdfFill = IconData(
    0xe702,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData fileText = IconData(
    0xe23a,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData fileTextFill = IconData(
    0xe23a,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData fire = IconData(
    0xe242,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData flag = IconData(
    0xe244,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData floppyDisk = IconData(
    0xe248,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData flowerLotus = IconData(
    0xe6cc,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData flowerLotusFill = IconData(
    0xe6cc,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData folderOpen = IconData(
    0xe256,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData folderStar = IconData(
    0xea86,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData gavel = IconData(
    0xea32,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData gear = IconData(
    0xe270,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData gearFill = IconData(
    0xe270,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData globe = IconData(
    0xe288,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData graph = IconData(
    0xeb58,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData graphFill = IconData(
    0xeb58,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData gridFour = IconData(
    0xe296,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData hand = IconData(
    0xe298,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData handHeart = IconData(
    0xe810,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData handHeartFill = IconData(
    0xe810,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData handSwipeRight = IconData(
    0xec92,
    fontFamily: _regular,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData handTap = IconData(
    0xec90,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData heart = IconData(
    0xe2a8,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData heartFill = IconData(
    0xe2a8,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData highlighterCircle = IconData(
    0xe632,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData house = IconData(
    0xe2c2,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData houseFill = IconData(
    0xe2c2,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData infinity = IconData(
    0xe634,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData info = IconData(
    0xe2ce,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData lightbulb = IconData(
    0xe2dc,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData lightbulbFill = IconData(
    0xe2dc,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData lightning = IconData(
    0xe2de,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData link = IconData(
    0xe2e2,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData list = IconData(
    0xe2f0,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData listBullets = IconData(
    0xe2f2,
    fontFamily: _regular,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData listNumbers = IconData(
    0xe2f6,
    fontFamily: _regular,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData lock = IconData(
    0xe2fa,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData lockKey = IconData(
    0xe2fe,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData magnifyingGlass = IconData(
    0xe30c,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData magnifyingGlassMinus = IconData(
    0xe30e,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData medal = IconData(
    0xe320,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData megaphone = IconData(
    0xe324,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData minus = IconData(
    0xe32a,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData minusCircle = IconData(
    0xe32c,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData moon = IconData(
    0xe330,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData moonStars = IconData(
    0xe58e,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData mosque = IconData(
    0xecee,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData note = IconData(
    0xe348,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData noteFill = IconData(
    0xe348,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData notePencil = IconData(
    0xe34c,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData paintBrush = IconData(
    0xe6f0,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData paintBrushFill = IconData(
    0xe6f0,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData palette = IconData(
    0xe6c8,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData path = IconData(
    0xe39c,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData pause = IconData(
    0xe39e,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData pencilSimple = IconData(
    0xe3b4,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData pencilSimpleFill = IconData(
    0xe3b4,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData personSimpleTaiChi = IconData(
    0xed5c,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData play = IconData(
    0xe3d0,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData plus = IconData(
    0xe3d4,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData plusCircle = IconData(
    0xe3d6,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData prohibit = IconData(
    0xe3de,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData puzzlePiece = IconData(
    0xe596,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData qrCode = IconData(
    0xe3e6,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData rectangle = IconData(
    0xe3f0,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData scales = IconData(
    0xe750,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData scan = IconData(
    0xebb6,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData scroll = IconData(
    0xeb7a,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData sealCheck = IconData(
    0xe606,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData shareNetwork = IconData(
    0xe408,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData shareNetworkFill = IconData(
    0xe408,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData shield = IconData(
    0xe40a,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData shieldCheck = IconData(
    0xe40c,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData shieldFill = IconData(
    0xe40a,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData slidersHorizontal = IconData(
    0xe434,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData sparkle = IconData(
    0xe6a2,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData sparkleFill = IconData(
    0xe6a2,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData square = IconData(
    0xe45e,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData squaresFour = IconData(
    0xe464,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData squaresFourFill = IconData(
    0xe464,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData sun = IconData(
    0xe472,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData sunFill = IconData(
    0xe472,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData textAa = IconData(
    0xe6ee,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData textT = IconData(
    0xe48a,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData timer = IconData(
    0xe492,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData trash = IconData(
    0xe4a6,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData trophy = IconData(
    0xe67e,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData uploadSimple = IconData(
    0xe4c0,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData user = IconData(
    0xe4c2,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData userMinus = IconData(
    0xe4ce,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData warning = IconData(
    0xe4e0,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData warningCircle = IconData(
    0xe4e2,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData wind = IconData(
    0xe5d2,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData x = IconData(
    0xe4f6,
    fontFamily: _regular,
    fontPackage: _package,
  );

  // تلاوة القرآن.
  static const IconData headphones = IconData(
    0xe2a6,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData headphonesFill = IconData(
    0xe2a6,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData playFill = IconData(
    0xe3d0,
    fontFamily: _fill,
    fontPackage: _package,
  );
  static const IconData pauseFill = IconData(
    0xe39e,
    fontFamily: _fill,
    fontPackage: _package,
  );

  /// الآية التالية: يشير في اتجاه القراءة.
  static const IconData skipForwardFill = IconData(
    0xe5a6,
    fontFamily: _fill,
    fontPackage: _package,
    matchTextDirection: true,
  );

  /// الآية السابقة: يشير عكس اتجاه القراءة.
  static const IconData skipBackFill = IconData(
    0xe5a4,
    fontFamily: _fill,
    fontPackage: _package,
    matchTextDirection: true,
  );
  static const IconData repeat = IconData(
    0xe3f6,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData repeatOnce = IconData(
    0xe3f8,
    fontFamily: _regular,
    fontPackage: _package,
  );
  static const IconData hourglassMedium = IconData(
    0xe2b8,
    fontFamily: _regular,
    fontPackage: _package,
  );
}
