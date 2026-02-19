import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../logic/wallet/wallet_bloc.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../models/transaction_model.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _showFundDialog(BuildContext context, String email) {
    final TextEditingController amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fund Wallet'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter amount (₦)',
            prefixText: '₦ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final walletBloc = context.read<WalletBloc>();
                Navigator.pop(dialogContext);
                walletBloc.add(InitiateDeposit(
                  context: context, // Use outer stable context
                  amount: amount,
                  email: email,
                ));
              }
            },
            child: const Text('Fund Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        elevation: 0,
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          } else if (state is PaymentFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.orange),
            );
          }
        },
        builder: (context, state) {
          if (state is WalletLoading || state is WalletInitial) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF004D40)),
                  SizedBox(height: 16),
                  Text('Fetching wallet details...'),
                ],
              ),
            );
          }

          if (state is WalletError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.read<WalletBloc>().add(LoadWallet()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is WalletLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<WalletBloc>().add(LoadWallet());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildBalanceCard(context, state.balance),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          'Recent Transactions',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  state.transactions.isEmpty
                      ? const SizedBox(
                          height: 200,
                          child: Center(child: Text('No transactions yet')),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: state.transactions.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            return _buildTransactionItem(
                                state.transactions[index]);
                          },
                        ),
                ],
              ),
            );
          }

          return const Center(child: Text('Connecting to wallet...'));
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    final authState = context.read<AuthBloc>().state;
    final String email = authState is AuthAuthenticated ? authState.user.email : '';
    final String role = authState is AuthAuthenticated ? authState.user.role : 'student';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '₦ ${NumberFormat('#,###.00').format(balance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (role == 'student')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showFundDialog(context, email),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Fund Wallet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF004D40),
                    ),
                  ),
                ),
              if (role == 'rider')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Logic for withdrawal
                    },
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Withdraw'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF004D40),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    final isCredit = tx.type == 'credit';
    final DateFormat formatter = DateFormat('MMM dd, yyyy • HH:mm');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isCredit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: isCredit ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        tx.description,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        formatter.format(tx.timestamp),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '${isCredit ? "+" : "-"} ₦${NumberFormat('#,###.00').format(tx.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isCredit ? Colors.green : Colors.red,
          fontSize: 16,
        ),
      ),
    );
  }
}
