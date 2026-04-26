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
      if (mounted) setState(() => loading = false);
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
    final totalActive = departments.fold<int>(
      0,
      (sum, item) => sum + item.activeTasksCount,
    );

    final totalCompleted = departments.fold<int>(
      0,
      (sum, item) => sum + item.completedTasksCount,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          widget.projectName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadDepartments,
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
                        onPressed: loadDepartments,
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
                              Icons.apartment_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Departamentos asignados',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${departments.length} departamento(s) · $totalActive activas · $totalCompleted completadas',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Departamentos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (departments.isEmpty)
                        _emptyBox(
                          icon: Icons.business_outlined,
                          title: 'Sin departamentos',
                          text: 'No tienes departamentos asignados en este proyecto.',
                        )
                      else
                        ...departments.map(_buildDepartmentCard),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDepartmentCard(DepartmentTaskBoard department) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.business_outlined,
            color: Color(0xFF0369A1),
          ),
        ),
        title: Text(
          department.departmentName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Activas: ${department.activeTasksCount}')),
              Chip(
                label: Text('Completadas: ${department.completedTasksCount}'),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => openDepartmentTasks(department),
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