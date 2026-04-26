import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../projects/models/project_models.dart';
import '../../projects/services/project_service.dart';
import '../../invitations/models/invitation_models.dart';
import '../../invitations/services/invitation_service.dart';
import '../../auth/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final projectService = ProjectService();
  final invitationService = InvitationService();
  final authService = AuthService();

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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'NexaFlow',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await authService.logout();

              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadHome,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _emptyBox(
                    icon: Icons.error_outline,
                    title: 'No se pudo cargar',
                    text: errorMessage,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: loadHome,
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
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.account_tree_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Mis proyectos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Consulta tus proyectos, invitaciones y tareas asignadas.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (invitations.isNotEmpty) ...[
                    _sectionTitle('Invitaciones pendientes'),
                    const SizedBox(height: 12),
                    ...invitations.map(_buildInvitationCard),
                    const SizedBox(height: 24),
                  ],

                  _sectionTitle('Proyectos'),
                  const SizedBox(height: 12),

                  if (projects.isEmpty)
                    _emptyBox(
                      icon: Icons.folder_open,
                      title: 'Sin proyectos',
                      text: 'Aún no tienes proyectos asignados.',
                    )
                  else
                    ...projects.map(_buildProjectCard),
                ],
              ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
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

  Widget _buildProjectCard(ProjectSummary project) {
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
          vertical: 10,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.business_center_outlined,
            color: Color(0xFF0369A1),
          ),
        ),
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(project.description ?? 'Sin descripción'),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFF0284C7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  invitation.projectName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Rol: ${invitation.role ?? 'Miembro'}'),
          const SizedBox(height: 14),
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
    );
  }
}
