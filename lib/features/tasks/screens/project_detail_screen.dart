import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;
  final String projectName;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          projectName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
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
                  Icons.business_center_rounded,
                  color: Colors.white,
                  size: 38,
                ),
                const SizedBox(height: 14),
                Text(
                  projectName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gestiona los departamentos y tareas asignadas a este proyecto.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
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
                  Icons.task_alt_rounded,
                  color: Color(0xFF0369A1),
                ),
              ),
              title: const Text(
                'Tareas del proyecto',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Ver departamentos asignados y tareas pendientes'),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                context.push('/projects/$projectId/tasks', extra: projectName);
              },
            ),
          ),
        ],
      ),
    );
  }
}