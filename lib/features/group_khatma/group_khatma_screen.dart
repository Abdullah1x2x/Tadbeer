import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/localization.dart';
import '../../app/theme.dart';
import '../../core/storage/user_data_store.dart';
import '../quran/screens/quran_screen.dart';
import 'group_khatma.dart';

/// شاشة الختمة الجماعية: إنشاء وتوزيع الأجزاء، أو الانضمام برمز.
class GroupKhatmaScreen extends StatelessWidget {
  /// ينشئ شاشة الختمة الجماعية.
  const GroupKhatmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Directionality(
      textDirection: context.currentLanguage.direction,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.groupKhatma)),
        body: ListenableBuilder(
          listenable: UserDataStore.instance,
          builder: (context, _) {
            final khatma = GroupKhatmaStore.current();
            if (khatma == null) return const _SetupView();
            if (khatma.me == null) return _PickNameView(khatma: khatma);
            return _KhatmaView(khatma: khatma);
          },
        ),
      ),
    );
  }
}

/// إنشاء ختمة جديدة أو الانضمام برمز.
class _SetupView extends StatefulWidget {
  const _SetupView();

  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  final _title = TextEditingController();
  final _names = TextEditingController();
  final _code = TextEditingController();
  String? _codeError;

  @override
  void dispose() {
    _title.dispose();
    _names.dispose();
    _code.dispose();
    super.dispose();
  }

  void _create() {
    final names = _names.text
        .split('\n')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .take(juzCount)
        .toList();
    if (names.isEmpty) return;
    HapticFeedback.mediumImpact();
    GroupKhatmaStore.save(
      GroupKhatma.create(
        _title.text.trim().isEmpty
            ? context.l10n.groupKhatma
            : _title.text.trim(),
        names,
      ),
    );
  }

  void _join() {
    final khatma = GroupKhatma.fromCode(_code.text);
    if (khatma == null) {
      setState(() => _codeError = context.l10n.invalidGroupCode);
      return;
    }
    HapticFeedback.mediumImpact();
    GroupKhatmaStore.save(khatma);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          l10n.groupKhatmaHint,
          style: TextStyle(
            height: 1.6,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.createGroupKhatma,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _title,
                  decoration: InputDecoration(labelText: l10n.groupKhatmaTitle),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _names,
                  minLines: 3,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: l10n.participantNames,
                    hintText: l10n.oneNamePerLine,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.groups_rounded),
                  label: Text(l10n.distributeJuz),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.joinWithCode,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.pasteGroupCode,
                    errorText: _codeError,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _join,
                  icon: const Icon(Icons.login_rounded),
                  label: Text(l10n.join),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// اختيار اسم المستخدم بين المشاركين.
class _PickNameView extends StatelessWidget {
  final GroupKhatma khatma;

  const _PickNameView({required this.khatma});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          khatma.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.whoAreYou,
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < khatma.names.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.person_rounded),
              title: Text(khatma.names[i]),
              subtitle: Text(l10n.juzList(khatma.juzOf(i))),
              onTap: () => GroupKhatmaStore.save(khatma.copyWith(me: i)),
            ),
          ),
      ],
    );
  }
}

/// متابعة الختمة: أجزائي، ومشاركة الرمز، وتوزيع الجميع.
class _KhatmaView extends StatelessWidget {
  final GroupKhatma khatma;

  const _KhatmaView({required this.khatma});

  String _shareText(AppStrings l10n) {
    final buffer = StringBuffer()
      ..writeln('📖 ${khatma.title}')
      ..writeln();
    for (var i = 0; i < khatma.names.length; i++) {
      buffer.writeln('• ${khatma.names[i]}: ${l10n.juzList(khatma.juzOf(i))}');
    }
    buffer
      ..writeln()
      ..writeln(l10n.groupCodeIntro)
      ..writeln(khatma.shareCode);
    return buffer.toString();
  }

  void _showQr(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(khatma.title, textAlign: TextAlign.center),
        content: SizedBox(
          width: 240,
          height: 240,
          child: QrImageView(
            data: khatma.shareCode,
            backgroundColor: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leaveGroupKhatma),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.leaveGroupKhatma),
          ),
        ],
      ),
    );
    if (ok == true) await GroupKhatmaStore.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gold = AppColors.accentGold(context);
    final mine = khatma.juzOf(khatma.me!);
    final doneCount = mine.where(khatma.done.contains).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                khatma.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.showQr,
              icon: const Icon(Icons.qr_code_2_rounded),
              onPressed: () => _showQr(context),
            ),
            IconButton(
              tooltip: l10n.share,
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () =>
                  SharePlus.instance.share(ShareParams(text: _shareText(l10n))),
            ),
            IconButton(
              tooltip: l10n.leaveGroupKhatma,
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _confirmLeave(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_rounded, color: gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.myJuzTitle(khatma.names[khatma.me!]),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      l10n.versesOfTotal(doneCount, mine.length),
                      style: TextStyle(
                        color: gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final juz in mine)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: khatma.done.contains(juz),
                    title: Text(l10n.juzLabel(juz)),
                    secondary: IconButton(
                      tooltip: l10n.readJuz,
                      icon: const Icon(Icons.menu_book_rounded),
                      // Viewing mode: group reading never moves the
                      // personal reading position or khatma.
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              QuranScreen(initialPage: firstPageOfJuz(juz)),
                        ),
                      ),
                    ),
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      final done = {...khatma.done};
                      v == true ? done.add(juz) : done.remove(juz);
                      GroupKhatmaStore.save(khatma.copyWith(done: done));
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ExpansionTile(
            title: Text(l10n.everyonesJuz),
            children: [
              for (var i = 0; i < khatma.names.length; i++)
                ListTile(
                  dense: true,
                  title: Text(khatma.names[i]),
                  trailing: Text(l10n.juzList(khatma.juzOf(i))),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
