import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/task_models.dart';
import '../models/tramite_models.dart';
import '../services/task_service.dart';
import '../services/tramite_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String projectId;
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final taskService = TaskService();
  final tramiteService = TramiteService();

  bool loading = true;
  bool loadingTramite = false;
  bool completing = false;

  String errorMessage = '';
  WorkflowTask? task;
  TramiteTemplate? tramiteTemplate;

  String? selectedDecisionResult;

  final Map<String, dynamic> tramiteData = {};
  final Map<String, PlatformFile> selectedFiles = {};

  @override
  void initState() {
    super.initState();
    loadTask();
  }

  Future<void> loadTask() async {
    setState(() {
      loading = true;
      errorMessage = '';
      tramiteTemplate = null;
      tramiteData.clear();
      selectedFiles.clear();
      selectedDecisionResult = null;
    });

    try {
      task = await taskService.getTaskDetail(widget.projectId, widget.taskId);

      final currentTask = task;

      if (currentTask != null &&
          currentTask.requiresTramite &&
          currentTask.tramiteTemplateId != null &&
          currentTask.tramiteTemplateId!.isNotEmpty) {
        await loadTramiteTemplate(currentTask.tramiteTemplateId!);
      }
    } catch (_) {
      errorMessage = 'No se pudo cargar la tarea';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadTramiteTemplate(String tramiteId) async {
    setState(() => loadingTramite = true);

    try {
      tramiteTemplate = await tramiteService.getTramiteById(
        widget.projectId,
        tramiteId,
      );
    } catch (_) {
      errorMessage = 'No se pudo cargar el formulario del trámite';
    } finally {
      if (mounted) setState(() => loadingTramite = false);
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

  bool get isDecisionTask {
    final currentTask = task;
    if (currentTask == null) return false;
    return currentTask.decisionQuestion != null &&
        currentTask.decisionQuestion!.isNotEmpty;
  }

  bool validateBeforeComplete() {
    final currentTask = task;
    if (currentTask == null) return false;

    if (isDecisionTask &&
        (selectedDecisionResult == null || selectedDecisionResult!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una decisión')),
      );
      return false;
    }

    if (currentTask.requiresTramite && tramiteTemplate != null) {
      for (final field in tramiteTemplate!.fields) {
        if (!field.required) continue;

        final value = tramiteData[field.id];
        final hasFile = selectedFiles.containsKey(field.id);

        if ((value == null || value.toString().trim().isEmpty) && !hasFile) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Completa el campo: ${field.label}')),
          );
          return false;
        }
      }
    }

    return true;
  }

  Future<void> completeTask() async {
    if (!validateBeforeComplete()) return;

    setState(() => completing = true);

    try {
      final files = <MultipartFile>[];

      for (final entry in selectedFiles.entries) {
        final file = entry.value;

        if (file.path != null) {
          files.add(
            await MultipartFile.fromFile(file.path!, filename: file.name),
          );

          tramiteData[entry.key] = file.name;
        }
      }

      await taskService.completeTask(
        widget.projectId,
        widget.taskId,
        tramiteData: tramiteData,
        decisionResult: selectedDecisionResult,
        files: files,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea completada correctamente')),
      );

      context.pop();
    } on DioException catch (error) {
      final data = error.response?.data;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data?['message']?.toString() ??
                data?['error']?.toString() ??
                'No se pudo completar la tarea',
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar la tarea')),
      );
    } finally {
      if (mounted) setState(() => completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTask = task;
    final ticket = currentTask?.ticket;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Detalle de tarea',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty && currentTask == null
              ? Center(child: Text(errorMessage))
              : currentTask == null
                  ? const Center(child: Text('Tarea no encontrada'))
                  : RefreshIndicator(
                      onRefresh: loadTask,
                      child: ListView(
                        padding: const EdgeInsets.all(18),
                        children: [
                          _buildTaskHeader(currentTask),
                          const SizedBox(height: 16),
                          if (ticket != null) _buildTicketCard(ticket),
                          if (ticket?.metadata != null &&
                              ticket!.metadata!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildMetadataCard(ticket.metadata!),
                          ],
                          if (isDecisionTask) ...[
                            const SizedBox(height: 16),
                            _buildDecisionCard(currentTask),
                          ],
                          if (currentTask.requiresTramite) ...[
                            const SizedBox(height: 16),
                            buildDynamicForm(),
                          ],
                          if (errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: completing || loadingTramite
                                  ? null
                                  : completeTask,
                              icon: completing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                completing
                                    ? 'Completando...'
                                    : 'Completar tarea',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildTaskHeader(WorkflowTask task) {
    return Container(
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
          const Icon(Icons.task_alt_rounded, color: Colors.white, size: 38),
          const SizedBox(height: 14),
          const Text(
            'Tarea asignada',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            task.nodeLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Revisa la información del ticket asociado y completa la acción requerida para continuar el flujo.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _softChip(getTaskStatusLabel(task.status)),
              _softChip(task.departmentName ?? 'Sin departamento'),
              if (task.requiresTramite) _softChip('Requiere trámite'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TaskTicketInfo ticket) {
    return _sectionCard(
      title: 'Detalles del ticket',
      icon: Icons.confirmation_number_outlined,
      children: [
        _InfoItem('Título', ticket.title),
        _InfoItem('Estado', ticket.status),
        _InfoItem('Descripción', ticket.description ?? 'Sin descripción'),
        _InfoItem('Cliente', ticket.clientName ?? 'No especificado'),
        _InfoItem('Teléfono', ticket.clientPhone ?? 'No especificado'),
        _InfoItem('Correo', ticket.clientEmail ?? 'No especificado'),
        _InfoItem('Referencia', ticket.clientReference ?? 'No especificada'),
      ],
    );
  }

  Widget _buildMetadataCard(Map<String, dynamic> metadata) {
    return _sectionCard(
      title: 'Metadata adicional',
      icon: Icons.data_object_rounded,
      children: metadata.entries
          .map((entry) => _InfoItem(entry.key, entry.value.toString()))
          .toList(),
    );
  }

  Widget _buildDecisionCard(WorkflowTask task) {
    final options = task.decisionOptions;

    return _sectionCard(
      title: 'Decisión',
      icon: Icons.alt_route_rounded,
      children: [
        if (task.decisionQuestion != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(task.decisionQuestion!),
          ),
        if (options.isNotEmpty)
          ...options.map(
            (option) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: selectedDecisionResult == option.value
                    ? const Color(0xFFE0F2FE)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedDecisionResult == option.value
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: RadioListTile<String>(
                value: option.value,
                groupValue: selectedDecisionResult,
                title: Text(
                  option.label.isNotEmpty ? option.label : option.value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('Valor: ${option.value}'),
                onChanged: (value) {
                  setState(() => selectedDecisionResult = value);
                },
              ),
            ),
          )
        else
          TextField(
            onChanged: (value) {
              selectedDecisionResult = value;
            },
            decoration: _inputDecoration('Resultado de decisión'),
          ),
      ],
    );
  }

  Widget buildDynamicForm() {
    if (loadingTramite) {
      return _sectionCard(
        title: 'Formulario del trámite',
        icon: Icons.dynamic_form_rounded,
        children: const [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text('Cargando formulario del trámite...'),
          ),
        ],
      );
    }

    final template = tramiteTemplate;

    if (template == null) {
      return _sectionCard(
        title: 'Formulario del trámite',
        icon: Icons.dynamic_form_rounded,
        children: const [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text('No se encontró el formulario del trámite'),
          ),
        ],
      );
    }

    return _sectionCard(
      title: 'Formulario del trámite',
      icon: Icons.dynamic_form_rounded,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (template.description != null &&
                  template.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(template.description!),
              ],
            ],
          ),
        ),
        ...template.fields.map(buildField),
      ],
    );
  }

  Widget buildField(TramiteField field) {
    switch (field.type) {
      case 'TEXT':
        return _textField(field);
      case 'TEXTAREA':
        return _textField(field, maxLines: 4);
      case 'NUMBER':
        return _textField(field, keyboardType: TextInputType.number);
      case 'DATE':
        return _dateField(field);
      case 'SELECT':
        return _selectField(field);
      case 'CHECKBOX':
        return _checkboxField(field);
      case 'FILE':
        return _fileField(field);
      default:
        return _textField(field);
    }
  }

  Widget _textField(
    TramiteField field, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _inputDecoration(
          field.required ? '${field.label} *' : field.label,
          hint: field.placeholder,
        ),
        onChanged: (value) {
          tramiteData[field.id] = value;
        },
      ),
    );
  }

  Widget _dateField(TramiteField field) {
    final value = tramiteData[field.id]?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            initialDate: DateTime.now(),
          );

          if (date != null) {
            setState(() {
              tramiteData[field.id] =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            });
          }
        },
        icon: const Icon(Icons.calendar_month),
        label: Text(
          value == null || value.isEmpty
              ? '${field.label}${field.required ? ' *' : ''}'
              : '${field.label}: $value',
        ),
      ),
    );
  }

  Widget _selectField(TramiteField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        decoration: _inputDecoration(
          field.required ? '${field.label} *' : field.label,
        ),
        items: field.options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (value) {
          tramiteData[field.id] = value;
        },
      ),
    );
  }

  Widget _checkboxField(TramiteField field) {
    final value = tramiteData[field.id] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CheckboxListTile(
        value: value,
        title: Text(field.required ? '${field.label} *' : field.label),
        subtitle: field.placeholder != null ? Text(field.placeholder!) : null,
        onChanged: (newValue) {
          setState(() {
            tramiteData[field.id] = newValue ?? false;
          });
        },
      ),
    );
  }

  Widget _fileField(TramiteField field) {
    final file = selectedFiles[field.id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.required ? '${field.label} *' : field.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await FilePicker.pickFiles(
                  allowMultiple: false,
                  type: FileType.any,
                );

                if (result != null && result.files.isNotEmpty) {
                  setState(() {
                    selectedFiles[field.id] = result.files.first;
                  });
                }
              },
              icon: const Icon(Icons.attach_file),
              label: Text(file == null ? 'Seleccionar archivo' : file.name),
            ),
            if (file != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${(file.size / 1024).toStringAsFixed(0)} KB',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0369A1)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _softChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}