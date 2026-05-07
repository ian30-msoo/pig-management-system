// lib/screens/ai/ai_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/providers.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';
import '../../models/pig_model.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MESSAGE MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _Msg {
  final String role, content;
  final DateTime ts;
  final bool isStreaming, isHerdReport, isPigReport, isPigList, isNewsBlock;
  final List<PigModel>? pigs;
  final List<FarmNews>? news;

  const _Msg({
    required this.role, required this.content, required this.ts,
    this.isStreaming = false, this.isHerdReport = false,
    this.isPigReport = false, this.isPigList = false,
    this.isNewsBlock = false, this.pigs, this.news,
  });

  Map<String, String> toApi() => {'role': role, 'content': content};
}

// ─────────────────────────────────────────────────────────────────────────────
//  QUICK PROMPTS
// ─────────────────────────────────────────────────────────────────────────────

class _QP {
  final String label, msg;
  final IconData icon;
  final Color color;
  const _QP(this.icon, this.color, this.label, this.msg);
}

final _prompts = [
  _QP(Icons.local_hospital_rounded, AppColors.danger, 'Sick Pig',
      'My pig has a high fever and is not eating. What could be wrong and what should I do immediately?'),
  _QP(Icons.restaurant_rounded, AppColors.success, 'Feeding Plan',
      'Create a daily feeding plan for my growers and finishers using Kenyan ingredients.'),
  _QP(Icons.favorite_rounded, const Color(0xFFEC4899), 'Breeding',
      'How do I know when my sow is ready to breed? What are the signs of heat?'),
  _QP(Icons.vaccines_rounded, AppColors.blue, 'Vaccines',
      'What vaccines does my pig herd need and the recommended schedule for Kenya?'),
  _QP(Icons.trending_up_rounded, AppColors.success, 'Profit Tips',
      'How can I increase the profitability of my pig farm in Kenya?'),
  _QP(Icons.monitor_weight_rounded, const Color(0xFFF59E0B), 'Weight Check',
      'My grower pig is 20 weeks old but only weighs 45 kg. Is this normal?'),
  _QP(Icons.security_rounded, AppColors.blue, 'Biosecurity',
      'How do I protect my farm from African Swine Fever in Kenya?'),
  _QP(Icons.attach_money_rounded, AppColors.success, 'Market Price',
      'What is the current market price for pigs in Kenya per kg live weight?'),
];

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});
  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();

  final List<_Msg> _msgs = [];
  bool _loading = false, _pigsLoading = false, _newsLoading = false;
  String? _sessionId, _userId;

  static final _epoch = DateTime(2000);

  @override
  void initState() {
    super.initState();
    _userId = context.read<app_auth.AuthProvider>().user?.uid;
    _welcome();
    _focusNode.addListener(() => setState(() {}));
  }

  void _welcome() {
    _msgs.add(_Msg(
      role: 'assistant', ts: _epoch,
      content:
      'Hello farmer! I am PigTrack AI — your expert pig farming advisor.\n\n'
          'I can help you with:\n\n'
          '1. Disease diagnosis and health management\n'
          '2. Feeding plans with Kenyan ingredients\n'
          '3. Breeding and reproduction guidance\n'
          '4. Growth tracking and market price prediction\n'
          '5. Farm financial management in KES\n'
          '6. Biosecurity and housing\n\n'
          '[TIP] Tap "My Animals" to see your pigs. Tap "AI Analysis" on any pig for a detailed report.\n\n'
          'Ask me anything about your pigs!',
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose(); _scrollCtrl.dispose(); _focusNode.dispose();
    super.dispose();
  }

  // ── Send ──────────────────────────────────────────────────────────────────
  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _loading) return;
    _inputCtrl.clear(); _focusNode.unfocus();

    final now = DateTime.now();
    setState(() {
      _msgs.add(_Msg(role: 'user', content: t, ts: now));
      _msgs.add(_Msg(role: 'assistant', content: '', ts: now, isStreaming: true));
      _loading = true;
    });
    _scrollDown();

    if (_sessionId == null && _userId != null) {
      try { _sessionId = await FirestoreService.createAiChatSession(_userId!, t); } catch (_) {}
    }
    if (_sessionId != null && _userId != null) {
      FirestoreService.saveAiMessage(userId: _userId!, sessionId: _sessionId!, role: 'user', content: t);
    }

    final history = _msgs
        .where((m) => !m.isStreaming && !m.isPigList && !m.isNewsBlock && m.ts != _epoch)
        .map((m) => m.toApi()).toList();

    final reply = await AiService.chat(messages: history);
    if (!mounted) return;
    setState(() {
      _msgs.removeLast();
      _msgs.add(_Msg(role: 'assistant', content: reply, ts: DateTime.now()));
      _loading = false;
    });
    if (_sessionId != null && _userId != null) {
      FirestoreService.saveAiMessage(userId: _userId!, sessionId: _sessionId!, role: 'assistant', content: reply);
    }
    _scrollDown();
  }

  // ── Show pig list ONLY — no auto analysis ─────────────────────────────────
  Future<void> _showPigs() async {
    if (_pigsLoading || _loading) return;
    final pigs = context.read<PigProvider>().activePigs;

    if (pigs.isEmpty) {
      _addBot('No active pigs on your farm yet.\n\n'
          '[TIP] Go to the Pigs screen and tap "Add Pig" to register your first pig, '
          'then come back for AI analysis.');
      return;
    }

    setState(() {
      _pigsLoading = true;
      _msgs.add(_Msg(role: 'user', content: 'Show me all my pigs', ts: DateTime.now()));
    });
    _scrollDown();

    final critical = pigs
        .where((p) => p.status == PigStatus.sick || p.status == PigStatus.quarantine)
        .toList();
    final critNames = critical.map((p) => p.name).join(', ');

    final intro = critical.isNotEmpty
        ? '[ALERT] ${critical.length} pig(s) need urgent attention: $critNames\n\n'
        'Here are your ${pigs.length} pig(s). Tap "AI Analysis" on any pig for a full report:'
        : 'Here are your ${pigs.length} pig(s). All healthy!\n\n'
        'Tap "AI Analysis" on any pig for a detailed health and feeding report:';

    setState(() {
      // ✅ Show pig cards ONLY — no auto herd analysis triggered
      _msgs.add(_Msg(
        role: 'assistant', content: intro,
        ts: DateTime.now(), isPigList: true, pigs: pigs,
      ));
      _pigsLoading = false;
    });
    _scrollDown();
  }

  // ── Analyse single pig (only on button tap) ───────────────────────────────
  Future<void> _analysePig(PigModel pig) async {
    if (_loading) return;
    setState(() {
      _msgs.add(_Msg(role: 'user', content: 'Give me a full AI analysis for ${pig.name} (${pig.tagId})', ts: DateTime.now()));
      _msgs.add(_Msg(role: 'assistant', content: '', ts: DateTime.now(), isStreaming: true));
      _loading = true;
    });
    _scrollDown();

    List<Map<String, dynamic>> hData = [], wData = [], fData = [];
    try {
      final pp = context.read<PigProvider>();
      final hRecs = await pp.getPigHealth(pig.id);
      final wRecs = await pp.getPigWeightHistory(pig.id);
      final fRecs = await pp.getPigFeeding(pig.id);
      hData = hRecs.map((h) => {'date': '${h.date.day}/${h.date.month}/${h.date.year}', 'type': h.type, 'condition': h.condition, 'status': h.status, 'treatment': h.treatment ?? ''}).toList();
      wData = wRecs.map((w) => {'date': '${w.date.day}/${w.date.month}/${w.date.year}', 'weightKg': w.weightKg}).toList();
      fData = fRecs.take(5).map((f) => {'date': '${f.date.day}/${f.date.month}/${f.date.year}', 'feedType': f.feedType, 'quantityKg': f.quantityKg}).toList();
    } catch (_) {}

    final reply = await AiService.analysePig(
      pig: {
        'name': pig.name, 'tagId': pig.tagId, 'breed': pig.breed,
        'gender': pig.gender.name, 'stage': pig.stage, 'weight': pig.weight,
        'ageLabel': pig.ageLabel, 'status': pig.status.label,
        'location': pig.location ?? 'Not specified', 'notes': pig.notes ?? 'None',
      },
      healthRecords: hData, weightHistory: wData, feedRecords: fData,
    );

    if (!mounted) return;
    setState(() {
      _msgs.removeLast();
      _msgs.add(_Msg(role: 'assistant', content: reply, ts: DateTime.now(), isPigReport: true));
      _loading = false;
    });
    _scrollDown();
  }

  // ── News ──────────────────────────────────────────────────────────────────
  Future<void> _showNews() async {
    if (_newsLoading || _loading) return;
    setState(() {
      _newsLoading = true;
      _msgs.add(_Msg(role: 'user', content: 'Show me the latest Kenya pig farming news', ts: DateTime.now()));
      _msgs.add(_Msg(role: 'assistant', content: '', ts: DateTime.now(), isStreaming: true));
    });
    _scrollDown();

    final news = await AiService.fetchLatestNews();
    if (!mounted) return;
    setState(() {
      _msgs.removeLast();
      _msgs.add(_Msg(
        role: 'assistant',
        content: 'Latest Kenya pig farming news and updates — April 2026:',
        ts: DateTime.now(), isNewsBlock: true, news: news,
      ));
      _newsLoading = false;
    });
    _scrollDown();
  }

  // ── Herd AI (explicit button — user requested) ────────────────────────────
  Future<void> _herdAI() async {
    if (_loading) return;
    final pigs = context.read<PigProvider>().activePigs;
    if (pigs.isEmpty) { _addBot('No active pigs found. Please add pigs first.'); return; }

    setState(() {
      _msgs.add(_Msg(role: 'user', content: 'Give me a complete AI analysis of my ${pigs.length} pig herd.', ts: DateTime.now()));
      _msgs.add(_Msg(role: 'assistant', content: '', ts: DateTime.now(), isStreaming: true));
      _loading = true;
    });
    _scrollDown();

    final pigsData = pigs.map((p) => {
      'id': p.id, 'name': p.name, 'tagId': p.tagId, 'breed': p.breed,
      'gender': p.gender.name, 'stage': p.stage, 'weight': p.weight,
      'ageLabel': p.ageLabel, 'status': p.status.label,
      'location': p.location ?? 'Not set', 'notes': p.notes ?? '',
    }).toList();

    final reply = await AiService.analyseHerd(pigsData: pigsData);
    if (!mounted) return;
    setState(() {
      _msgs.removeLast();
      _msgs.add(_Msg(role: 'assistant', content: reply, ts: DateTime.now(), isHerdReport: true));
      _loading = false;
    });
    _scrollDown();
  }

  void _addBot(String c) {
    setState(() => _msgs.add(_Msg(role: 'assistant', content: c, ts: DateTime.now())));
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 160,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut,
        );
      }
    });
  }

  void _newChat() {
    setState(() { _sessionId = null; _msgs.clear(); _welcome(); });
  }

  void _copy(String c) {
    Clipboard.setData(ClipboardData(text: c));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Copied to clipboard', style: TextStyle(fontFamily: 'Poppins')),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showHistory() {
    if (_userId == null) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _HistorySheet(
        userId: _userId!,
        onLoad: (msgs) {
          Navigator.pop(context);
          setState(() {
            _msgs.clear();
            for (final m in msgs) {
              _msgs.add(_Msg(role: m['role'] ?? 'assistant', content: m['content'] ?? '', ts: DateTime.now()));
            }
          });
          _scrollDown();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final pp = context.watch<PigProvider>();

    return ColoredBox(
      color: AppColors.offWhite,
      child: Column(children: [
        _Header(
          top: mq.padding.top,
          pigCount: pp.activePigs.length,
          sickCount: pp.sickCount + pp.quarantineCount,
          onNewChat: _newChat,
          onHistory: _showHistory,
        ),
        _ActionRow(
          pigsLoading: _pigsLoading, newsLoading: _newsLoading, isLoading: _loading,
          onPigs: _showPigs, onNews: _showNews, onHerd: _herdAI,
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _prompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final p = _prompts[i];
              return GestureDetector(
                onTap: () => _send(p.msg),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gray200),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(p.icon, size: 12, color: p.color),
                    const SizedBox(width: 5),
                    Text(p.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _msgs.length <= 1
              ? _WelcomeView(onPrompt: (p) => _send(p.msg), onPigs: _showPigs, onNews: _showNews, onHerd: _herdAI)
              : ListView.builder(
            controller: _scrollCtrl, physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            itemCount: _msgs.length,
            itemBuilder: (_, i) {
              final m = _msgs[i];
              return _BubbleWidget(msg: m, onCopy: () => _copy(m.content), onPig: _analysePig);
            },
          ),
        ),
        _InputBar(
          ctrl: _inputCtrl, focus: _focusNode,
          loading: _loading || _pigsLoading || _newsLoading,
          bottom: mq.padding.bottom, onSend: _send,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double top;
  final int pigCount, sickCount;
  final VoidCallback onNewChat, onHistory;
  const _Header({required this.top, required this.pigCount, required this.sickCount, required this.onNewChat, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(top: top + 14, left: 18, right: 18, bottom: 16),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5)),
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('PigTrack AI', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins')),
          Row(children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(
              pigCount == 0 ? 'Pig Farming Expert' : '$pigCount pig${pigCount != 1 ? "s" : ""} ${sickCount > 0 ? "· $sickCount need attention" : "· all healthy"}',
              style: TextStyle(fontSize: 11, color: sickCount > 0 ? const Color(0xFFFFD700) : Colors.white70, fontFamily: 'Poppins', fontWeight: sickCount > 0 ? FontWeight.w600 : FontWeight.normal),
            ),
          ]),
        ])),
        GestureDetector(
          onTap: onHistory,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
            child: const Icon(Icons.history_rounded, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onNewChat,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
            child: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 17),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ACTION ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final bool pigsLoading, newsLoading, isLoading;
  final VoidCallback onPigs, onNews, onHerd;
  const _ActionRow({required this.pigsLoading, required this.newsLoading, required this.isLoading, required this.onPigs, required this.onNews, required this.onHerd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(children: [
        _Btn(label: 'My Animals', icon: Icons.pets_rounded, color: AppColors.primary, loading: pigsLoading, disabled: isLoading, onTap: onPigs, outline: true),
        const SizedBox(width: 8),
        _Btn(label: 'Latest News', icon: Icons.newspaper_rounded, color: AppColors.blue, loading: newsLoading, disabled: isLoading, onTap: onNews, outline: true),
        const SizedBox(width: 8),
        _Btn(label: 'Herd AI', icon: Icons.analytics_rounded, color: Colors.white, loading: false, disabled: isLoading, onTap: onHerd, filled: true),
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading, disabled, outline, filled;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.icon, required this.color, required this.loading, required this.disabled, required this.onTap, this.outline = false, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: loading || disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: filled ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: outline ? Border.all(color: color.withValues(alpha: 0.45), width: 1.5) : null,
            gradient: filled ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]) : null,
            boxShadow: [BoxShadow(color: (filled ? AppColors.primary : color).withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            loading
                ? SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: filled ? Colors.white : color))
                : Icon(icon, size: 14, color: filled ? Colors.white : color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: filled ? Colors.white : color, fontFamily: 'Poppins')),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WELCOME VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeView extends StatelessWidget {
  final void Function(_QP) onPrompt;
  final VoidCallback onPigs, onNews, onHerd;
  const _WelcomeView({required this.onPrompt, required this.onPigs, required this.onNews, required this.onHerd});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))]),
          child: Column(children: [
            Container(width: 56, height: 56, decoration: const BoxDecoration(color: AppColors.primaryBg, shape: BoxShape.circle),
                child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 28)),
            const SizedBox(height: 10),
            const Text('PigTrack AI', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark, fontFamily: 'Poppins')),
            const SizedBox(height: 4),
            const Text('Expert pig farming advisor for Kenya\nDisease diagnosis · Price prediction · Live news',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins', height: 1.5)),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: const [
              _Chip(Icons.local_hospital_rounded, 'Disease AI'),
              _Chip(Icons.restaurant_rounded, 'Feeding Plans'),
              _Chip(Icons.favorite_rounded, 'Breeding'),
              _Chip(Icons.trending_up_rounded, 'Price Predict'),
              _Chip(Icons.analytics_rounded, 'Herd Analysis'),
              _Chip(Icons.newspaper_rounded, 'Live News'),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _FeaturedCard(icon: Icons.pets_rounded, label: 'My Animals', sub: 'View and analyse pigs', color: AppColors.primary, onTap: onPigs)),
          const SizedBox(width: 10),
          Expanded(child: _FeaturedCard(icon: Icons.newspaper_rounded, label: 'Latest News', sub: 'Kenya farming news 2026', color: AppColors.blue, onTap: onNews)),
        ]),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onHerd,
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.analytics_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('AI Herd Analysis', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins')),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        const Align(alignment: Alignment.centerLeft, child: Text('Quick Questions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins'))),
        const SizedBox(height: 8),
        ..._prompts.map((p) => GestureDetector(
          onTap: () => onPrompt(p),
          child: Container(
            width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)]),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: p.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(p.icon, color: p.color, size: 17)),
              const SizedBox(width: 12),
              Expanded(child: Text(p.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins'))),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.gray400),
            ]),
          ),
        )),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon; final String label;
  const _Chip(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppColors.primary), const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary, fontFamily: 'Poppins')),
    ]),
  );
}

