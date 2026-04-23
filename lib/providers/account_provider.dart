import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bank_account.dart';
import '../services/database_service.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService());

final accountStreamProvider = StreamProvider<List<BankAccount>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getAccounts();
});

class AccountNotifier extends StateNotifier<List<BankAccount>> {
  final Ref ref;
  AccountNotifier(this.ref) : super([]);

  // This can be used for optimistic UI updates or manual management
  void setAccounts(List<BankAccount> accounts) => state = accounts;

  Future<void> addAccount(BankAccount account) async {
    await ref.read(databaseServiceProvider).addAccount(account);
  }

  double get totalBalance => state.fold(0, (sum, item) => sum + item.balance);
}

final accountProvider = StateNotifierProvider<AccountNotifier, List<BankAccount>>((ref) {
  final notifier = AccountNotifier(ref);
  // Optional: Sync state with stream
  ref.listen(accountStreamProvider, (prev, next) {
    next.whenData((accounts) => notifier.setAccounts(accounts));
  });
  return notifier;
});
