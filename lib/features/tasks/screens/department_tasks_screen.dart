import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/task_models.dart';
import '../services/task_service.dart';

class DepartmentTasksScreen extends StatefulWidget {
  final String projectId;
  final String departmentId;
  final String departmentName;

  const DepartmentTasksScreen({
    super.key,
    required this.projectId,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  State<DepartmentTasksScreen> createState() => _DepartmentTasksScreenState();
}

class _DepartmentTasksScreenState extends State<DepartmentTasksScreen> {
  final taskService = TaskService();

  bool loading = true;
  String errorMessage = '';
  List<WorkflowTask> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      tasks = await taskService.getMyDepartmentTasks(
        widget.projectId,
        widget.departmentId,
      );
    } catch (_) {
      errorMessage = 'No se pudieron cargar las tareas del departamento';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String getTaskStatusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Pendiente';
      case 'IN_PROGRESS':
        return 'En proceso';
      case 'DONE':
        return 'Hecho';
      default:
        return status;
    }
  }

  IconData getTaskStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.schedule_rounded;
      case 'IN_PROGRESS':
        return Icons.sync_rounded;
      case 'DONE':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.task_outlined;
    }
  }

  void openTask(WorkflowTask task) {
    context.push(
      '/projects/${widget.projectId}/tasks/${task.id}',
      extra: task.nodeLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          widget.departmentName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadTasks,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _emptyBox(
                        icon: Icons.error_outline_rounded,
                        title: 'No se pudo cargar',
                        text: errorMessage,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: loadTasks,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF0369A1)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.task_alt_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.departmentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${tasks.length} tarea(s) asignada(s)',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Mis tareas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (tasks.isEmpty)
                        _emptyBox(
                          icon: Icons.inbox_outlined,
                          title: 'Sin tareas',
                          text: 'No tienes tareas asignadas en este departamento.',
                        )
                      else
                        ...tasks.map(_buildTaskCard),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTaskCard(WorkflowTask task) {
    final ticket = task.ticket;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => openTask(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      getTaskStatusIcon(task.status),
                      color: const Color(0xFF0369A1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.nodeLabel,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(getTaskStatusLabel(task.status))),
                  if (task.requiresTramite)
                    const Chip(label: Text('Requiere trámite')),
                ],
              ),
              if (ticket != null) ...[
                const SizedBox(height: 12),
                Text(
                  ticket.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (ticket.description != null &&
                    ticket.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ticket.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 10),
                if (ticket.clientName != null)
                  _miniInfo(Icons.person_outline, ticket.clientName!),
                if (ticket.clientPhone != null)
                  _miniInfo(Icons.phone_outlined, ticket.clientPhone!),
                if (ticket.clientEmail != null)
                  _miniInfo(Icons.email_outlined, ticket.clientEmail!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF64748B)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}