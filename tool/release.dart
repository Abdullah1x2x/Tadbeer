// Prepares a release: one command writes the version everywhere it lives.
//
//   dart run tool/release.dart 1.0.1
//
// Reads the notes under "## غير منشور" in CHANGELOG.md, then updates
// pubspec.yaml, the constants in app_update_service.dart, CHANGELOG.md,
// version.json, docs/version.json and the Arabic store changelog.
// It commits nothing and pushes nothing; it prints the commands to run next.
import 'dart:convert';
import 'dart:io';

const unreleasedHeading = '## غير منشور';
const _repo = 'https://github.com/Abdullah1x2x/Tadbeer';

/// The `version:` line of pubspec.yaml as (name, build).
(String, int) pubspecVersion(String pubspec) {
  final m = RegExp(
    r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec);
  if (m == null) throw const FormatException('pubspec.yaml has no version');
  return (m.group(1)!, int.parse(m.group(2)!));
}

String setPubspecVersion(String pubspec, String version, int build) =>
    pubspec.replaceFirst(
      RegExp(r'^version:.*$', multiLine: true),
      'version: $version+$build',
    );

/// Rewrites `currentVersion` and `currentBuildNumber` in the update service.
String setServiceVersion(String source, String version, int build) {
  final name = RegExp(r"currentVersion = '[^']*'");
  final number = RegExp(r'currentBuildNumber = \d+');
  if (!name.hasMatch(source) || !number.hasMatch(source)) {
    throw const FormatException('Version constants not found in the service');
  }
  return source
      .replaceFirst(name, "currentVersion = '$version'")
      .replaceFirst(number, 'currentBuildNumber = $build');
}

/// Closes the unreleased section as [version] and opens an empty one above
/// it. Returns the new changelog and the released notes (its `- ` lines).
(String, List<String>) cutChangelog(
  String changelog,
  String version,
  String date,
) {
  final start = changelog.indexOf(unreleasedHeading);
  if (start < 0) {
    throw const FormatException('CHANGELOG.md has no "$unreleasedHeading"');
  }
  final bodyStart = start + unreleasedHeading.length;
  final next = changelog.indexOf('\n## ', bodyStart);
  final body = changelog.substring(bodyStart, next < 0 ? null : next);
  final notes = [
    for (final line in LineSplitter.split(body))
      if (line.startsWith('- ')) line.substring(2).trim(),
  ];
  if (notes.isEmpty) {
    throw const FormatException('Nothing is listed under "$unreleasedHeading"');
  }
  final cut = changelog.replaceRange(
    start,
    bodyStart,
    '$unreleasedHeading\n\n## $version — $date',
  );
  return (cut, notes);
}

/// What the app reads to offer the update.
Map<String, Object> versionJson(
  String version,
  int build,
  String date,
  List<String> notes,
) => {
  'latest_version': version,
  'build_number': build,
  'release_date': date,
  'title': 'الإصدار $version من تَدبِير',
  'changelog': notes.map((n) => '• $n').join('\n'),
  'telegram_url': 'https://t.me/tadbeerapp',
  'download_url': '$_repo/releases/tag/v$version',
  // The app swaps the ABI name for the device's own.
  'apk_url':
      '$_repo/releases/download/v$version/app-arm64-v8a-release.apk',
  'linux_url':
      '$_repo/releases/download/v$version/tadbeer-linux-x64.tar.gz',
  'is_mandatory': false,
};

void _rewrite(String path, String Function(String) change) {
  final file = File(path);
  file.writeAsStringSync(change(file.readAsStringSync()));
}

void main(List<String> args) {
  if (args.length != 1 || !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(args.first)) {
    stderr.writeln('Usage: dart run tool/release.dart <version, like 1.0.1>');
    exit(64);
  }
  final version = args.first;
  final date = DateTime.now().toIso8601String().substring(0, 10);

  try {
    final (current, lastBuild) = pubspecVersion(
      File('pubspec.yaml').readAsStringSync(),
    );
    if (current == version) {
      throw FormatException('pubspec.yaml is already at $version');
    }
    final build = lastBuild + 1;

    // Read the notes first: a missing section stops before any file changes.
    final (changelog, notes) = cutChangelog(
      File('CHANGELOG.md').readAsStringSync(),
      version,
      date,
    );

    File('CHANGELOG.md').writeAsStringSync(changelog);
    _rewrite('pubspec.yaml', (s) => setPubspecVersion(s, version, build));
    _rewrite(
      'lib/features/updates/app_update_service.dart',
      (s) => setServiceVersion(s, version, build),
    );
    final json =
        '${const JsonEncoder.withIndent('  ').convert(versionJson(version, build, date, notes))}\n';
    File('version.json').writeAsStringSync(json);
    File('docs/version.json').writeAsStringSync(json);
    File(
      'fastlane/metadata/android/ar/changelogs/$build.txt',
    ).writeAsStringSync('${notes.map((n) => '- $n').join('\n')}\n');

    stdout.writeln('''
Prepared $version (build $build).

Write the English store notes: fastlane/metadata/android/en-US/changelogs/$build.txt

Then, in this order (push the tag only; the release workflow moves main
forward once the APKs are uploaded, so nobody is offered a missing file):
  flutter test
  git add pubspec.yaml CHANGELOG.md version.json docs/version.json lib/features/updates/app_update_service.dart fastlane
  git commit -m "release: v$version"
  git tag v$version
  git push origin v$version''');
  } on FormatException catch (e) {
    stderr.writeln('Release not prepared: ${e.message}');
    exit(1);
  }
}
