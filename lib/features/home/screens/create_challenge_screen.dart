// lib/features/challenges/screens/create_challenge_screen.dart - CORRIGIDO
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/challenge_model.dart'; // ✅ USAR VERSÃO CORRIGIDA

/// Tela para criação de novos desafios
class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Form state
  ChallengeType _selectedType = ChallengeType.creative;
  ArenaType _selectedArena = ArenaType.tournament; // ✅ CORRIGIDO: ArenaType
  DateTime _startsAt = DateTime.now().add(const Duration(hours: 1));
  DateTime _endsAt = DateTime.now().add(const Duration(days: 7));
  int _maxParticipants = 100;
  int _entryFee = 0;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();

    AppLogger.info('➕ CreateChallengeScreen: Iniciado');

    // Configurar animações
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Iniciar animação
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    AppLogger.info('🧹 CreateChallengeScreen: Disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildContent(context),
          );
        },
      ),
    );
  }

  /// App bar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Criar Desafio'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.pop(),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : _createChallenge,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar'),
        ),
      ],
    );
  }

  /// Conteúdo principal
  Widget _buildContent(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderSection(context),
          const SizedBox(height: 24),
          _buildBasicInfoSection(context),
          const SizedBox(height: 24),
          _buildTypeSection(context),
          const SizedBox(height: 24),
          _buildArenaSection(context), // ✅ CORRIGIDO
          const SizedBox(height: 24),
          _buildTimingSection(context),
          const SizedBox(height: 24),
          _buildParticipantsSection(context),
          const SizedBox(height: 32),
          _buildCreateButton(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Seção de cabeçalho
  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.emoji_events,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Novo Desafio',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Crie um desafio emocionante para a comunidade',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Seção de informações básicas
  Widget _buildBasicInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações Básicas',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Título
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Título do Desafio',
            hintText: 'Ex: Melhor Foto do Pôr do Sol',
            prefixIcon: const Icon(Icons.title),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            counter: Text(
              '${_titleController.text.length}/${AppConstants.maxChallengeNameLength}',
            ),
          ),
          maxLength: AppConstants.maxChallengeNameLength,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return ValidationConstants.requiredFieldError;
            }
            if (value.trim().length < 5) {
              return 'Título deve ter pelo menos 5 caracteres';
            }
            if (value.trim().length > AppConstants.maxChallengeNameLength) {
              return 'Título muito longo (máximo ${AppConstants.maxChallengeNameLength} caracteres)';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),

        const SizedBox(height: 16),

        // Descrição
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Descrição',
            hintText: 'Descreva as regras e objetivos do desafio...',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            counter: Text(
              '${_descriptionController.text.length}/${AppConstants.maxChallengeDescriptionLength}',
            ),
          ),
          maxLength: AppConstants.maxChallengeDescriptionLength,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return ValidationConstants.requiredFieldError;
            }
            if (value.trim().length < 10) {
              return 'Descrição deve ter pelo menos 10 caracteres';
            }
            if (value.trim().length >
                AppConstants.maxChallengeDescriptionLength) {
              return 'Descrição muito longa (máximo ${AppConstants.maxChallengeDescriptionLength} caracteres)';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  /// Seção de tipo do desafio
  Widget _buildTypeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo do Desafio',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        ...ChallengeType.values.map((type) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<ChallengeType>(
              value: type,
              groupValue: _selectedType,
              onChanged: (value) => setState(() => _selectedType = value!),
              title: Row(
                children: [
                  Text(type.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(type.label),
                ],
              ),
              subtitle: Text(type.description),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: _selectedType == type
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Seção de arena (corrigida)
  Widget _buildArenaSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arena de Competição',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        ...ArenaType.values.map((arena) {
          // ✅ CORRIGIDO: ArenaType
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<ArenaType>(
              value: arena,
              groupValue: _selectedArena,
              onChanged: (value) => setState(() => _selectedArena = value!),
              title: Row(
                children: [
                  Text(arena.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(arena.label),
                ],
              ),
              subtitle: Text(arena.description),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: _selectedArena == arena
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Seção de timing
  Widget _buildTimingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duração do Desafio',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              // Data de início
              Row(
                children: [
                  Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Início',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${_startsAt.day}/${_startsAt.month}/${_startsAt.year} às ${_startsAt.hour}:${_startsAt.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDateTime(isStart: true),
                    child: const Text('Alterar'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Data de fim
              Row(
                children: [
                  Icon(Icons.stop, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fim',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${_endsAt.day}/${_endsAt.month}/${_endsAt.year} às ${_endsAt.hour}:${_endsAt.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDateTime(isStart: false),
                    child: const Text('Alterar'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Duração calculada
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Duração: ${_calculateDuration()}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Seção de participantes
  Widget _buildParticipantsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações de Participação',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              // Máximo de participantes
              Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Máximo de Participantes',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '$_maxParticipants',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Slider(
                value: _maxParticipants.toDouble(),
                min: 10,
                max: AppConstants.maxChallengeParticipants.toDouble(),
                divisions: 99,
                label: '$_maxParticipants participantes',
                onChanged: (value) =>
                    setState(() => _maxParticipants = value.round()),
              ),

              const SizedBox(height: 16),

              // Taxa de entrada
              Row(
                children: [
                  Icon(Icons.bolt, color: ColorConstants.coinsColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Taxa de Entrada (Faíscas)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '$_entryFee',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.coinsColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Slider(
                value: _entryFee.toDouble(),
                min: 0,
                max: AppConstants.maxEntryFee.toDouble(),
                divisions: 20,
                label: '$_entryFee Faíscas',
                onChanged: (value) => setState(() => _entryFee = value.round()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Botão de criar
  Widget _buildCreateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isCreating ? null : _createChallenge,
        icon: _isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.emoji_events),
        label: Text(_isCreating ? 'Criando Desafio...' : 'Criar Desafio'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ========== MÉTODOS ==========

  /// Selecionar data e hora
  void _selectDateTime({required bool isStart}) async {
    final currentDate = isStart ? _startsAt : _endsAt;

    final date = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentDate),
    );

    if (time == null) return;

    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startsAt = selectedDateTime;
        // Garantir que fim seja após início
        if (_endsAt.isBefore(_startsAt)) {
          _endsAt = _startsAt.add(const Duration(days: 7));
        }
      } else {
        _endsAt = selectedDateTime;
        // Garantir que fim seja após início
        if (_endsAt.isBefore(_startsAt)) {
          _startsAt = _endsAt.subtract(const Duration(hours: 1));
        }
      }
    });
  }

  /// Calcular duração
  String _calculateDuration() {
    final duration = _endsAt.difference(_startsAt);

    if (duration.inDays > 0) {
      return '${duration.inDays} dias e ${duration.inHours % 24} horas';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} horas e ${duration.inMinutes % 60} minutos';
    } else {
      return '${duration.inMinutes} minutos';
    }
  }

  /// Criar desafio
  void _createChallenge() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.warning('⚠️ Formulário inválido');
      return;
    }

    // Validações adicionais
    if (_endsAt.isBefore(_startsAt)) {
      _showSnackBar('Data de fim deve ser após data de início', isError: true);
      return;
    }

    if (_startsAt.difference(DateTime.now()).inMinutes < 10) {
      _showSnackBar(
        'Desafio deve começar em pelo menos 10 minutos',
        isError: true,
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      AppLogger.info('➕ Criando desafio: ${_titleController.text.trim()}');

      // TODO: Implementar criação via provider quando estiver disponível
      /*
      final challengeId = await ref.read(challengeActionProvider.notifier).createChallenge(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        arena: _selectedArena,
        startsAt: _startsAt,
        endsAt: _endsAt,
        maxParticipants: _maxParticipants,
        entryFee: _entryFee,
      );

      if (challengeId != null && mounted) {
        AppLogger.info('✅ Desafio criado com sucesso: $challengeId');
        context.go('/challenges/$challengeId');
      }
      */

      // Por enquanto, simular sucesso
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        _showSnackBar('Desafio criado com sucesso! 🎉');
        context.pop();
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao criar desafio', error: e);
      _showSnackBar('Erro ao criar desafio: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  /// Mostrar SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
