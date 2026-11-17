// The first launch: everything stays on this device, and the first step is one account.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../accounts/accounts_screen.dart';
import '../data/import_screen.dart';

class FirstAccountScreen extends StatelessWidget {
  const FirstAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset(
                    'assets/brand/app-icon.svg',
                    width: 64,
                    height: 64,
                    semanticsLabel: 'Ledgerly',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Welcome to Ledgerly', style: context.text.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Your money, on this device. Recording takes seconds, and every number can be traced to its entries. Nothing needs a connection.',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: 24),
                Text('Your first account', style: context.text.title),
                const SizedBox(height: 4),
                Text(
                  'Add the account you use most. You can add the others later, under More.',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: 16),
                AccountForm(onCreated: (_) {}),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen())),
                    icon: const LedgerIcon('inbox', size: 16),
                    label: const Text('Or import a Ledgerly file'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
