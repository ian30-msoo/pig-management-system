import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      _FAQ('How do I add a new pig?', 'Go to the Pigs section from the bottom navigation bar. Tap the "Add Pig" button in the top right corner. Fill in all the required details and press Save.'),
      _FAQ('How do I record a feeding session?', 'Navigate to the Feeding section from the sidebar or dashboard Quick Actions. Tap the "+" button to add a new feeding record. Select the pig, feed type, quantity, and time.'),
      _FAQ('How does the AI Disease Predictor work?', 'The AI analyzes symptoms you describe and compares them against a database of pig diseases common in Kenya. It provides risk levels and treatment recommendations. Always confirm with a licensed veterinarian.'),
      _FAQ('How do I join a community?', 'During onboarding, you can join communities. You can also go to Community from the bottom nav bar to view and participate in community discussions.'),
      _FAQ('How do I track finances?', 'Go to the Finance section from the bottom nav bar. You can record sales, expenses, and view your income/expense breakdown and reports.'),
      _FAQ('Can I use the app offline?', 'Basic features work offline. Data syncs automatically when you reconnect to the internet via Firebase.'),
      _FAQ('How do I change my password?', 'Go to Profile → Account Settings → Change Password. Enter your current password and set a new one.'),
      _FAQ('How do I back up my data?', 'Your data is automatically backed up to Firebase Cloud. Go to Settings → Data & Privacy → Backup Data to manually trigger a backup.'),
    ];

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 20, right: 20, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 8),
                const Text('Help & Support', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                const Text('How can we help you today?', style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Poppins')),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Quick Contact
                Row(
                  children: [
                    _ContactCard(Icons.phone_rounded, 'Call Us', '0800 723 022', AppColors.success, () {}),
                    const SizedBox(width: 10),
                    _ContactCard(Icons.email_rounded, 'Email', 'support@\PigTrack.co.ke', AppColors.blue, () {}),
                    const SizedBox(width: 10),
                    _ContactCard(Icons.chat_bubble_rounded, 'Live Chat', 'Chat with us', AppColors.warning, () {}),
                  ],
                ),
                const SizedBox(height: 20),

                const Text('Frequently Asked Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
                const SizedBox(height: 12),
                ...faqs.map((f) => _FAQTile(f)),

                const SizedBox(height: 20),
                const Text('Video Tutorials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
                const SizedBox(height: 12),
                ...['Getting Started with PigTrack', 'Recording Pig Health Data', 'Using the AI Predictor', 'Managing Farm Finances'].map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.play_circle_rounded, color: AppColors.danger, size: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins'))),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.gray400),
                  ]),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQ {
  final String question, answer;
  const _FAQ(this.question, this.answer);
}

class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  const _FAQTile(this.faq, {super.key});
  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
    child: Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 17)),
        title: Text(widget.faq.question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
        trailing: Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.gray400),
        onExpansionChanged: (v) => setState(() => _open = v),
        children: [Text(widget.faq.answer, style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.6))],
      ),
    ),
  );
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ContactCard(this.icon, this.title, this.subtitle, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins')),
          Text(subtitle, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7), fontFamily: 'Poppins', height: 1.3), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}
