import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../providers/wallet_provider.dart';

class ManageWalletsScreen extends ConsumerStatefulWidget {
  const ManageWalletsScreen({super.key});

  @override
  ConsumerState<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends ConsumerState<ManageWalletsScreen> {
  void _showWalletForm([Map<String, dynamic>? wallet]) {
    final isEditing = wallet != null;
    final nameController = TextEditingController(text: wallet?['name'] ?? '');
    final typeController = TextEditingController(text: wallet?['type'] ?? 'cash');
    final currencyController = TextEditingController(text: wallet?['currency'] ?? 'IDR');
    final balanceController = TextEditingController(text: wallet?['balance']?.toString() ?? '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Wallet' : 'Add Wallet',
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Wallet Name',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: typeController.text,
                dropdownColor: const Color(0xFF2E2E45),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Wallet Type',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                  DropdownMenuItem(value: 'e_wallet', child: Text('E-Wallet')),
                  DropdownMenuItem(value: 'crypto', child: Text('Crypto')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) typeController.text = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: currencyController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Currency (e.g. IDR, USD)',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (isEditing) ...[
                    Expanded(
                      child: AppButton(
                        label: 'Delete',
                        type: AppButtonType.outline,
                        onPressed: () async {
                          final err = await ref.read(walletsProvider.notifier).deleteWallet(wallet['id']);
                          if (mounted) {
                            if (err != null) {
                              AppSnackbar.show(context, title: 'Error', message: err, type: SnackbarType.error);
                            } else {
                              context.pop();
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'Save',
                      onPressed: () async {
                        final data = {
                          'name': nameController.text,
                          'type': typeController.text,
                          'currency': currencyController.text,
                          'balance': double.tryParse(balanceController.text) ?? 0,
                        };
                        String? err;
                        if (isEditing) {
                          err = await ref.read(walletsProvider.notifier).updateWallet(wallet['id'], data);
                        } else {
                          err = await ref.read(walletsProvider.notifier).createWallet(data);
                        }
                        
                        if (mounted) {
                          if (err != null) {
                            AppSnackbar.show(context, title: 'Error', message: err, type: SnackbarType.error);
                          } else {
                            context.pop();
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletsState = ref.watch(walletsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Manage Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showWalletForm(),
          )
        ],
      ),
      body: walletsState.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return const Center(child: Text('No wallets found.', style: TextStyle(color: Colors.white54)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return Card(
                color: const Color(0xFF1C1C2E),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(wallet['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('${wallet['type']} • ${wallet['currency']}', style: const TextStyle(color: Colors.white54)),
                  trailing: Text(
                    '${wallet['currency']} ${wallet['balance']}',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _showWalletForm(wallet),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
