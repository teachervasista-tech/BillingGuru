import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../cart/presentation/view_models/cart_view_model.dart';
import '../../sales/data/models/sale_summary.dart';
import '../../sales/presentation/view_models/sales_view_model.dart';
import '../data/customer_local_service.dart';
import '../domain/customer.dart';

final customerServiceProvider = Provider<CustomerLocalService>((ref) {
  return CustomerLocalService(database: ref.watch(appDatabaseProvider));
});

final customerSearchProvider = NotifierProvider<CustomerSearch, String>(
  CustomerSearch.new,
);

class CustomerSearch extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final customersProvider = FutureProvider<List<Customer>>((ref) {
  return ref
      .watch(customerServiceProvider)
      .getCustomers(search: ref.watch(customerSearchProvider));
});

final customerStatsProvider = FutureProvider.family<CustomerStats, String>((
  ref,
  customerId,
) {
  return ref.watch(customerServiceProvider).getStats(customerId);
});

final customerSalesProvider = FutureProvider.family<List<SaleSummary>, String>((
  ref,
  customerId,
) {
  return ref.watch(salesRepositoryProvider).getSales(customerId: customerId);
});

/// Customer attached to the sale being rung up; cleared with the cart.
final selectedCustomerProvider = NotifierProvider<SelectedCustomer, Customer?>(
  SelectedCustomer.new,
);

class SelectedCustomer extends Notifier<Customer?> {
  @override
  Customer? build() {
    ref.listen(cartProvider, (_, cart) {
      if (cart.isEmpty) state = null;
    });
    return null;
  }

  void select(Customer? customer) => state = customer;
}

/// Customer CRUD that keeps dependent providers fresh.
final customerActionsProvider = Provider<CustomerActions>(CustomerActions.new);

class CustomerActions {
  CustomerActions(this.ref);

  final Ref ref;

  CustomerLocalService get _service => ref.read(customerServiceProvider);

  Future<Customer> save(Customer customer) async {
    await _service.saveCustomer(customer);
    ref.invalidate(customersProvider);
    if (ref.read(selectedCustomerProvider)?.id == customer.id) {
      ref.read(selectedCustomerProvider.notifier).select(customer);
    }
    return customer;
  }

  Future<void> delete(String id) async {
    await _service.deleteCustomer(id);
    ref.invalidate(customersProvider);
    ref.invalidate(salesViewModelProvider);
    if (ref.read(selectedCustomerProvider)?.id == id) {
      ref.read(selectedCustomerProvider.notifier).select(null);
    }
  }

  String newId() => _service.newId();
}
