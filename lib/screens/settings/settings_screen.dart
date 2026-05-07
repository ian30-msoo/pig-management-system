import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotif = true;
  bool _feedingReminders = true;
  bool _healthAlerts = true;
  bool _communityUpdates = false;
  bool _weeklyReport = true;
  String _language = 'English';
  String _currency = 'KES (Ksh)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20, right: 20, bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(width: 12),
                const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionLabel('Notifications'),
                _SettingsCard(children: [
                  _SwitchRow(
                    icon: Icons.notifications_active_rounded,
                    color: AppColors.primary,
                    title: 'Push Notifications',
                    subtitle: 'All app notifications',
                    value: _pushNotif,
                    onChanged: (v) => setState(() => _pushNotif = v),
                  ),
                  const Divider(height: 1),
                  _SwitchRow(
                    icon: Icons.restaurant_rounded,
                    color: AppColors.warning,
                    title: 'Feeding Reminders',
                    subtitle: 'Daily feeding schedule alerts',
                    value: _feedingReminders,
                    onChanged: (v) => setState(() => _feedingReminders = v),
                  ),
                  const Divider(height: 1),
                  _SwitchRow(
                    icon: Icons.medical_services_rounded,
                    color: AppColors.danger,
                    title: 'Health Alerts',
                    subtitle: 'Disease & vaccination reminders',
                    value: _healthAlerts,
                    onChanged: (v) => setState(() => _healthAlerts = v),
                  ),
                  const Divider(height: 1),
                  _SwitchRow(
                    icon: Icons.people_rounded,
                    color: AppColors.blue,
                    title: 'Community Updates',
                    subtitle: 'New posts & comments',
                    value: _communityUpdates,
                    onChanged: (v) => setState(() => _communityUpdates = v),
                  ),
                  const Divider(height: 1),
                  _SwitchRow(
                    icon: Icons.bar_chart_rounded,
                    color: AppColors.success,
                    title: 'Weekly Report',
                    subtitle: 'Every Sunday morning',
                    value: _weeklyReport,
                    onChanged: (v) => setState(() => _weeklyReport = v),
                  ),
                ]),

                const SizedBox(height: 16),
                _sectionLabel('Preferences'),
                _SettingsCard(children: [
                  _TapRow(
                    icon: Icons.language_rounded,
                    color: AppColors.primary,
                    title: 'Language',
                    trailing: _language,
                    onTap: () => _showOptions(context, 'Language', ['English', 'Swahili'], (v) => setState(() => _language = v)),
                  ),
                  const Divider(height: 1),
                  _TapRow(
                    icon: Icons.currency_exchange_rounded,
                    color: AppColors.success,
                    title: 'Currency',
                    trailing: _currency,
                    onTap: () => _showOptions(context, 'Currency', ['KES (Ksh)', 'USD (\$)', 'EUR (€)'], (v) => setState(() => _currency = v)),
                  ),
                  const Divider(height: 1),
                  _TapRow(
                    icon: Icons.palette_rounded,
                    color: AppColors.warning,
                    title: 'Theme',
                    trailing: 'Light',
                    onTap: () {},
                  ),
                ]),

                const SizedBox(height: 16),
                _sectionLabel('Data & Privacy'),
                _SettingsCard(children: [
                  _TapRow(icon: Icons.backup_rounded, color: AppColors.blue, title: 'Backup Data', trailing: '', onTap: () {}),
                  const Divider(height: 1),
                  _TapRow(icon: Icons.download_rounded, color: AppColors.success, title: 'Export Data (CSV)', trailing: '', onTap: () {}),
                  const Divider(height: 1),
                  _TapRow(icon: Icons.delete_forever_rounded, color: AppColors.danger, title: 'Delete Account', trailing: '', onTap: () => _deleteAccountDialog(context), dangerous: true),
                ]),

                const SizedBox(height: 16),
                _sectionLabel('About'),
                _SettingsCard(children: [
                  _TapRow(icon: Icons.info_rounded, color: AppColors.blue, title: 'App Version', trailing: '1.0.0', onTap: () {}),
                  const Divider(height: 1),
                  _TapRow(icon: Icons.description_rounded, color: AppColors.gray600, title: 'Terms of Service', trailing: '', onTap: () {}),
                  const Divider(height: 1),
                  _TapRow(icon: Icons.privacy_tip_rounded, color: AppColors.gray600, title: 'Privacy Policy', trailing: '', onTap: () {}),
                  const Divider(height: 1),
                  _TapRow(icon: Icons.star_rounded, color: AppColors.warning, title: 'Rate MkulimaPro', trailing: '', onTap: () {}),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray400, letterSpacing: 1, fontFamily: 'Poppins')),
  );

  void _showOptions(BuildContext context, String title, List<String> options, void Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          ...options.map((o) => ListTile(
            title: Text(o, style: const TextStyle(fontFamily: 'Poppins')),
            onTap: () { onSelect(o); Navigator.pop(context); },
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _deleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.danger)),
        content: const Text('This action is permanent and cannot be undone. All your farm data will be deleted.', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { Navigator.pop(ctx); },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
    child: Column(children: children),
  );
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.icon, required this.color, required this.title, required this.subtitle, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    secondary: Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
    title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
    value: value,
    onChanged: onChanged,
    activeColor: AppColors.primary,
  );
}

class _TapRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, trailing;
  final VoidCallback onTap;
  final bool dangerous;
  const _TapRow({required this.icon, required this.color, required this.title, required this.trailing, required this.onTap, this.dangerous = false});
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
    title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: dangerous ? AppColors.danger : AppColors.dark, fontFamily: 'Poppins')),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trailing.isNotEmpty) Text(trailing, style: const TextStyle(fontSize: 12, color: AppColors.gray400, fontFamily: 'Poppins')),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, color: AppColors.gray200, size: 20),
      ],
    ),
    dense: true,
  );
}
