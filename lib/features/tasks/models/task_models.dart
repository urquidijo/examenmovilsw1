class DepartmentTaskBoard {
  final String departmentId;
  final String departmentName;
  final int activeTasksCount;
  final int completedTasksCount;
  final bool assignedToMe;

  DepartmentTaskBoard({
    required this.departmentId,
    required this.departmentName,
    required this.activeTasksCount,
    required this.completedTasksCount,
    required this.assignedToMe,
  });

  factory DepartmentTaskBoard.fromJson(Map<String, dynamic> json) {
    return DepartmentTaskBoard(
      departmentId: json['departmentId'] ?? '',
      departmentName: json['departmentName'] ?? 'Departamento',
      activeTasksCount: json['activeTasksCount'] ?? 0,
      completedTasksCount: json['completedTasksCount'] ?? 0,
      assignedToMe: json['assignedToMe'] ?? false,
    );
  }
}

class WorkflowTask {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String? nodeName;
  final String? departmentName;
  final String? createdAt;
  final String? updatedAt;

  WorkflowTask({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.nodeName,
    this.departmentName,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkflowTask.fromJson(Map<String, dynamic> json) {
    return WorkflowTask(
      id: json['id'] ?? '',
      title: json['title'] ?? json['name'] ?? json['nodeName'] ?? 'Tarea',
      description: json['description'],
      status: json['status'] ?? 'PENDING',
      nodeName: json['nodeName'],
      departmentName: json['departmentName'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}