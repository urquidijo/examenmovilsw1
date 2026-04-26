class ProjectSummary {
  final String id;
  final String name;
  final String? description;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  ProjectSummary({
    required this.id,
    required this.name,
    this.description,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

 factory ProjectSummary.fromJson(Map<String, dynamic> json) {
  return ProjectSummary(
    id: json['id'] ?? json['projectId'] ?? json['_id'] ?? '',
    name: json['name'] ?? json['projectName'] ?? 'Proyecto sin nombre',
    description: json['description'],
    status: json['status'],
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
  );
}
}