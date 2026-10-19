import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registerMode = false;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    if (state.isLoggedIn) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Logged in as: ${state.userEmail}'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => state.loadOrders(),
            child: const Text('Load My Orders'),
          ),
          const SizedBox(height: 8),
          ...state.orders.map(
            (order) => Card(
              child: ListTile(
                title: Text('Order #${order.id} - ${order.status}'),
                subtitle: Text(
                  '${order.currency} ${order.total} • ${order.createdAt.toLocal()}',
                ),
              ),
            ),
          ),
          if (state.orders.isEmpty) const Text('No orders found yet.'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => state.logout(),
            child: const Text('Logout'),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          value: _registerMode,
          onChanged: (value) => setState(() => _registerMode = value),
          title: Text(_registerMode ? 'Register mode' : 'Login mode'),
        ),
        TextField(
          controller: _username,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        if (_registerMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: state.isLoading
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    if (_registerMode) {
                      await state.register(
                        _username.text.trim(),
                        _email.text.trim(),
                        _password.text.trim(),
                      );
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Registration successful.')),
                      );
                    } else {
                      await state.login(
                        _username.text.trim(),
                        _password.text.trim(),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
          child: Text(_registerMode ? 'Register' : 'Login'),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
