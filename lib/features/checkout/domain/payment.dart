enum PaymentMethod {
  cash('Cash'),
  card('Card'),
  digital('Digital / bank');

  const PaymentMethod(this.label);

  final String label;
}
