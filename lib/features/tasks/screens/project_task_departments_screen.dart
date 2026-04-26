import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/task_models.dart';
import '../services/task_service.dart';

class ProjectTaskDepartmentsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectTaskDepartmentsScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectTaskDepartmentsScreen> createState() =>
      _ProjectTaskDepartmentsScreenState();
}

class _ProjectTaskDepartmentsScreenState
    extends State<ProjectTaskDepartmentsScreen> {
  final taskService = TaskService();

  bool loading = true;
  String errorMessage = '';
  List<DepartmentTaskBoard> departments = [];

  @override
  void initState() {
    super.initState();
    loadDepartments();
  }

  Future<void> loadDepartments() async {
    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      departments = await taskService.getTaskBoardDepartments(widget.projectId);
    } catch (_) {
      errorMessage = 'No se pudieron cargar los departamentos';
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void openDepartmentTasks(DepartmentTaskBoard department) {
    context.push(
      '/projects/${widget.projectId}/tasks/departments/${department.departmentId}',
      extra: department.departmentName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.projectName)),
      body: RefreshIndicator(
        onRefresh: loadDepartments,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(errorMessage),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: loadDepartments,
                    child: const Text('Reintentar'),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Departamentos asignados',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (departments.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No tienes departamentos asignados'),
                      ),
                    )
                  else
                    ...departments.map(_buildDepartmentCard),
                ],
              ),
      ),
    );
  }

  Widget _buildDepartmentCard(DepartmentTaskBoard department) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.business_outlined)),
        title: Text(
          department.departmentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Activas: ${department.activeTasksCount} · Completadas: ${department.completedTasksCount}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openDepartmentTasks(department),
      ),
    );
  }
}
