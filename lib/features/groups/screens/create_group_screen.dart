// lib/features/groups/screens/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unlock/core/constants/app_constants.dart';
import 'package:unlock/core/utils/logger.dart';
import 'package:unlock/models/group_model.dart';
import 'package:unlock/providers/group_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Focus nodes
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();

  // Form state
  String _selectedAvatar = '👥';
  GroupType _selectedType = GroupType.casual;
  GroupPrivacy _selectedPrivacy = GroupPrivacy.private;
  int _maxMembers = 20;
  bool _isCreating = false;

  // Avatar options
  static const List<String> _avatarOptions = [
    '👥',
    '🏆',
    '🎮',
    '🎨',
    '💼',
    '👨‍👩‍👧‍👦',
    '📚',
    '🌟',
    '⚡',
    '🔥',
    '💎',
    '🎯',
  ];

  @override
  void initState() {
    super.initState();

    AppLogger.info('➕ CreateGroupScreen: Iniciado');

    // Configurar animações
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Iniciar animação
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    AppLogger.info('🧹 CreateGroupScreen: Disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escutar mudanças no provider
    ref.listen<GroupActionState>(groupActionProvider, (previous, current) {
      _handleProviderChanges(context, current);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildContent(context),
            ),
          );
        },
      ),
    );
  }

  /// App bar customizada
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Criar Grupo'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.pop(),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : _createGroup,
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
          _buildAvatarSection(context),
          const SizedBox(height: 24),
          _buildTypeSection(context),
          const SizedBox(height: 24),
          _buildPrivacySection(context),
          const SizedBox(height: 24),
          _buildMembersSection(context),
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
            Icons.group_add,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Novo Grupo',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Crie um espaço para desafios e conexões com seus amigos',
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

        // Nome do grupo
        TextFormField(
          controller: _nameController,
          focusNode: _nameFocus,
          decoration: InputDecoration(
            labelText: 'Nome do Grupo',
            hintText: 'Ex: Família Silva, Amigos da Faculdade...',
            prefixIcon: const Icon(Icons.group),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            counter: Text('${_nameController.text.length}/30'),
          ),
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nome é obrigatório';
            }
            if (value.trim().length < 3) {
              return 'Nome deve ter pelo menos 3 caracteres';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
          onFieldSubmitted: (_) => _descriptionFocus.requestFocus(),
        ),

        const SizedBox(height: 16),

        // Descrição
        TextFormField(
          controller: _descriptionController,
          focusNode: _descriptionFocus,
          decoration: InputDecoration(
            labelText: 'Descrição',
            hintText: 'Descreva o propósito do seu grupo...',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            counter: Text('${_descriptionController.text.length}/150'),
          ),
          maxLength: 150,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value != null && value.trim().length > 150) {
              return 'Descrição muito longa';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  /// Seção de seleção de avatar
  Widget _buildAvatarSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avatar do Grupo',
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
              // Avatar selecionado
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _selectedAvatar,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Grid de opções
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _avatarOptions.length,
                itemBuilder: (context, index) {
                  final avatar = _avatarOptions[index];
                  final isSelected = avatar == _selectedAvatar;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = avatar),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          avatar,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Seção de tipo do grupo
  Widget _buildTypeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo do Grupo',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        ...GroupType.values.map((type) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<GroupType>(
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
              subtitle: Text(_getTypeDescription(type)),
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

  /// Seção de privacidade
  Widget _buildPrivacySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacidade',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        ...GroupPrivacy.values.map((privacy) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<GroupPrivacy>(
              value: privacy,
              groupValue: _selectedPrivacy,
              onChanged: (value) => setState(() => _selectedPrivacy = value!),
              title: Text(privacy.label),
              subtitle: Text(privacy.description),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: _selectedPrivacy == privacy
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Seção de configuração de membros
  Widget _buildMembersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações de Membros',
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
              Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Máximo de Membros',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '$_maxMembers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Slider(
                value: _maxMembers.toDouble(),
                min: 5,
                max: 100,
                divisions: 19,
                label: '$_maxMembers membros',
                onChanged: (value) =>
                    setState(() => _maxMembers = value.round()),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5', style: Theme.of(context).textTheme.labelSmall),
                  Text('100', style: Theme.of(context).textTheme.labelSmall),
                ],
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
        onPressed: _isCreating ? null : _createGroup,
        icon: _isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.group_add),
        label: Text(_isCreating ? 'Criando Grupo...' : 'Criar Grupo'),
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

  /// Criar grupo
  void _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.warning('⚠️ Formulário inválido');
      return;
    }

    // Fechar teclado
    FocusScope.of(context).unfocus();

    setState(() => _isCreating = true);

    try {
      AppLogger.info('➕ Criando grupo: ${_nameController.text.trim()}');

      final groupId = await ref
          .read(groupActionProvider.notifier)
          .createGroup(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            avatar: _selectedAvatar,
            type: _selectedType,
            privacy: _selectedPrivacy,
            maxMembers: _maxMembers,
          );

      if (groupId != null && mounted) {
        AppLogger.info('✅ Grupo criado com sucesso: $groupId');

        // Vibração de sucesso
        HapticFeedback.lightImpact();

        // Navegar para o grupo criado
        context.go('/groups/$groupId');
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao criar grupo', error: e);
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  /// Manipular mudanças no provider
  void _handleProviderChanges(BuildContext context, GroupActionState state) {
    if (state.error != null) {
      AppLogger.warning('⚠️ Erro na criação: ${state.error}');
      _showSnackBar(context, state.error!, isError: true);
    }

    if (state.successMessage != null) {
      AppLogger.info('✅ Sucesso na criação: ${state.successMessage}');
    }
  }

  /// Mostrar SnackBar
  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
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

  /// Obter descrição do tipo
  String _getTypeDescription(GroupType type) {
    switch (type) {
      case GroupType.casual:
        return 'Para diversão e desafios descontraídos';
      case GroupType.competitive:
        return 'Focado em competições sérias e rankings';
      case GroupType.family:
        return 'Para membros da família e parentes';
      case GroupType.work:
        return 'Colegas de trabalho e equipes';
      case GroupType.hobby:
        return 'Pessoas com interesses específicos';
      case GroupType.study:
        return 'Grupos de estudo e aprendizado';
    }
  }
}
