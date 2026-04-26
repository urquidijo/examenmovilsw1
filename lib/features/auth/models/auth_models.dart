class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
      };
}

class AuthResponse {
  final String token;
  final String id;
  final String name;
  final String email;
  final String? role;

  AuthResponse({
    required this.token,
    required this.id,
    required this.name,
    required this.email,
    this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
    );
  }

  Map<String, dynamic> userToJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };
}