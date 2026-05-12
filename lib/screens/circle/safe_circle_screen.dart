import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/safe_circle_service.dart';
import '../../theme/app_theme.dart';

class SafeCircleScreen extends StatefulWidget {
  const SafeCircleScreen({super.key});

  @override
  State<SafeCircleScreen> createState() => _SafeCircleScreenState();
}

class _SafeCircleScreenState extends State<SafeCircleScreen> {
  final SafeCircleService _service = SafeCircleService();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final error = await _service.addMember(
      name:  _nameCtrl.text,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
    );

    if (!mounted) return;
    Navigator.pop(context); // close loader

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _emailCtrl.clear();
      Navigator.pop(context); // close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact added to Safe-Circle!')),
      );
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Trusted Contact',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'They don\'t need the app — just a phone or email.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),

              // Phone
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: 'e.g. 9876543210',
                ),
                validator: (v) => v == null || v.trim().length < 10
                    ? 'Enter a valid phone number'
                    : null,
              ),
              const SizedBox(height: 12),

              // Email (optional)
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'For email alerts',
                ),
                // no validator — email is optional
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _addMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add to Safe-Circle',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Safe-Circle',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Up to 5 trusted contacts (no app needed)',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.outline)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _showAddSheet,
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'When SOS fires, they get an SMS + email with your live location.',
                    style: TextStyle(fontSize: 12, color: colors.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getCircle(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: colors.outline),
                        const SizedBox(height: 12),
                        Text('No contacts yet',
                            style: TextStyle(
                                color: colors.outline,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          'Add family or friends.\nThey don\'t need to install the app.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: colors.outline, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final name  = data['name']  as String? ?? '?';
                    final phone = data['phone'] as String? ?? '';
                    final email = data['email'] as String? ?? '';

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.primaryContainer,
                          child: Text(
                            name[0].toUpperCase(),
                            style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.phone, size: 12),
                              const SizedBox(width: 4),
                              Text(phone, style: const TextStyle(fontSize: 12)),
                            ]),
                            if (email.isNotEmpty)
                              Row(children: [
                                const Icon(Icons.email, size: 12),
                                const SizedBox(width: 4),
                                Text(email,
                                    style: const TextStyle(fontSize: 12)),
                              ]),
                          ],
                        ),
                        isThreeLine: email.isNotEmpty,
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppTheme.primaryRed),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Remove contact?'),
                                content: Text('Remove $name from your Safe-Circle?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Remove',
                                          style: TextStyle(
                                              color: AppTheme.primaryRed))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _service.removeMember(docs[i].id);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}