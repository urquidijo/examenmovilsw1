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

class DecisionOption {
  final String label;
  final String value;

  DecisionOption({
    required this.label,
    required this.value,
  });

  factory DecisionOption.fromJson(Map<String, dynamic> json) {
    return DecisionOption(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

class TaskTicketInfo {
  final String id;
  final String title;
  final String? description;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? clientReference;
  final String status;
  final Map<String, dynamic>? metadata;

  TaskTicketInfo({
    required this.id,
    required this.title,
    this.description,
    this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.clientReference,
    required this.status,
    this.metadata,
  });

  factory TaskTicketInfo.fromJson(Map<String, dynamic> json) {
    return TaskTicketInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Ticket',
      description: json['description'],
      clientName: json['clientName'],
      clientPhone: json['clientPhone'],
      clientEmail: json['clientEmail'],
      clientReference: json['clientReference'],
      status: json['status'] ?? '',
      metadata: json['metadata'],
    );
  }
}

class WorkflowTask {
  final String id;
  final String projectId;
  final String ticketId;
  final String workflowId;
  final String nodeId;
  final String nodeLabel;
  final String nodeType;

  final String? departmentId;
  final String? departmentName;

  final String? assignedUserId;
  final String? assignedUserName;

  final bool requiresTramite;
  final String? tramiteTemplateId;
  final String? tramiteTemplateName;

  final String? decisionMode;
  final String? decisionQuestion;
  final List<DecisionOption> decisionOptions;

  final String status;
  final Map<String, dynamic>? submittedTramiteData;

  final TaskTicketInfo? ticket;

  final String createdAt;
  final String? startedAt;
  final String? completedAt;

  WorkflowTask({
    required this.id,
    required this.projectId,
    required this.ticketId,
    required this.workflowId,
    required this.nodeId,
    required this.nodeLabel,
    required this.nodeType,
    this.departmentId,
    this.departmentName,
    this.assignedUserId,
    this.assignedUserName,
    required this.requiresTramite,
    this.tramiteTemplateId,
    this.tramiteTemplateName,
    this.decisionMode,
    this.decisionQuestion,
    required this.decisionOptions,
    required this.status,
    this.submittedTramiteData,
    this.ticket,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory WorkflowTask.fromJson(Map<String, dynamic> json) {
    return WorkflowTask(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      ticketId: json['ticketId'] ?? '',
      workflowId: json['workflowId'] ?? '',
      nodeId: json['nodeId'] ?? '',
      nodeLabel: json['nodeLabel'] ?? 'Tarea',
      nodeType: json['nodeType'] ?? '',
      departmentId: json['departmentId'],
      departmentName: json['departmentName'],
      assignedUserId: json['assignedUserId'],
      assignedUserName: json['assignedUserName'],
      requiresTramite: json['requiresTramite'] ?? false,
      tramiteTemplateId: json['tramiteTemplateId'],
      tramiteTemplateName: json['tramiteTemplateName'],
      decisionMode: json['decisionMode'],
      decisionQuestion: json['decisionQuestion'],
      decisionOptions: ((json['decisionOptions'] ?? []) as List)
          .map((item) => DecisionOption.fromJson(item))
          .toList(),
      status: json['status'] ?? 'PENDING',
      submittedTramiteData: json['submittedTramiteData'],
      ticket: json['ticket'] != null
          ? TaskTicketInfo.fromJson(json['ticket'])
          : null,
      createdAt: json['createdAt'] ?? '',
      startedAt: json['startedAt'],
      completedAt: json['completedAt'],
    );
  }
}