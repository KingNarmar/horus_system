abstract class CustomerDbFields {
  static const tableName = 'customers';

  static const name = 'name';
  static const contactPerson = 'contact_person';
  static const phone = 'phone';
  static const email = 'email';
  static const taxRegistrationNumber = 'tax_registration_number';
  static const address = 'address';
  static const city = 'city';
  static const country = 'country';
  static const creditLimit = 'credit_limit';

  static const allColumns =
      'id, company_id, name, contact_person, phone, email, tax_registration_number, address, city, country, credit_limit, is_active, created_at, updated_at';
}
