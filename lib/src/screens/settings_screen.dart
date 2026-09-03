import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../widgets/app_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _businessName = TextEditingController();
  var _initialized = false;
  var _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _businessName.text = context.appState.business?.name ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _businessName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final email = state.user?.email ?? 'Signed-in user';

    return ListView(
      children: [
        ScreenPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                title: 'Settings',
                subtitle: 'Manage account and business details.',
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: Text(email),
                        subtitle: Text('User ID: ${state.user?.id ?? ''}'),
                      ),
                      const Divider(),
                      Text('Business',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _businessName,
                        decoration: const InputDecoration(
                          labelText: 'Business name',
                          prefixIcon: Icon(Icons.storefront),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: _saving ? null : _saveBusiness,
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Save business'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _saving
                                ? null
                                : () async {
                                    await context.appState.signOut();
                                  },
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveBusiness() async {
    final name = _businessName.text.trim();
    if (name.isEmpty) {
      showAppSnackBar(context, 'Business name is required.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await context.appState.updateBusinessName(name);
      if (mounted) showAppSnackBar(context, 'Business updated.');
    } catch (error) {
      if (mounted) showAppSnackBar(context, error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
