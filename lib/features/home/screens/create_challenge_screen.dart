// screens/create_challenge_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  ChallengeType _selectedType = ChallengeType.creative;
  ChallengeArena _selectedArena = ChallengeArena.public;
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  int _maxParticipants = 0; // 0 = ilimitado
  int _rewardFaiscas = 50;
  bool _isLoading = false;

  final List<ChallengeType> _challengeTypes = [
    ChallengeType.creative,
    ChallengeType.game,
    ChallengeType.quiz,
    ChallengeType.realWorld,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Desafio'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createChallenge,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('CRIAR'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 24),
            _buildBasicInfo(),
            const SizedBox(height: 24),
            _buildArenaSelector(),
            const SizedBox(height: 24),
            _buildSettings(),
            const SizedBox(height: 32),
            _buildPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Desafio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _challengeTypes.map((type) {
                final isSelected = _selectedType == type;
                return FilterChip(
                  label: Text(_getTypeLabel(type)),
                  avatar: Icon(
                    _getTypeIcon(type),
                    size: 18,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              _getTypeDescription(_selectedType),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Básicas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título do Desafio',
                hintText: 'Ex: Melhor foto do pôr do sol',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Digite um título para o desafio';
                }
                if (value!.length < 5) {
                  return 'Título muito curto (mínimo 5 caracteres)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Descreva as regras e critérios...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Digite uma descrição para o desafio';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArenaSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Arena', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...ChallengeArena.values.map((arena) {
              return RadioListTile<ChallengeArena>(
                title: Text(_getArenaLabel(arena)),
                subtitle: Text(_getArenaDescription(arena)),
                value: arena,
                groupValue: _selectedArena,
                onChanged: (value) {
                  setState(() {
                    _selectedArena = value!;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Data de Encerramento'),
              subtitle: Text(
                '${_endDate.day}/${_endDate.month}/${_endDate.year}',
              ),
              onTap: _selectEndDate,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Máximo de Participantes'),
                      Slider(
                        value: _maxParticipants.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: _maxParticipants == 0
                            ? 'Ilimitado'
                            : '$_maxParticipants',
                        onChanged: (value) {
                          setState(() {
                            _maxParticipants = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flash_on),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recompensa (Faíscas)'),
                      Slider(
                        value: _rewardFaiscas.toDouble(),
                        min: 10,
                        max: 500,
                        divisions: 49,
                        label: '$_rewardFaiscas ⚡',
                        onChanged: (value) {
                          setState(() {
                            _rewardFaiscas = value.toInt();
                          });
                        },
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

  Widget _buildPreview() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Prévia do Desafio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getTypeIcon(_selectedType)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _titleController.text.isEmpty
                              ? 'Título do desafio'
                              : _titleController.text,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Chip(
                        label: Text('$_rewardFaiscas ⚡'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descriptionController.text.isEmpty
                        ? 'Descrição do desafio aparecerá aqui'
                        : _descriptionController.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Termina em ${_endDate.day}/${_endDate.month}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        _getArenaLabel(_selectedArena),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now().add(const Duration(hours: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final challenge = ChallengeModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        arena: _selectedArena,
        creatorId: 'current_user_id', // TODO: Get from auth provider
        createdAt: DateTime.now(),
        endDate: _endDate,
        maxParticipants: _maxParticipants == 0 ? null : _maxParticipants,
        rewardFaiscas: _rewardFaiscas,
        status: ChallengeStatus.active,
        participants: [],
      );

      await ref.read(challengeProvider.notifier).createChallenge(challenge);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Desafio criado com sucesso! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar desafio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTypeLabel(ChallengeType type) {
    switch (type) {
      case ChallengeType.creative:
        return 'Criativo';
      case ChallengeType.game:
        return 'Game';
      case ChallengeType.quiz:
        return 'Quiz';
      case ChallengeType.realWorld:
        return 'Mundo Real';
    }
  }

  IconData _getTypeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.creative:
        return Icons.palette;
      case ChallengeType.game:
        return Icons.videogame_asset;
      case ChallengeType.quiz:
        return Icons.quiz;
      case ChallengeType.realWorld:
        return Icons.public;
    }
  }

  String _getTypeDescription(ChallengeType type) {
    switch (type) {
      case ChallengeType.creative:
        return 'Fotos, vídeos, desenhos e outras criações artísticas';
      case ChallengeType.game:
        return 'Mini-jogos e desafios de habilidade';
      case ChallengeType.quiz:
        return 'Perguntas e respostas sobre diversos temas';
      case ChallengeType.realWorld:
        return 'Atividades físicas e do mundo real';
    }
  }

  String _getArenaLabel(ChallengeArena arena) {
    switch (arena) {
      case ChallengeArena.oneVsOne:
        return '1v1 - Duelo';
      case ChallengeArena.group:
        return 'Grupo Fechado';
      case ChallengeArena.public:
        return 'Público';
    }
  }

  String _getArenaDescription(ChallengeArena arena) {
    switch (arena) {
      case ChallengeArena.oneVsOne:
        return 'Desafie um amigo diretamente';
      case ChallengeArena.group:
        return 'Apenas para seu grupo de amigos';
      case ChallengeArena.public:
        return 'Aberto para todos na plataforma';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