class _FeaturedCard extends StatelessWidget {
  final IconData icon; final String label, sub; final Color color; final VoidCallback onTap;
  const _FeaturedCard({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8)]),
      child: Column(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins')),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins')),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  BUBBLE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _BubbleWidget extends StatelessWidget {
  final _Msg msg;
  final VoidCallback onCopy;
  final void Function(PigModel) onPig;
  const _BubbleWidget({required this.msg, required this.onCopy, required this.onPig});

  bool get _isUser => msg.role == 'user';

  @override
  Widget build(BuildContext context) {
    if (msg.isPigList && msg.pigs != null) return _PigListBubble(msg: msg, onPig: onPig);
    if (msg.isNewsBlock && msg.news != null) return _NewsBubble(msg: msg);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser) ...[_Avatar(), const SizedBox(width: 8)],
          Flexible(
            child: GestureDetector(
              onLongPress: msg.isStreaming ? null : onCopy,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                decoration: BoxDecoration(
                  color: _isUser ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(_isUser ? 18 : 4), bottomRight: Radius.circular(_isUser ? 4 : 18),
                  ),
                  boxShadow: [BoxShadow(color: _isUser ? AppColors.primary.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: msg.isStreaming
                    ? const _Dots()
                    : _isUser
                    ? Text(msg.content, style: const TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'Poppins', height: 1.5))
                    : _FmtText(text: msg.content),
              ),
            ),
          ),
          if (_isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PIG LIST BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _PigListBubble extends StatelessWidget {
  final _Msg msg;
  final void Function(PigModel) onPig;
  const _PigListBubble({required this.msg, required this.onPig});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Avatar(), const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
            ),
            child: _FmtText(text: msg.content),
          ),
          const SizedBox(height: 8),
          // Pig cards — no auto analysis, user must tap button
          ...msg.pigs!.map((pig) => _PigCard(pig: pig, onAnalyse: () => onPig(pig))),
        ])),
      ]),
    );
  }
}

