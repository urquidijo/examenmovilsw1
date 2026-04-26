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
      if (mounted) {
        setState(() => loading = false);
      }
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
        return Icons.schedule;
      case 'IN_PROGRESS':
        return Icons.sync;
      case 'DONE':
        return Icons.check_circle_outline;
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
      appBar: AppBar(title: Text(widget.departmentName)),
      body: RefreshIndicator(
        onRefresh: loadTasks,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(errorMessage),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: loadTasks,
                    child: const Text('Reintentar'),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Mis tareas',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (tasks.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No tienes tareas asignadas'),
                      ),
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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: InkWell(
          onTap: () => openTask(task),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.nodeLabel,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text('Estado: ${getTaskStatusLabel(task.status)}'),

              if (ticket != null) ...[
                const SizedBox(height: 10),
                Text(
                  ticket.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (ticket.description != null &&
                    ticket.description!.isNotEmpty)
                  Text(ticket.description!),
                if (ticket.clientName != null)
                  Text('Cliente: ${ticket.clientName}'),
                if (ticket.clientPhone != null)
                  Text('Teléfono: ${ticket.clientPhone}'),
                if (ticket.clientEmail != null)
                  Text('Correo: ${ticket.clientEmail}'),
              ],

              const SizedBox(height: 10),

              Row(
                children: [
                  if (task.requiresTramite)
                    const Chip(label: Text('Requiere trámite')),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
