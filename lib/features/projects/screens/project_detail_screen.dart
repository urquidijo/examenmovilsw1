import 'package:flutter/material.dart';

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
              leading: const Icon(Icons.task_alt),
              title: const Text('Tareas del proyecto'),
              subtitle: const Text('Aquí mostraremos departamentos y tareas asignadas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}