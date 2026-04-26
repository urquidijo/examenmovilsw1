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
      appBar: AppBar(
        title: Text(projectName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.task_alt),
              ),
              title: const Text(
                'Tareas del proyecto',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Ver departamentos asignados y tareas pendientes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push(
                  '/projects/$projectId/tasks',
                  extra: projectName,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}