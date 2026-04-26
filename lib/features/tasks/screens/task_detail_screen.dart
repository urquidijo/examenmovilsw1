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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una decisión')));
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
      appBar: AppBar(title: const Text('Detalle de tarea')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty && currentTask == null
          ? Center(child: Text(errorMessage))
          : currentTask == null
          ? const Center(child: Text('Tarea no encontrada'))
          : RefreshIndicator(
              onRefresh: loadTask,
              child: ListView(
                padding: const EdgeInsets.all(16),
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
                    height: 50,
                    child: FilledButton(
                      onPressed: completing || loadingTramite
                          ? null
                          : completeTask,
                      child: completing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Completar tarea'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTaskHeader(WorkflowTask task) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarea asignada',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              task.nodeLabel,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Revisa la información del ticket asociado y completa la acción requerida para continuar el flujo.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(getTaskStatusLabel(task.status))),
                Chip(label: Text(task.departmentName ?? 'Sin departamento')),
                if (task.requiresTramite)
                  const Chip(label: Text('Requiere trámite')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(TaskTicketInfo ticket) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles del ticket',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _InfoItem('Título', ticket.title),
            _InfoItem('Estado', ticket.status),
            _InfoItem('Descripción', ticket.description ?? 'Sin descripción'),
            _InfoItem('Cliente', ticket.clientName ?? 'No especificado'),
            _InfoItem('Teléfono', ticket.clientPhone ?? 'No especificado'),
            _InfoItem('Correo', ticket.clientEmail ?? 'No especificado'),
            _InfoItem(
              'Referencia',
              ticket.clientReference ?? 'No especificada',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(Map<String, dynamic> metadata) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metadata adicional',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...metadata.entries.map(
              (entry) => _InfoItem(entry.key, entry.value.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionCard(WorkflowTask task) {
    final options = task.decisionOptions;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Decisión',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (task.decisionQuestion != null) ...[
              const SizedBox(height: 8),
              Text(task.decisionQuestion!),
            ],
            const SizedBox(height: 12),
            if (options != null && options.isNotEmpty)
              ...options.map(
                (option) => RadioListTile<String>(
                  value: option.value,
                  groupValue: selectedDecisionResult,
                  title: Text(
                    option.label.isNotEmpty ? option.label : option.value,
                  ),
                  subtitle: Text('Valor: ${option.value}'),
                  onChanged: (value) {
                    setState(() => selectedDecisionResult = value);
                  },
                ),
              )
            else
              TextField(
                onChanged: (value) {
                  selectedDecisionResult = value;
                },
                decoration: const InputDecoration(
                  labelText: 'Resultado de decisión',
                  border: OutlineInputBorder(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildDynamicForm() {
    if (loadingTramite) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('Cargando formulario del trámite...'),
        ),
      );
    }

    final template = tramiteTemplate;

    if (template == null) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('No se encontró el formulario del trámite'),
        ),
      );
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formulario del trámite',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              template.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (template.description != null &&
                template.description!.isNotEmpty)
              Text(template.description!),
            const SizedBox(height: 18),
            ...template.fields.map(buildField),
          ],
        ),
      ),
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
        decoration: InputDecoration(
          labelText: field.required ? '${field.label} *' : field.label,
          hintText: field.placeholder,
          border: const OutlineInputBorder(),
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
        decoration: InputDecoration(
          labelText: field.required ? '${field.label} *' : field.label,
          border: const OutlineInputBorder(),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.required ? '${field.label} *' : field.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
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
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
        ],
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
