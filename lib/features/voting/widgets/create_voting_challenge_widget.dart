// lib/features/voting/widgets/create_voting_challenge_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/challenge_model.dart';
import 'package:unlock/models/vote_model.dart';
import 'package:unlock/providers/auth_provider.dart';
import 'package:unlock/providers/challenge_provider.dart';

/// Widget para criar desafios com sistema de votação
class CreateVotingChallengeWidget extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const CreateVotingChallengeWidget({super.key, this.onSuccess, this.onCancel});

  @override
  ConsumerState<CreateVotingChallengeWidget> createState() =>
      _CreateVotingChallengeWidgetState();
}

class _CreateVotingChallengeWidgetState
    extends ConsumerState<CreateVotingChallengeWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late PageController _pageController;

  // Controladores de formulário
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Estado do formulário
  int _currentStep = 0;
  ChallengeType _selectedType = ChallengeType.creative;
  ArenaType _selectedArena = ArenaType.tournament;

  // Configurações de tempo
  DateTime? _startsAt;
  DateTime? _submissionEndsAt;
  DateTime? _votingEndsAt;

  // Configurações de votação
  bool _enableVoting = true;
  bool _allowSelfVoting = false;
  int _maxVotesPerUser = 100;
  List<VoteType> _allowedVoteTypes = [...VoteType.values];

  // Configurações anti-manipulação
  bool _enableAntiManipulation = true;
  int _maxVotesPerIP = 5;
  int _maxVotesPerDevice = 3;

  // Configurações adicionais
  int _maxParticipants = 100;
  int _entryFee = 0;
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _pageController = PageController();
    _animationController.forward();

    // Configurar datas padrão
    _initializeDefaultDates();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeDefaultDates() {
    final now = DateTime.now();
    _startsAt = now.add(const Duration(hours: 1));
    _submissionEndsAt = now.add(const Duration(days: 3));
    _votingEndsAt = now.add(const Duration(days: 5));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                _buildHeader(context),
                _buildProgressIndicator(context),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildBasicInfoStep(context),
                      _buildTimeSettingsStep(context),
                      _buildVotingSettingsStep(context),
                      _buildAdvancedSettingsStep(context),
                      _buildReviewStep(context),
                    ],
                  ),
                ),
                _buildNavigationButtons(context),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construir cabeçalho
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.create,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Criar Desafio com Votação',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Configure seu desafio criativo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onCancel != null)
            IconButton(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  /// Construir indicador de progresso
  Widget _buildProgressIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(5, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Step 1: Informações básicas
  Widget _buildBasicInfoStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações Básicas',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Título
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Título do Desafio',
              hintText: 'Ex: Melhor foto do pôr do sol',
              prefixIcon: Icon(Icons.title),
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 16),

          // Descrição
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              hintText: 'Descreva as regras e objetivos...',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: 24),

          // Tipo de desafio
          Text(
            'Tipo de Desafio',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ChallengeType.values
                .where((type) => type.supportsVoting)
                .map((type) => _buildTypeChip(context, type))
                .toList(),
          ),

          const SizedBox(height: 24),

          // Arena
          Text(
            'Arena',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ArenaType.values
                .map((arena) => _buildArenaChip(context, arena))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Step 2: Configurações de tempo
  Widget _buildTimeSettingsStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurações de Tempo',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Início do desafio
          _buildDateTimePicker(
            context,
            'Início do Desafio',
            _startsAt,
            Icons.play_arrow,
            (date) => setState(() => _startsAt = date),
          ),

          const SizedBox(height: 16),

          // Fim das submissões
          _buildDateTimePicker(
            context,
            'Fim das Submissões',
            _submissionEndsAt,
            Icons.upload,
            (date) => setState(() => _submissionEndsAt = date),
          ),

          const SizedBox(height: 16),

          // Fim da votação
          _buildDateTimePicker(
            context,
            'Fim da Votação',
            _votingEndsAt,
            Icons.how_to_vote,
            (date) => setState(() => _votingEndsAt = date),
          ),

          const SizedBox(height: 24),

          // Validação visual das datas
          _buildTimelinePreview(context),
        ],
      ),
    );
  }

  /// Step 3: Configurações de votação
  Widget _buildVotingSettingsStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurações de Votação',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Habilitar votação
          SwitchListTile(
            title: const Text('Habilitar Votação'),
            subtitle: const Text('Permitir que usuários votem nas submissões'),
            value: _enableVoting,
            onChanged: (value) => setState(() => _enableVoting = value),
          ),

          if (_enableVoting) ...[
            const Divider(),

            // Auto-voto
            SwitchListTile(
              title: const Text('Permitir Auto-voto'),
              subtitle: const Text(
                'Usuários podem votar em suas próprias submissões',
              ),
              value: _allowSelfVoting,
              onChanged: (value) => setState(() => _allowSelfVoting = value),
            ),

            const SizedBox(height: 16),

            // Limite de votos
            Text(
              'Limite de Votos por Usuário',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _maxVotesPerUser.toDouble(),
              min: 10,
              max: 1000,
              divisions: 99,
              label: _maxVotesPerUser.toString(),
              onChanged: (value) =>
                  setState(() => _maxVotesPerUser = value.toInt()),
            ),

            const SizedBox(height: 16),

            // Tipos de voto permitidos
            Text(
              'Tipos de Voto Permitidos',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VoteType.values.map((type) {
                final isSelected = _allowedVoteTypes.contains(type);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(type.emoji),
                      const SizedBox(width: 4),
                      Text(type.label),
                      const SizedBox(width: 4),
                      Text('(${type.weight > 0 ? '+' : ''}${type.weight})'),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _allowedVoteTypes.add(type);
                      } else {
                        _allowedVoteTypes.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Step 4: Configurações avançadas
  Widget _buildAdvancedSettingsStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurações Avançadas',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Anti-manipulação
          SwitchListTile(
            title: const Text('Sistema Anti-Manipulação'),
            subtitle: const Text('Previne votos falsos e spam'),
            value: _enableAntiManipulation,
            onChanged: (value) =>
                setState(() => _enableAntiManipulation = value),
          ),

          if (_enableAntiManipulation) ...[
            const SizedBox(height: 16),

            Text(
              'Limite de Votos por IP: $_maxVotesPerIP',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _maxVotesPerIP.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (value) =>
                  setState(() => _maxVotesPerIP = value.toInt()),
            ),

            Text(
              'Limite de Votos por Dispositivo: $_maxVotesPerDevice',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _maxVotesPerDevice.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) =>
                  setState(() => _maxVotesPerDevice = value.toInt()),
            ),
          ],

          const Divider(),

          // Configurações gerais
          Text(
            'Participantes Máximos',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _maxParticipants.toDouble(),
            min: 10,
            max: 1000,
            divisions: 99,
            label: _maxParticipants.toString(),
            onChanged: (value) =>
                setState(() => _maxParticipants = value.toInt()),
          ),

          const SizedBox(height: 16),

          Text(
            'Taxa de Entrada (Faíscas): $_entryFee',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _entryFee.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (value) => setState(() => _entryFee = value.toInt()),
          ),
        ],
      ),
    );
  }

  /// Step 5: Revisão
  Widget _buildReviewStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revisão Final',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewSection('Básico', [
                    'Título: ${_titleController.text}',
                    'Tipo: ${_selectedType.label}',
                    'Arena: ${_selectedArena.label}',
                  ]),

                  _buildReviewSection('Cronograma', [
                    'Início: ${_formatDateTime(_startsAt)}',
                    'Fim Submissões: ${_formatDateTime(_submissionEndsAt)}',
                    'Fim Votação: ${_formatDateTime(_votingEndsAt)}',
                  ]),

                  _buildReviewSection('Votação', [
                    'Habilitada: ${_enableVoting ? 'Sim' : 'Não'}',
                    if (_enableVoting) ...[
                      'Auto-voto: ${_allowSelfVoting ? 'Permitido' : 'Negado'}',
                      'Limite/usuário: $_maxVotesPerUser votos',
                      'Tipos permitidos: ${_allowedVoteTypes.length} tipos',
                    ],
                  ]),

                  _buildReviewSection('Avançado', [
                    'Max participantes: $_maxParticipants',
                    'Taxa entrada: $_entryFee Faíscas',
                    'Anti-manipulação: ${_enableAntiManipulation ? 'Ativo' : 'Inativo'}',
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construir seção de revisão
  Widget _buildReviewSection(String title, List<String> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $item',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir chip de tipo
  Widget _buildTypeChip(BuildContext context, ChallengeType type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(type.icon), const SizedBox(width: 4), Text(type.label)],
      ),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedType = type),
    );
  }

  /// Construir chip de arena
  Widget _buildArenaChip(BuildContext context, ArenaType arena) {
    final isSelected = _selectedArena == arena;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(arena.icon),
          const SizedBox(width: 4),
          Text(arena.label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedArena = arena),
    );
  }

  /// Construir seletor de data/hora
  Widget _buildDateTimePicker(
    BuildContext context,
    String label,
    DateTime? currentDate,
    IconData icon,
    Function(DateTime) onChanged,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        subtitle: Text(
          currentDate != null ? _formatDateTime(currentDate) : 'Selecionar...',
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: () => _selectDateTime(context, currentDate, onChanged),
      ),
    );
  }

  /// Construir preview da timeline
  Widget _buildTimelinePreview(BuildContext context) {
    if (_startsAt == null ||
        _submissionEndsAt == null ||
        _votingEndsAt == null) {
      return const SizedBox.shrink();
    }

    final submissionDuration = _submissionEndsAt!.difference(_startsAt!);
    final votingDuration = _votingEndsAt!.difference(_submissionEndsAt!);
    final totalDuration = _votingEndsAt!.difference(_startsAt!);

    final submissionPercent =
        (submissionDuration.inHours / totalDuration.inHours) * 100;
    final votingPercent =
        (votingDuration.inHours / totalDuration.inHours) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline do Desafio',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: submissionPercent.toInt(),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: votingPercent.toInt(),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Submissões (${submissionDuration.inDays}d)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Votação (${votingDuration.inDays}d)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construir botões de navegação
  Widget _buildNavigationButtons(BuildContext context) {
    final challengeState = ref.watch(challengeActionProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: challengeState.isLoading ? null : _previousStep,
                child: const Text('Anterior'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),

          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: challengeState.isLoading ? null : _nextStep,
              child: challengeState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == 4 ? 'Criar Desafio' : 'Próximo'),
            ),
          ),
        ],
      ),
    );
  }

  /// Navegar para próximo step
  void _nextStep() {
    if (_currentStep < 4) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _createChallenge();
    }
  }

  /// Navegar para step anterior
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Validar step atual
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_titleController.text.trim().isEmpty) {
          _showError('Por favor, insira um título para o desafio');
          return false;
        }
        if (_descriptionController.text.trim().isEmpty) {
          _showError('Por favor, insira uma descrição');
          return false;
        }
        return true;

      case 1:
        if (_startsAt == null ||
            _submissionEndsAt == null ||
            _votingEndsAt == null) {
          _showError('Por favor, configure todas as datas');
          return false;
        }
        if (_startsAt!.isAfter(_submissionEndsAt!)) {
          _showError('A data de início deve ser antes do fim das submissões');
          return false;
        }
        if (_submissionEndsAt!.isAfter(_votingEndsAt!)) {
          _showError('O fim das submissões deve ser antes do fim da votação');
          return false;
        }
        return true;

      case 2:
        if (_enableVoting && _allowedVoteTypes.isEmpty) {
          _showError('Selecione pelo menos um tipo de voto');
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  /// Criar desafio
  Future<void> _createChallenge() async {
    final user = ref.read(authProvider.select((state) => state.user));
    if (user == null) {
      _showError('Você precisa estar logado para criar um desafio.');
      return;
    }

    final challengeId = await ref
        .read(challengeActionProvider.notifier)
        .createChallenge(
          creatorId: user.uid,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          arena: _selectedArena,
          startsAt: _startsAt!,
          submissionEndsAt: _submissionEndsAt!,
          votingEndsAt: _votingEndsAt!,
          allowSelfVoting: _allowSelfVoting,
          maxVotesPerUser: _maxVotesPerUser,
          allowedVoteTypes: _allowedVoteTypes,
          antiManipulation: _enableAntiManipulation
              ? {
                  'checkIP': true,
                  'maxVotesPerIP': _maxVotesPerIP,
                  'checkDevice': true,
                  'maxVotesPerDevice': _maxVotesPerDevice,
                }
              : {},
          maxParticipants: _maxParticipants,
          entryFee: _entryFee,
          tags: _tags,
        );

    if (challengeId != null) {
      AppLogger.info('✅ Desafio criado com sucesso: $challengeId');
      widget.onSuccess?.call();
    }
  }

  /// Selecionar data e hora
  Future<void> _selectDateTime(
    BuildContext context,
    DateTime? currentDate,
    Function(DateTime) onChanged,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDate ?? DateTime.now()),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        onChanged(dateTime);
      }
    }
  }

  /// Mostrar erro
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Formatar data/hora
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} às ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
