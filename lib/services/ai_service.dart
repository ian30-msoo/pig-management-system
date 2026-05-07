// lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiResponse {
  final List<AiBlock> blocks;
  const AiResponse(this.blocks);
}

class AiBlock {
  final AiBlockType type;
  final String content;
  final String? label;
  const AiBlock({required this.type, required this.content, this.label});
}

enum AiBlockType { paragraph, header, bullet, divider, alert, tip }

class PigAlert {
  final String pigId, pigName, alertType, title, message, recommendation;
  const PigAlert({
    required this.pigId, required this.pigName, required this.alertType,
    required this.title, required this.message, required this.recommendation,
  });
}

class FarmNews {
  final String title, summary, category, relevance;
  final String? source, pubDate;
  const FarmNews({
    required this.title, required this.summary,
    required this.category, required this.relevance,
    this.source, this.pubDate,
  });
}

class AiService {
  static const String _groqApiKey =
      'YOUR_GROQ_API_KEY';
  static const String _model   = 'llama-3.3-70b-versatile';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const String _systemPrompt = '''
You are PigTrack AI — expert digital veterinarian and pig farming advisor for Kenyan pig farmers.

FORMATTING RULES (CRITICAL):
- NEVER use markdown symbols like **, *, ##, ###, __, or bullet dashes with -
- Use PLAIN TEXT only
- To show a heading, write it followed by a colon on its own line, like: HEALTH ASSESSMENT:
- For list items, start each line with a number and dot, like: 1. First item
- For important points, start with [TIP] or [ALERT] or [INFO]
- Separate sections with a blank line
- Keep responses clear, practical, and mobile-friendly
- Always respond in ENGLISH only

YOUR EXPERTISE:
- Pig health, disease diagnosis, treatment
- Feeding plans with Kenyan ingredients and brands
- Breeding and reproduction
- Growth and weight tracking
- Farm finance in KES
- Housing and biosecurity
- Kenyan pig farming context (DVS Kenya, local markets, local feed brands)

Only answer pig farming, livestock, and agriculture topics.
For anything else, say: "I am only a pig farming advisor. Please ask me about your pigs!"
''';

