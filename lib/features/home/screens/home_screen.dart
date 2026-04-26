import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../projects/models/project_models.dart';
import '../../projects/services/project_service.dart';
import '../../invitations/models/invitation_models.dart';
import '../../invitations/services/invitation_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final projectService = ProjectService();
  final invitationService = InvitationService();

  bool loading = true;
  String errorMessage = '';

  List<ProjectSummary> projects = [];
  List<ProjectInvitation> invitations = [];

  @override
  void initState() {
    super.initState();
    loadHome();
  }

  Future<void> loadHome() async {
    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      final results = await Future.wait([
        projectService.getMyProjects(),
        invitationService.getMyPendingInvitations(),
      ]);

      projects = results[0] as List<ProjectSummary>;
      invitations = results[1] as List<ProjectInvitation>;
    } catch (_) {
      errorMessage = 'No se pudo cargar la información';
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> acceptInvitation(String id) async {
    await invitationService.acceptInvitation(id);
    await loadHome();
  }

  Future<void> rejectInvitation(String id) async {
    await invitationService.rejectInvitation(id);
    await loadHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis proyectos'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: loadHome,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(errorMessage),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: loadHome,
                    child: const Text('Reintentar'),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (invitations.isNotEmpty) ...[
                    const Text(
                      'Invitaciones pendientes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...invitations.map(_buildInvitationCard),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Proyectos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (projects.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Aún no tienes proyectos asignados'),
                      ),
                    )
                  else
                    ...projects.map(_buildProjectCard),
                ],
              ),
      ),
    );
  }

  Widget _buildProjectCard(ProjectSummary project) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.account_tree_outlined)),
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(project.description ?? 'Sin descripción'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (project.id.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Este proyecto no tiene ID válido')),
            );
            return;
          }

          context.push('/projects/${project.id}/tasks', extra: project.name);
        },
      ),
    );
  }

  Widget _buildInvitationCard(ProjectInvitation invitation) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invitation.projectName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Rol: ${invitation.role ?? 'Miembro'}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => rejectInvitation(invitation.id),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => acceptInvitation(invitation.id),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
