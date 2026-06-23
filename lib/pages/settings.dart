import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/business_profile.dart';
import '../provider/InvoiceProvider.dart';
import '../provider/MenuProvider.dart';
import '../provider/settings_provider.dart';
import '../utils/const.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider = Provider.of<MenuItemsProvider>(context, listen: false);
      final invoiceProvider =
          Provider.of<InvoiceProvider>(context, listen: false);
      Provider.of<SettingsProvider>(context, listen: false)
          .fetchDatabaseData(menuProvider, invoiceProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final businessProvider = context.watch<BusinessProfileProvider>();
    final business = businessProvider.profile;

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionCard(
              title: 'Business Profile',
              child: _BusinessProfileForm(initial: business),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Backup & Restore',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: settingsProvider.backupProgress / 100,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          final menuProvider =
                              context.read<MenuItemsProvider>();
                          final invoiceProvider =
                              context.read<InvoiceProvider>();
                          settingsProvider.fetchDatabaseData(
                              menuProvider, invoiceProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Fetch Data'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async =>
                            settingsProvider.backupData(context),
                        icon: const Icon(Icons.backup),
                        label: const Text('Backup'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final menuProvider =
                              context.read<MenuItemsProvider>();
                          final invoiceProvider =
                              context.read<InvoiceProvider>();
                          settingsProvider.restoreData(
                              menuProvider, invoiceProvider);
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Restore'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Database Preview',
              child: Column(
                children: [
                  _buildSection('Invoice', settingsProvider.invoices),
                  _buildSection('InvoiceItem', settingsProvider.invoiceItems),
                  _buildSection('MenuItem', settingsProvider.menuItems),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      color: secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> data) {
    if (data.isEmpty) {
      return ListTile(
        title: Text('$title: No Data Stored',
            style: const TextStyle(color: Colors.red)),
      );
    }
    return ExpansionTile(
      title: Text(title),
      children: data.map((item) {
        String displayText = item?.toString() ?? 'Empty item';
        return ListTile(title: Text(displayText));
      }).toList(),
    );
  }
}

/// Inline form for editing the singleton [BusinessProfile].
class _BusinessProfileForm extends StatefulWidget {
  final BusinessProfile initial;
  const _BusinessProfileForm({required this.initial});

  @override
  State<_BusinessProfileForm> createState() => _BusinessProfileFormState();
}

class _BusinessProfileFormState extends State<_BusinessProfileForm> {
  late final _nameCtl = TextEditingController(text: widget.initial.restaurantName);
  late final _addressCtl = TextEditingController(text: widget.initial.address);
  late final _phoneCtl = TextEditingController(text: widget.initial.phone);
  late final _upiCtl = TextEditingController(text: widget.initial.upiId);
  late final _payeeCtl = TextEditingController(text: widget.initial.payeeName);
  late final _mcCtl = TextEditingController(text: widget.initial.merchantCode);
  late final _footerCtl = TextEditingController(text: widget.initial.footerText);
  late final _taxCtl = TextEditingController(
      text: widget.initial.defaultTaxRatePercent.toString());
  late int _paperSize = widget.initial.paperSizeMm;

  @override
  void dispose() {
    _nameCtl.dispose();
    _addressCtl.dispose();
    _phoneCtl.dispose();
    _upiCtl.dispose();
    _payeeCtl.dispose();
    _mcCtl.dispose();
    _footerCtl.dispose();
    _taxCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<BusinessProfileProvider>();
    await provider.save(widget.initial.copyWith(
      restaurantName: _nameCtl.text.trim(),
      address: _addressCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      upiId: _upiCtl.text.trim(),
      payeeName: _payeeCtl.text.trim(),
      merchantCode: _mcCtl.text.trim(),
      footerText: _footerCtl.text.trim(),
      paperSizeMm: _paperSize,
      defaultTaxRatePercent: double.tryParse(_taxCtl.text.trim()) ?? 0,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Business profile saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(_nameCtl, 'Restaurant Name'),
        _field(_addressCtl, 'Address'),
        _field(_phoneCtl, 'Phone', keyboardType: TextInputType.phone),
        _field(_upiCtl, 'UPI ID (e.g. merchant@okbizaxis)'),
        _field(_payeeCtl, 'Payee Name (pn)'),
        _field(_mcCtl, 'Merchant Code (mc)'),
        _field(_footerCtl, 'Receipt Footer Text'),
        _field(_taxCtl, 'Default Tax Rate %', keyboardType: TextInputType.number),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Paper Size: '),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('58mm'),
              selected: _paperSize == 58,
              onSelected: (_) => setState(() => _paperSize = 58),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('80mm'),
              selected: _paperSize == 80,
              onSelected: (_) => setState(() => _paperSize = 80),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Profile'),
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctl, String label,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