class _PigCard extends StatelessWidget {
  final PigModel pig;
  final VoidCallback onAnalyse;
  const _PigCard({required this.pig, required this.onAnalyse});

  IconData _stageIcon(String s) {
    switch (s.toLowerCase()) {
      case 'piglet':   return Icons.child_care_rounded;
      case 'weaner':   return Icons.pets_rounded;
      case 'sow':      return Icons.female_rounded;
      case 'boar':     return Icons.male_rounded;
      default:         return Icons.pets_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = pig.status == PigStatus.sick || pig.status == PigStatus.quarantine;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: isCritical
            ? Border.all(color: AppColors.danger.withValues(alpha: 0.5), width: 1.5)
            : Border.all(color: AppColors.gray200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: isCritical ? AppColors.dangerBg : AppColors.primaryBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(_stageIcon(pig.stage), color: isCritical ? AppColors.danger : AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(pig.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: pig.status.bgColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(pig.status.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: pig.status.color, fontFamily: 'Poppins')),
                ),
              ]),
              const SizedBox(height: 2),
              Text('${pig.tagId} · ${pig.breed} · ${pig.stage}', style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins')),
            ])),
          ]),
          const SizedBox(height: 8),
          // Stats — Wrap prevents overflow on any screen width
          Wrap(spacing: 6, runSpacing: 6, children: [
            _Stat(Icons.monitor_weight_outlined, '${pig.weight.toStringAsFixed(1)} kg'),
            _Stat(Icons.access_time_rounded, pig.ageLabel),
            _Stat(pig.gender == PigGender.male ? Icons.male_rounded : Icons.female_rounded,
                pig.gender == PigGender.male ? 'Male' : 'Female'),
            if (pig.location != null && pig.location!.isNotEmpty)
              _Stat(Icons.location_on_outlined, pig.location!),
          ]),
          if (isCritical) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  pig.status == PigStatus.sick ? 'This pig is sick — needs immediate attention!' : 'This pig is in quarantine!',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.danger, fontFamily: 'Poppins'),
                )),
              ]),
            ),
          ],
          const SizedBox(height: 8),
          // ✅ User must tap this button — analysis only runs on explicit tap
          GestureDetector(
            onTap: onAnalyse,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                gradient: isCritical
                    ? const LinearGradient(colors: [AppColors.danger, Color(0xFFB91C1C)])
                    : const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(isCritical ? Icons.medical_services_rounded : Icons.analytics_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(isCritical ? 'Urgent AI Analysis' : 'Run AI Analysis',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon; final String label;
  const _Stat(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppColors.gray400), const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  NEWS BUBBLE
// ─────────────────────────────────────────────────────────────────────────────

class _NewsBubble extends StatelessWidget {
  final _Msg msg;
  const _NewsBubble({required this.msg});

  Color _catColor(String c) {
    switch (c) {
      case 'Health Alert': return AppColors.danger;
      case 'Market Price': return AppColors.success;
      case 'Breeding':     return const Color(0xFFEC4899);
      case 'Feed':         return const Color(0xFFF59E0B);
      default:             return AppColors.blue;
    }
  }

  IconData _catIcon(String c) {
    switch (c) {
      case 'Health Alert': return Icons.medical_services_rounded;
      case 'Market Price': return Icons.trending_up_rounded;
      case 'Breeding':     return Icons.favorite_rounded;
      case 'Feed':         return Icons.restaurant_rounded;
      default:             return Icons.lightbulb_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final news = msg.news!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Avatar(), const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
            ),
            child: Row(children: [
              const Icon(Icons.language_rounded, size: 14, color: AppColors.blue),
              const SizedBox(width: 8),
              Expanded(child: Text(msg.content, style: const TextStyle(fontSize: 12, color: AppColors.dark, fontFamily: 'Poppins', height: 1.4))),
            ]),
          ),
          const SizedBox(height: 8),
          ...news.map((item) {
            final color = _catColor(item.category);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: item.relevance == 'high'
                    ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5)
                    : Border.all(color: AppColors.gray200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_catIcon(item.category), size: 10, color: color),
                        const SizedBox(width: 4),
                        Text(item.category, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins')),
                      ]),
                    ),
                    if (item.relevance == 'high') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Text('IMPORTANT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.danger, fontFamily: 'Poppins')),
                      ),
                    ],
                    if (item.pubDate != null) ...[const Spacer(), Text(item.pubDate!, style: const TextStyle(fontSize: 9, color: AppColors.gray400, fontFamily: 'Poppins'))],
                  ]),
                  const SizedBox(height: 6),
                  Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
                  if (item.source != null) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.source_rounded, size: 10, color: AppColors.gray400),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item.source!, style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins', fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                  const SizedBox(height: 5),
                  Text(item.summary, style: const TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.45)),
                ]),
              ),
            );
          }),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FORMATTED TEXT
