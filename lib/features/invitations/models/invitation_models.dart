class ProjectInvitation {
  final String id;
  final String projectId;
  final String projectName;
  final String? email;
  final String? role;
  final String? status;
  final String? createdAt;

  ProjectInvitation({
    required this.id,
    required this.projectId,
    required this.projectName,
    this.email,
    this.role,
    this.status,
    this.createdAt,
  });

  factory ProjectInvitation.fromJson(Map<String, dynamic> json) {
    return ProjectInvitation(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? json['project']?['id'] ?? '',
      projectName: json['projectName'] ?? json['project']?['name'] ?? 'Proyecto',
      email: json['email'],
      role: json['role'],
      status: json['status'],
      createdAt: json['createdAt'],
    );
  }
}