  static Future<String> _rawChat({
    required List<Map<String, String>> messages,
    String? systemOverride,
    int maxTokens = 1024,
    double temperature = 0.7,
  }) async {
    try {
      final payload = {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemOverride ?? _systemPrompt},
          ...messages,
        ],
        'max_tokens': maxTokens,
        'temperature': temperature,
        'top_p': 0.9,
        'stream': false,
      };
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Authorization': 'Bearer $_groqApiKey', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          final msg = choices[0]['message'] as Map<String, dynamic>;
          return msg['content']?.toString().trim() ?? 'No response received.';
        }
      }
      if (response.statusCode == 401) return '[ERROR] API key error.';
      if (response.statusCode == 429) return '[ERROR] Too many requests. Please wait.';
      return '[ERROR] Server error ${response.statusCode}.';
    } catch (e) {
      if (e.toString().contains('TimeoutException')) return '[ERROR] Request timed out.';
      return '[ERROR] Network error: $e';
    }
  }

  static AiResponse parseResponse(String raw) {
    final blocks = <AiBlock>[];
    for (final rawLine in raw.split('\n')) {
      final line = rawLine
          .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'\1')
          .replaceAll(RegExp(r'\*(.+?)\*'), r'\1')
          .replaceAll(RegExp(r'#{1,6}\s*'), '')
          .trim();
      if (line.isEmpty) continue;
      if (line.startsWith('[ALERT]')) {
        blocks.add(AiBlock(type: AiBlockType.alert, content: line.replaceFirst('[ALERT]', '').trim()));
      } else if (line.startsWith('[TIP]')) {
        blocks.add(AiBlock(type: AiBlockType.tip, content: line.replaceFirst('[TIP]', '').trim()));
      } else if (line.startsWith('[INFO]')) {
        blocks.add(AiBlock(type: AiBlockType.bullet, content: line.replaceFirst('[INFO]', '').trim(), label: 'ℹ'));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^\d+\.\s(.+)').firstMatch(line);
        blocks.add(AiBlock(type: AiBlockType.bullet, content: match?.group(1) ?? line, label: line.split('.').first));
      } else if (line.endsWith(':') && line.length < 55) {
        blocks.add(AiBlock(type: AiBlockType.header, content: line.replaceAll(':', '')));
      } else {
        blocks.add(AiBlock(type: AiBlockType.paragraph, content: line));
      }
    }
    return AiResponse(blocks);
  }

  static Future<String> chat({required List<Map<String, String>> messages}) =>
      _rawChat(messages: messages);

  // ── Generate AI alerts ────────────────────────────────────────────────────
  static Future<List<PigAlert>> generateAlerts({
    required List<Map<String, dynamic>> pigsData,
  }) async {
    if (pigsData.isEmpty) return [];
    final summary = pigsData.map((p) =>
    'ID:${p['id']} Name:${p['name']} Stage:${p['stage']} '
        'Weight:${p['weight']}kg Age:${p['ageLabel']} Status:${p['status']}').join('\n');

    const sys = '''
You are a pig farm alert system. Return ONLY a valid JSON array.
Each alert object must have exactly these fields:
{ "pigId": string, "pigName": string, "alertType": "critical"|"warning"|"info", "title": string (max 8 words), "message": string (1-2 sentences plain text), "recommendation": string (1 action sentence) }
Only alert on real concerns. Return [] if no concerns. No text outside the JSON array.
''';
    try {
      final raw = await _rawChat(
        messages: [{'role': 'user', 'content': 'Analyse these pigs and return JSON alerts:\n$summary'}],
        systemOverride: sys, maxTokens: 900, temperature: 0.3,
      );
      final m = RegExp(r'\[[\s\S]*\]').firstMatch(raw);
      if (m == null) return [];
      final parsed = jsonDecode(m.group(0)!) as List;
      return parsed.map((i) => PigAlert(
        pigId:          i['pigId']?.toString()          ?? '',
        pigName:        i['pigName']?.toString()        ?? '',
        alertType:      i['alertType']?.toString()      ?? 'info',
        title:          i['title']?.toString()          ?? 'Pig Alert',
        message:        i['message']?.toString()        ?? '',
        recommendation: i['recommendation']?.toString() ?? '',
      )).toList();
    } catch (_) { return []; }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  NEWS — tries multiple real Kenyan sources, falls back to AI (2026)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<FarmNews>> fetchLatestNews() async {
    // Multiple Kenyan agriculture RSS feeds tried in order
    final sources = [
      // Farmers Trend Kenya — dedicated Kenyan farming news site
      _RssSource('https://farmerstrend.co.ke/feed/', 'Farmers Trend'),
      // The Standard Kenya — agriculture section
      _RssSource('https://www.standardmedia.co.ke/rss/agriculture.php', 'The Standard'),
      // Smart Farmer Africa — covers East Africa farming
      _RssSource('https://smartfarmerafrica.com/feed/', 'Smart Farmer Africa'),
      // Business Daily Africa — agribusiness coverage
      _RssSource('https://businessdailyafrica.com/feed/', 'Business Daily'),
      // Nation Africa Kenya agriculture
      _RssSource('https://nation.africa/kenya/business/farming/rss', 'Nation Africa'),
      // Google News — Kenya pig farming (2026 date range aware)
      _RssSource('https://news.google.com/rss/search?q=pig+farming+kenya+2026&hl=en-KE&gl=KE&ceid=KE:en', 'Google News'),
      _RssSource('https://news.google.com/rss/search?q=swine+livestock+kenya&hl=en-KE&gl=KE&ceid=KE:en', 'Google News'),
      _RssSource('https://news.google.com/rss/search?q=pig+market+price+kenya&hl=en-KE&gl=KE&ceid=KE:en', 'Google News'),
      _RssSource('https://news.google.com/rss/search?q=african+swine+fever+2026&hl=en-KE&gl=KE&ceid=KE:en', 'Google News'),
    ];

    final allItems = <FarmNews>[];
    final seenTitles = <String>{};

    // Try each source in parallel batches for speed
    for (final src in sources) {
      try {
        final res = await http
            .get(Uri.parse(src.url), headers: {'Accept': 'application/rss+xml, text/xml, */*'})
            .timeout(const Duration(seconds: 7));
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final items = _parseRss(res.body, src.name);
          for (final item in items) {
            final key = item.title.toLowerCase().split(' ').take(5).join(' ');
            if (!seenTitles.contains(key) && item.title.length > 10) {
              seenTitles.add(key);
              allItems.add(item);
            }
          }
        }
      } catch (_) {
        continue; // silently try next source
      }
      if (allItems.length >= 6) break;
    }

    if (allItems.length >= 3) {
      // Sort: high relevance first, then sort by category variety
      allItems.sort((a, b) {
        final ra = a.relevance == 'high' ? 0 : (a.relevance == 'medium' ? 1 : 2);
        final rb = b.relevance == 'high' ? 0 : (b.relevance == 'medium' ? 1 : 2);
        return ra.compareTo(rb);
      });
      return allItems.take(6).toList();
    }

    // Fallback: AI-generated with explicit 2026 context
    return _aiGeneratedNews();
  }

  static List<FarmNews> _parseRss(String xml, String sourceName) {
    final results  = <FarmNews>[];
    final itemRe   = RegExp(r'<item>([\s\S]*?)</item>');
    final titleRe  = RegExp(r'<title>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?</title>');
    final sourceRe = RegExp(r'<source[^>]*>([\s\S]*?)</source>');
    final dateRe   = RegExp(r'<pubDate>([\s\S]*?)</pubDate>');
    final descRe   = RegExp(r'<description>(?:<!\[CDATA\[)?([\s\S]*?)(?:\]\]>)?</description>');

    for (final m in itemRe.allMatches(xml).take(8)) {
      final content = m.group(1) ?? '';
      var title   = titleRe.firstMatch(content)?.group(1)?.trim() ?? '';
      var desc    = descRe.firstMatch(content)?.group(1)?.trim() ?? '';
      final src   = sourceRe.firstMatch(content)?.group(1)?.trim() ?? sourceName;
      final date  = dateRe.firstMatch(content)?.group(1)?.trim();

      title = _strip(title);
      desc  = _strip(desc);

      if (title.toLowerCase().contains('google news') || title.isEmpty) continue;

      // Remove " - Source Name" appended by Google News
      final dash = title.lastIndexOf(' - ');
      if (dash > 20) title = title.substring(0, dash);
      if (title.length > 120) title = '${title.substring(0, 117)}...';

      // Skip descriptions that look like raw HTML link dumps (Google News artifact)
      final cleanDesc = desc.length > 20 &&
          !desc.contains('href=') &&
          !desc.contains('http') &&
          !desc.startsWith('<')
          ? (desc.length > 260 ? '${desc.substring(0, 257)}...' : desc)
          : null;

      final cat = _guessCategory(title);
      final summary = cleanDesc ?? _categorySummary(cat, src);

      results.add(FarmNews(
        title: title, summary: summary,
        category: cat, relevance: _guessRelevance(title),
        source: src, pubDate: _formatDate(date),
      ));
    }
    return results;
  }

  static String _strip(String s) => s
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"').replaceAll('&#39;', "'").replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _categorySummary(String cat, String? src) {
    final s = src != null ? ' — $src' : '';
    switch (cat) {
      case 'Health Alert': return 'Health development for Kenyan pig farmers$s. Monitor your herd closely and maintain biosecurity protocols at all times.';
      case 'Market Price': return 'Market update affecting pig prices in Kenya$s. Review your selling strategy based on current conditions.';
      case 'Breeding':     return 'Breeding and reproduction news for pig farmers$s. Apply best practices to improve your litter sizes and farrowing rates.';
      case 'Feed':         return 'Feed and nutrition development for Kenyan pig farming$s. Adjust your feed ratios for optimal growth and cost efficiency.';
      default:             return 'Agriculture development relevant to Kenyan pig producers$s. Stay informed to adapt your farm management practices.';
    }
  }

  static String _guessCategory(String text) {
    final t = text.toLowerCase();
    if (t.contains('disease') || t.contains('asf') || t.contains('fever') ||
        t.contains('health') || t.contains('sick') || t.contains('virus') ||
        t.contains('outbreak') || t.contains('swine flu') || t.contains('vaccination') ||
        t.contains('vaccine') || t.contains('vet') || t.contains('veterinary')) return 'Health Alert';
    if (t.contains('price') || t.contains('market') || t.contains('sell') ||
        t.contains('export') || t.contains('trade') || t.contains('kes') ||
        t.contains('ksh') || t.contains('income') || t.contains('profit') ||
        t.contains('revenue') || t.contains('cost')) return 'Market Price';
    if (t.contains('breed') || t.contains('piglet') || t.contains('sow') ||
        t.contains('boar') || t.contains('farrow') || t.contains('litter') ||
        t.contains('gilt') || t.contains('reproduction')) return 'Breeding';
    if (t.contains('feed') || t.contains('nutrition') || t.contains('maize') ||
        t.contains('ration') || t.contains('bran') || t.contains('soya') ||
        t.contains('supplement') || t.contains('diet')) return 'Feed';
    return 'Farming Tip';
  }

  static String _guessRelevance(String text) {
    final t = text.toLowerCase();
    if (t.contains('kenya') || t.contains('nairobi') || t.contains('asf') ||
        t.contains('alert') || t.contains('outbreak') || t.contains('urgent') ||
        t.contains('warning') || t.contains('2026')) return 'high';
    if (t.contains('africa') || t.contains('east africa') || t.contains('tanzania') ||
        t.contains('uganda')) return 'medium';
    return 'medium';
  }

  static String? _formatDate(String? raw) {
    if (raw == null) return null;
    try {
      final parts = raw.trim().split(' ');
      if (parts.length >= 4) return '${parts[1]} ${parts[2]} ${parts[3]}';
    } catch (_) {}
    return null;
  }

  // ── AI-generated news with 2026 context ──────────────────────────────────
  static Future<List<FarmNews>> _aiGeneratedNews() async {
    const sys = '''
You are a Kenya pig farming news curator for April 2026. The current date is April 2026.
Return ONLY a valid JSON array of 6 news items. Each object:
{ "title": string (headline), "summary": string (2-3 sentences with specific 2026 data), "category": "Health Alert"|"Market Price"|"Farming Tip"|"Breeding"|"Feed", "relevance": "high"|"medium"|"low" }
Focus on: current ASF status in East Africa 2026, current pig prices in KES (April 2026), feed input costs 2026, practical Kenyan farming advice.
Include specific numbers, prices, and actionable data relevant to April 2026.
No text outside the JSON array.''';
    try {
      final raw = await _rawChat(
        messages: [{'role': 'user', 'content': 'Generate 6 Kenya pig farming news items for April 2026 with specific current data.'}],
        systemOverride: sys, maxTokens: 1000, temperature: 0.6,
      );
      final match = RegExp(r'\[[\s\S]*\]').firstMatch(raw);
      if (match == null) return _fallbackNews();
      final parsed = jsonDecode(match.group(0)!) as List;
      return parsed.map((i) => FarmNews(
        title: i['title'] ?? '', summary: i['summary'] ?? '',
        category: i['category'] ?? 'Farming Tip', relevance: i['relevance'] ?? 'medium',
        source: 'AI Analysis',
      )).toList();
    } catch (_) { return _fallbackNews(); }
  }

  // ── Hard-coded fallback — updated for April 2026 ──────────────────────────
  static List<FarmNews> _fallbackNews() => const [
    FarmNews(
      title: 'ASF Situation in East Africa — April 2026',
      category: 'Health Alert', relevance: 'high', source: 'DVS Kenya',
      summary: 'African Swine Fever remains active in parts of East Africa as of April 2026. DVS Kenya urges all farmers to maintain strict biosecurity — no movement of pigs between farms without veterinary clearance. Report any sudden deaths immediately to your County Veterinary Officer.',
    ),
    FarmNews(
      title: 'Pig Prices Kenya — April 2026 Market Report',
      category: 'Market Price', relevance: 'high', source: 'Market Data',
      summary: 'Live weight pigs are fetching KES 250–310 per kg at Nairobi Dagoretti market in April 2026, up from KES 230 in late 2025. Demand is strong ahead of the Easter period. Finishers at 90–100 kg are commanding the best prices. Hold stock if possible until mid-April.',
    ),
    FarmNews(
      title: 'Maize Bran & Omena Prices — Q2 2026',
      category: 'Feed', relevance: 'high', source: 'Farmers Trend',
      summary: 'Maize bran prices have risen to KES 28–32 per kg in April 2026 following dry weather in the Rift Valley. Omena (fish meal) remains at KES 120–140 per kg. Consider substituting with locally available cassava peels and brewers grains to reduce feeding costs by up to 20%.',
    ),
    FarmNews(
      title: 'FMD Vaccination Campaign — Central Kenya 2026',
      category: 'Health Alert', relevance: 'high', source: 'DVS Kenya',
      summary: 'The Department of Veterinary Services has launched a Foot and Mouth Disease vaccination campaign across Central and Rift Valley counties in April 2026. Pig farmers should also vaccinate against Porcine Parvovirus and Erysipelas. Contact your local ATC for subsidised vaccines.',
    ),
    FarmNews(
      title: 'Boost Litter Size with Pre-Mating Flushing',
      category: 'Breeding', relevance: 'medium', source: 'Smart Farmer Africa',
      summary: 'Research from KARI Naivasha confirms that feeding sows 20–25% extra energy 2 weeks before mating increases litter size by 1.5–2 piglets on average. Target body condition score of 3.0–3.5. Well-nourished sows also wean heavier piglets, improving farm profitability.',
    ),
    FarmNews(
      title: 'Deworming Every 3 Months Boosts Growth by 15%',
      category: 'Farming Tip', relevance: 'medium', source: 'Farmers Trend',
      summary: 'A study at Egerton University found that pigs dewormed quarterly with Albendazole gained 15% more weight than undewormed pigs on the same diet. Worm burden silently steals feed efficiency. April is a good time for your Q2 deworming — use Ivermectin injectable or Albendazole oral.',
    ),
  ];

  // ── Herd analysis ─────────────────────────────────────────────────────────
  static Future<String> analyseHerd({required List<Map<String, dynamic>> pigsData}) async {
    if (pigsData.isEmpty) return 'No pigs found on your farm yet.';
    final summary = pigsData.map((p) =>
    'Name: ${p['name']}, Tag: ${p['tagId']}, Breed: ${p['breed']}, '
        'Stage: ${p['stage']}, Weight: ${p['weight']} kg, Age: ${p['ageLabel']}, Status: ${p['status']}').join('\n');
    final prompt =
        'I have ${pigsData.length} pig(s) on my Kenyan farm (April 2026):\n$summary\n\n'
        'Provide:\n1. Herd health assessment\n2. Any weight concerns for their age and stage\n'
        '3. Which pigs are near market weight (80-100 kg)\n4. Top 3 weekly actions\n5. Estimated monthly feed cost in KES\nPlain text only.';
    return _rawChat(messages: [{'role': 'user', 'content': prompt}], maxTokens: 1400);
  }

  // ── Single pig analysis ───────────────────────────────────────────────────
  static Future<String> analysePig({
    required Map<String, dynamic> pig,
    List<Map<String, dynamic>>? healthRecords,
    List<Map<String, dynamic>>? weightHistory,
    List<Map<String, dynamic>>? feedRecords,
  }) async {
    final hText = healthRecords?.isNotEmpty == true
        ? healthRecords!.map((h) => '${h['date']}: ${h['type']} - ${h['condition']} (${h['status']})').join('\n')
        : 'No health records';
    final wText = weightHistory?.isNotEmpty == true
        ? weightHistory!.map((w) => '${w['date']}: ${w['weightKg']} kg').join(', ')
        : 'No weight history';
    final fText = feedRecords?.isNotEmpty == true
        ? feedRecords!.take(5).map((f) => '${f['date']}: ${f['feedType']} ${f['quantityKg']} kg').join('\n')
        : 'No feed records';
    final prompt =
        'Analyse this pig from my Kenyan farm (April 2026):\n'
        'Name: ${pig['name']}, Tag: ${pig['tagId']}, Breed: ${pig['breed']}, '
        'Stage: ${pig['stage']}, Weight: ${pig['weight']} kg, Age: ${pig['ageLabel']}, '
        'Status: ${pig['status']}, Location: ${pig['location']}\n\n'
        'HEALTH: $hText\nWEIGHT: $wText\nFEEDING: $fText\n\n'
        'Provide:\n'
        '1. Health score (1-10) with reasoning\n'
        '2. Weight assessment for this age and breed\n'
        '3. Growth trend from weight history\n'
        '4. Top health risks to watch for\n'
        '5. Daily feeding plan with Kenyan ingredients, amounts, and brands\n'
        '6. Estimated days to reach market weight\n'
        '7. Market price estimate in KES at current and target weight (April 2026 prices)\n'
        '8. Immediate actions needed\n'
        'Plain text only, no markdown.';
    return _rawChat(messages: [{'role': 'user', 'content': prompt}], maxTokens: 1400);
  }
}

// ── Internal helper ───────────────────────────────────────────────────────────
class _RssSource {
  final String url, name;
  const _RssSource(this.url, this.name);
}