// ─────────────────────────────────────────────────────────────────────────────

class _FmtText extends StatelessWidget {
  final String text;
  const _FmtText({required this.text});

  @override
  Widget build(BuildContext context) {
    final cleaned = text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*', dotAll: true), r'\1')
        .replaceAll(RegExp(r'\*(.+?)\*', dotAll: true), r'\1')
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll(RegExp(r'---+'), '').trim();
    final parsed = AiService.parseResponse(cleaned);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parsed.blocks.map((b) {
        switch (b.type) {
          case AiBlockType.header:
            return Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text(b.content.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'Poppins', letterSpacing: 0.5)),
            );
          case AiBlockType.bullet:
            final lbl = b.label ?? '•';
            final isNum = RegExp(r'^\d+$').hasMatch(lbl);
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 22, child: Text(isNum ? '$lbl.' : lbl, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Poppins'))),
                Expanded(child: Text(b.content, style: const TextStyle(fontSize: 13, color: AppColors.dark, fontFamily: 'Poppins', height: 1.5))),
              ]),
            );
          case AiBlockType.alert:
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.danger.withValues(alpha: 0.3))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.danger), const SizedBox(width: 7),
                Expanded(child: Text(b.content, style: const TextStyle(fontSize: 12, color: AppColors.danger, fontFamily: 'Poppins', height: 1.4, fontWeight: FontWeight.w600))),
              ]),
            );
          case AiBlockType.tip:
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lightbulb_outlined, size: 15, color: AppColors.success), const SizedBox(width: 7),
                Expanded(child: Text(b.content, style: const TextStyle(fontSize: 12, color: AppColors.success, fontFamily: 'Poppins', height: 1.4, fontWeight: FontWeight.w600))),
              ]),
            );
          case AiBlockType.divider:
            return Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 8), color: AppColors.gray200);
          default:
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(b.content, style: const TextStyle(fontSize: 13, color: AppColors.dark, fontFamily: 'Poppins', height: 1.55)),
            );
        }
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HISTORY SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _HistorySheet extends StatelessWidget {
  final String userId;
  final void Function(List<Map<String, dynamic>>) onLoad;
  const _HistorySheet({required this.userId, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Row(children: [
            const Icon(Icons.history_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text('Chat History', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins'))),
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: Colors.white)),
          ]),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService.aiChatSessionsStream(userId),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final sessions = snap.data ?? [];
              if (sessions.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.gray200),
                  const SizedBox(height: 12),
                  const Text('No chat history yet', style: TextStyle(fontSize: 14, color: AppColors.gray400, fontFamily: 'Poppins')),
                  const SizedBox(height: 6),
                  Text('Start chatting to save history here', style: TextStyle(fontSize: 12, color: AppColors.gray400.withValues(alpha: 0.7), fontFamily: 'Poppins')),
                ]));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  final count = s['messageCount'] ?? 0;
                  return GestureDetector(
                    onTap: () async {
                      final msgs = await FirestoreService.getAiChatMessages(userId: userId, sessionId: s['id']);
                      onLoad(msgs);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
                      child: Row(children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.chat_rounded, color: AppColors.primary, size: 18)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s['title'] ?? 'Chat session', maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
                          const SizedBox(height: 2),
                          Text('$count message${count != 1 ? "s" : ""}', style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
                        ])),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.gray400, size: 18),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AVATAR  /  DOTS  /  INPUT BAR
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(color: AppColors.primaryBg, shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5)),
    child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 14),
  );
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 18,
    child: AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
        final v = ((_a.value - i * 0.25) % 1.0).clamp(0.0, 1.0);
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(width: 6, height: 6, decoration: BoxDecoration(color: Color.lerp(AppColors.gray300, AppColors.primary, v as double), shape: BoxShape.circle)));
      })),
    ),
  );
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focus;
  final bool loading;
  final double bottom;
  final void Function(String) onSend;
  const _InputBar({required this.ctrl, required this.focus, required this.loading, required this.bottom, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + bottom),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -3))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 110),
            decoration: BoxDecoration(
                color: AppColors.gray100, borderRadius: BorderRadius.circular(22),
                border: Border.all(color: focus.hasFocus ? AppColors.primary : AppColors.gray200, width: 1.5)),
            child: TextField(
              controller: ctrl, focusNode: focus, maxLines: null,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(fontSize: 13, fontFamily: 'Poppins', color: AppColors.dark),
              decoration: InputDecoration(
                  hintText: 'Ask about your pigs...', border: InputBorder.none,
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400, fontFamily: 'Poppins'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11)),
              onSubmitted: loading ? null : onSend,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: loading ? null : () => onSend(ctrl.text),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: loading
                  ? const LinearGradient(colors: [AppColors.gray300, AppColors.gray400])
                  : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryDark]),
              shape: BoxShape.circle,
              boxShadow: loading ? [] : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: loading
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 19),
          ),
        ),
      ]),
    );
  }
}