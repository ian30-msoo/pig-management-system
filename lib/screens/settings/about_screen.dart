import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 20, right: 20, bottom: 0),
            decoration: const BoxDecoration(
              color: AppColors.dark,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.savings_rounded, color: Colors.white, size: 46),
                ),
                const SizedBox(height: 14),
                const Text('PigTrack', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins')),
                const Text('Smart Pig Management System', style: TextStyle(fontSize: 13, color: Colors.white60, fontFamily: 'Poppins')),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: AppColors.primary, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _AboutCard(
                  title: 'About the App',
                  content: 'PigTrack is a comprehensive pig farm management system built for Kenyan pig farmers, veterinarians, and livestock officers. It provides tools for tracking pig health, managing feeding schedules, recording financial transactions, and connecting with the farming community.',
                ),
                const SizedBox(height: 16),
                const _AboutCard(
                  title: 'Project Information',
                  content: 'This app was developed as part of an academic research project at Meru University of Science & Technology. It aims to modernize and digitize pig farming in Kenya using mobile technology and AI.',
                ),
                const SizedBox(height: 16),
                const _InfoTile(Icons.person_rounded, 'Developer', 'Ian Wanjohi Muthoni'),
                const _InfoTile(Icons.badge_rounded, 'Registration No.', 'CT203/109328/22'),
                const _InfoTile(Icons.school_rounded, 'Institution', 'Meru University of Science & Technology'),
                const _InfoTile(Icons.supervisor_account_rounded, 'Supervisor', 'Mwenda Gichuru'),
                const SizedBox(height: 24),

                const Text('Key Features', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
                const SizedBox(height: 10),
                ...[ 
                  (Icons.savings_rounded, 'Pig Records Management', 'Track all pigs with breed, health & weight data'),
                  (Icons.restaurant_rounded, 'Feeding Schedule Tracker', 'Log and monitor daily feeding sessions'),
                  (Icons.medical_services_rounded, 'Health Records & Alerts', 'Track vaccinations and medical records'),
                  (Icons.smart_toy_rounded, 'AI Disease Predictor', 'AI-powered disease outbreak prediction'),
                  (Icons.people_rounded, 'Farmer Community', 'Connect with farmers and veterinarians'),
                  (Icons.account_balance_wallet_rounded, 'Financial Records', 'Track income, expenses and profitability'),
                  (Icons.bar_chart_rounded, 'Analytics & Reports', 'Visualize farm performance data'),
                ].map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
                  child: Row(children: [
                    Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(10)), child: Icon(f.$1, color: AppColors.primary, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
                      Text(f.$3, style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
                    ])),
                  ]),
                )),
                const SizedBox(height: 24),
                Center(child: Text('Made with ❤️ in Kenya\n© 2026 PigTrack', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.gray400, fontFamily: 'Poppins', height: 1.6))),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String title, content;
  const _AboutCard({required this.title, required this.content});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
      const SizedBox(height: 8),
      Text(content, style: const TextStyle(fontSize: 13, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.6)),
    ]),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primary, size: 18)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
      ]),
    ]),
  );
}
