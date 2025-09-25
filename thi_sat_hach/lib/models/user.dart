class User {
  int? id;
  String username;
  String password;
  String? fullname;
  String? email;
  String? avatar;
  String? address;
  String? phone;

  User({
    this.id,
    required this.username,
    required this.password,
    this.fullname,
    this.email,
    this.phone,
    this.address,
    this.avatar,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullname': fullname,
      'email': email,
      'avatar': avatar,
      'phone': phone,
      'address': address,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      fullname: map['fullname'],
      email: map['email'],
      avatar: map['avatar'],
      address: map['address'],
      phone: map['phone'],
    );
  }
}
