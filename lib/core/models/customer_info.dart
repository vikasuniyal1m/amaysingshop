class CustomerInfo {
  CustomerInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address1,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address1;
  final String city;
  final String state;
  final String postcode;
  final String country;

  Map<String, dynamic> toWooAddressJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'address_1': address1,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'email': email,
      'phone': phone,
    };
  }
}
