// models/profile_model.dart
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileModel {
  final String id;
  final String name;
  final String avatar;
  final int age;
  final String location;
  final List<String> interests;
  final String bio;
  final int matchPercentage;
  final String status; // online, offline, away
  final DateTime lastSeen;
  final List<String> photos;
  final String profession;

  ProfileModel({
    required this.id,
    required this.name,
    required this.avatar,
    required this.age,
    required this.location,
    required this.interests,
    required this.bio,
    required this.matchPercentage,
    required this.status,
    required this.lastSeen,
    required this.photos,
    required this.profession,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      age: json['age'] ?? 18,
      location: json['location'] ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      bio: json['bio'] ?? '',
      matchPercentage: json['matchPercentage'] ?? 0,
      status: json['status'] ?? 'offline',
      lastSeen: DateTime.parse(
        json['lastSeen'] ?? DateTime.now().toIso8601String(),
      ),
      photos: List<String>.from(json['photos'] ?? []),
      profession: json['profession'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'age': age,
      'location': location,
      'interests': interests,
      'bio': bio,
      'matchPercentage': matchPercentage,
      'status': status,
      'lastSeen': lastSeen.toIso8601String(),
      'photos': photos,
      'profession': profession,
    };
  }

  // Factory para gerar perfis aleatórios para teste
  static ProfileModel generateRandom() {
    final random = Random();
    final names = [
      'Ana Silva',
      'Carlos Santos',
      'Maria Oliveira',
      'João Pereira',
      'Fernanda Costa',
      'Rafael Lima',
      'Juliana Rodrigues',
      'Bruno Alves',
      'Camila Ferreira',
      'Diego Martins',
      'Letícia Barbosa',
      'Gabriel Souza',
      'Amanda Ribeiro',
      'Thiago Nascimento',
      'Priscila Araújo',
      'Lucas Mendes',
    ];

    final locations = [
      'São Paulo, SP',
      'Rio de Janeiro, RJ',
      'Belo Horizonte, MG',
      'Salvador, BA',
      'Fortaleza, CE',
      'Brasília, DF',
      'Curitiba, PR',
      'Recife, PE',
      'Porto Alegre, RS',
      'Manaus, AM',
    ];

    final interestsList = [
      'Música',
      'Cinema',
      'Livros',
      'Viagens',
      'Esportes',
      'Arte',
      'Tecnologia',
      'Culinária',
      'Fotografia',
      'Dança',
      'Yoga',
      'Natureza',
      'Games',
      'Animais',
      'Moda',
      'Investimentos',
    ];

    final professions = [
      'Designer',
      'Desenvolvedor',
      'Médico',
      'Advogado',
      'Professor',
      'Engenheiro',
      'Arquiteto',
      'Psicólogo',
      'Jornalista',
      'Marketeiro',
      'Enfermeiro',
      'Contador',
      'Artista',
      'Empresário',
      'Consultor',
    ];

    final statusOptions = ['online', 'offline', 'away'];

    final selectedInterests = <String>[];
    final interestCount = random.nextInt(5) + 2; // 2-6 interesses
    while (selectedInterests.length < interestCount) {
      final interest = interestsList[random.nextInt(interestsList.length)];
      if (!selectedInterests.contains(interest)) {
        selectedInterests.add(interest);
      }
    }

    return ProfileModel(
      id: 'profile_${random.nextInt(10000)}',
      name: names[random.nextInt(names.length)],
      avatar: 'https://picsum.photos/200/200?random=${random.nextInt(1000)}',
      age: random.nextInt(25) + 18, // 18-42 anos
      location: locations[random.nextInt(locations.length)],
      interests: selectedInterests,
      bio: _generateRandomBio(),
      matchPercentage: random.nextInt(40) + 60, // 60-99%
      status: statusOptions[random.nextInt(statusOptions.length)],
      lastSeen: DateTime.now().subtract(
        Duration(
          minutes: random.nextInt(1440), // últimas 24h
        ),
      ),
      photos: List.generate(
        random.nextInt(4) + 2, // 2-5 fotos
        (index) =>
            'https://picsum.photos/400/600?random=${random.nextInt(1000) + index}',
      ),
      profession: professions[random.nextInt(professions.length)],
    );
  }

  static String _generateRandomBio() {
    final bios = [
      'Aventureiro por natureza, sempre em busca de novas experiências! 🌍',
      'Apaixonado pela vida e por momentos únicos ✨',
      'Coffee lover ☕ | Dog person 🐕 | Weekend explorer',
      'Vivendo um dia de cada vez com muito amor e risadas 😊',
      'Sonhador, realizador e sempre positivo! 🌟',
      'Arte, música e boas conversas são meu combustível 🎵',
      'Explorando o mundo e fazendo conexões genuínas 🗺️',
      'Mente curiosa, coração aberto para novas amizades ❤️',
    ];

    final random = Random();
    return bios[random.nextInt(bios.length)];
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? avatar,
    int? age,
    String? location,
    List<String>? interests,
    String? bio,
    int? matchPercentage,
    String? status,
    DateTime? lastSeen,
    List<String>? photos,
    String? profession,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      age: age ?? this.age,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      photos: photos ?? this.photos,
      profession: profession ?? this.profession,
    );
  }
}

class ProfilesState {
  final List<ProfileModel> profiles;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final Set<String> likedProfiles;
  final Set<String> superLikedProfiles;
  final Set<String> giftedProfiles;

  const ProfilesState({
    this.profiles = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.likedProfiles = const {},
    this.superLikedProfiles = const {},
    this.giftedProfiles = const {},
  });

  ProfilesState copyWith({
    List<ProfileModel>? profiles,
    bool? isLoading,
    bool? hasMore,
    String? error,
    Set<String>? likedProfiles,
    Set<String>? superLikedProfiles,
    Set<String>? giftedProfiles,
  }) {
    return ProfilesState(
      profiles: profiles ?? this.profiles,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      likedProfiles: likedProfiles ?? this.likedProfiles,
      superLikedProfiles: superLikedProfiles ?? this.superLikedProfiles,
      giftedProfiles: giftedProfiles ?? this.giftedProfiles,
    );
  }
}

class ProfilesNotifier extends StateNotifier<ProfilesState> {
  ProfilesNotifier() : super(const ProfilesState()) {
    loadInitialProfiles();
  }

  static const int _pageSize = 10;
  final Random _random = Random();

  // Carrega perfis iniciais
  Future<void> loadInitialProfiles() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.delayed(
        const Duration(milliseconds: 800),
      ); // Simula delay da API

      final profiles = _generateInitialProfiles();

      state = state.copyWith(
        profiles: profiles,
        isLoading: false,
        hasMore: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar perfis: $e',
      );
    }
  }

  // Carrega mais perfis (scroll infinito)
  Future<void> loadMoreProfiles() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simula delay da API

      final newProfiles = _generateRandomProfiles();
      final allProfiles = [...state.profiles, ...newProfiles];

      // Simula fim dos resultados após certo número de perfis
      final hasMore = allProfiles.length < 100;

      state = state.copyWith(
        profiles: allProfiles,
        isLoading: false,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar mais perfis: $e',
      );
    }
  }

  // Refresh da lista
  Future<void> refreshProfiles() async {
    state = const ProfilesState();
    await loadInitialProfiles();
  }

  // Ações de interação
  void likeProfile(String profileId) {
    final newLiked = Set<String>.from(state.likedProfiles)..add(profileId);
    state = state.copyWith(likedProfiles: newLiked);
  }

  void superLikeProfile(String profileId) {
    final newSuperLiked = Set<String>.from(state.superLikedProfiles)
      ..add(profileId);
    state = state.copyWith(superLikedProfiles: newSuperLiked);
  }

  void sendGift(String profileId) {
    final newGifted = Set<String>.from(state.giftedProfiles)..add(profileId);
    state = state.copyWith(giftedProfiles: newGifted);
  }

  void removeLike(String profileId) {
    final newLiked = Set<String>.from(state.likedProfiles)..remove(profileId);
    state = state.copyWith(likedProfiles: newLiked);
  }

  // Gera perfis iniciais com dados específicos
  List<ProfileModel> _generateInitialProfiles() {
    return [
      ProfileModel(
        id: 'profile_001',
        name: 'Sofia Mendes',
        avatar: 'https://picsum.photos/200/200?random=1',
        age: 26,
        location: 'São Paulo, SP',
        interests: ['Fotografia', 'Viagens', 'Arte', 'Culinária'],
        bio: 'Fotógrafa apaixonada por capturar momentos únicos ✨📸',
        matchPercentage: 95,
        status: 'online',
        lastSeen: DateTime.now(),
        photos: [
          'https://picsum.photos/400/600?random=10',
          'https://picsum.photos/400/600?random=11',
          'https://picsum.photos/400/600?random=12',
        ],
        profession: 'Fotógrafa',
      ),
      ProfileModel(
        id: 'profile_002',
        name: 'Ricardo Oliveira',
        avatar: 'https://picsum.photos/200/200?random=2',
        age: 29,
        location: 'Rio de Janeiro, RJ',
        interests: ['Música', 'Surfista', 'Cinema', 'Tecnologia'],
        bio: 'Desenvolvedor de dia, músico de noite 🎵💻',
        matchPercentage: 88,
        status: 'online',
        lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
        photos: [
          'https://picsum.photos/400/600?random=20',
          'https://picsum.photos/400/600?random=21',
        ],
        profession: 'Desenvolvedor',
      ),
      ProfileModel(
        id: 'profile_003',
        name: 'Marina Santos',
        avatar: 'https://picsum.photos/200/200?random=3',
        age: 24,
        location: 'Belo Horizonte, MG',
        interests: ['Yoga', 'Natureza', 'Livros', 'Animais'],
        bio: 'Buscando equilíbrio e conexões verdadeiras 🧘‍♀️🌿',
        matchPercentage: 92,
        status: 'away',
        lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
        photos: [
          'https://picsum.photos/400/600?random=30',
          'https://picsum.photos/400/600?random=31',
          'https://picsum.photos/400/600?random=32',
          'https://picsum.photos/400/600?random=33',
        ],
        profession: 'Instrutora de Yoga',
      ),
      // Adiciona mais alguns perfis aleatórios
      ...List.generate(_pageSize - 3, (index) => ProfileModel.generateRandom()),
    ];
  }

  // Gera perfis aleatórios para scroll infinito
  List<ProfileModel> _generateRandomProfiles() {
    return List.generate(_pageSize, (index) => ProfileModel.generateRandom());
  }

  // Filtros (pode ser expandido futuramente)
  void filterByAge(int minAge, int maxAge) {
    // Implementar filtro por idade
  }

  void filterByLocation(String location) {
    // Implementar filtro por localização
  }

  void filterByInterests(List<String> interests) {
    // Implementar filtro por interesses
  }
}

// Providers
final profilesProvider = StateNotifierProvider<ProfilesNotifier, ProfilesState>(
  (ref) {
    return ProfilesNotifier();
  },
);

// Provider para profile específico
final profileProvider = Provider.family<ProfileModel?, String>((
  ref,
  profileId,
) {
  final profiles = ref.watch(profilesProvider).profiles;
  try {
    return profiles.firstWhere((profile) => profile.id == profileId);
  } catch (e) {
    return null;
  }
});

// Provider para status de like de um perfil
final profileLikeStatusProvider = Provider.family<Map<String, bool>, String>((
  ref,
  profileId,
) {
  final state = ref.watch(profilesProvider);
  return {
    'liked': state.likedProfiles.contains(profileId),
    'superLiked': state.superLikedProfiles.contains(profileId),
    'gifted': state.giftedProfiles.contains(profileId),
  };
});

// Provider para estatísticas
final profileStatsProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(profilesProvider);
  return {
    'total': state.profiles.length,
    'liked': state.likedProfiles.length,
    'superLiked': state.superLikedProfiles.length,
    'gifted': state.giftedProfiles.length,
  };
});

class ProfilesPage extends ConsumerStatefulWidget {
  const ProfilesPage({super.key});

  @override
  ConsumerState<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends ConsumerState<ProfilesPage>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(profilesProvider.notifier).loadMoreProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profilesState = ref.watch(profilesProvider);
    final stats = ref.watch(profileStatsProvider);

    return Scaffold(
      backgroundColor: _getBackgroundColor(isDark),
      body: RefreshIndicator(
        onRefresh: () => ref.read(profilesProvider.notifier).refreshProfiles(),
        color: Colors.deepPurple,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(isDark, stats),
            _buildProfilesList(profilesState, isDark),
            if (profilesState.isLoading && profilesState.profiles.isNotEmpty)
              _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA);
  }

  Widget _buildAppBar(bool isDark, Map<String, int> stats) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Descobrir',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.tune,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          onPressed: _showFilters,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int value, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfilesList(ProfilesState state, bool isDark) {
    if (state.profiles.isEmpty && state.isLoading) {
      return SliverFillRemaining(child: _buildInitialLoading(isDark));
    }

    if (state.profiles.isEmpty && state.error != null) {
      return SliverFillRemaining(child: _buildError(state.error!, isDark));
    }

    if (state.profiles.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState(isDark));
    }

    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final profile = state.profiles[index];
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ProfileCard(
              profile: profile,
              onTap: () => _showProfileDetails(profile),
              isDark: isDark,
            ),
          );
        }, childCount: state.profiles.length),
      ),
    );
  }

  Widget _buildInitialLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade400,
                  Colors.indigo.shade400,
                  Colors.blue.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Descobrindo perfis incríveis...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.red.shade300 : Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Ops! Algo deu errado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                ref.read(profilesProvider.notifier).refreshProfiles(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum perfil encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajuste seus filtros ou tente novamente',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.deepPurple,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  void _showProfileDetails(ProfileModel profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileBottomSheet(profile: profile),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Em breve...',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Fechar'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

class ProfileCard extends StatefulWidget {
  final ProfileModel profile;
  final VoidCallback onTap;
  final bool isDark;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 100,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.grey.shade900.withOpacity(0.4)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: widget.isDark
                    ? Border.all(color: Colors.grey.shade800.withOpacity(0.5))
                    : null,
                boxShadow: widget.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  _buildPhoto(),
                  Expanded(child: _buildInfo()),
                  _buildMatchBadge(),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoto() {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.all(10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: widget.profile.avatar,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.grey),
              ),
            ),
          ),
          if (widget.profile.status == 'online')
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.profile.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                ', ${widget.profile.age}',
                style: TextStyle(
                  fontSize: 16,
                  color: widget.isDark ? Colors.grey.shade300 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 12,
                color: widget.isDark
                    ? Colors.grey.shade400
                    : Colors.grey.shade500,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  widget.profile.location.split(',')[0], // Só cidade
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.indigo.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${widget.profile.matchPercentage}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ProfileBottomSheet extends ConsumerStatefulWidget {
  final ProfileModel profile;

  const ProfileBottomSheet({super.key, required this.profile});

  @override
  ConsumerState<ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends ConsumerState<ProfileBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late PageController _pageController;
  int _currentPhoto = 0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageController = PageController();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final likeStatus = ref.watch(profileLikeStatusProvider(widget.profile.id));

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeOutCubic,
            ),
          ),
      child: Container(
        height: size.height * 0.9,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHandle(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPhotos(isDark),
                    _buildBasicInfo(isDark),
                    _buildInterests(isDark),
                    _buildBio(isDark),
                    const SizedBox(height: 100), // Espaço para botões
                  ],
                ),
              ),
            ),
            _buildActions(isDark, likeStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildPhotos(bool isDark) {
    return Container(
      height: 350,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPhoto = index),
              itemCount: widget.profile.photos.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: widget.profile.photos[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    child: const Icon(Icons.error),
                  ),
                );
              },
            ),
          ),
          // Indicadores de foto
          if (widget.profile.photos.length > 1)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(
                  widget.profile.photos.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: index == _currentPhoto
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Status
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.profile.name}, ${widget.profile.age}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.profile.profession,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.profile.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.indigo.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${widget.profile.matchPercentage}% match',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterests(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interesses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.profile.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: Colors.deepPurple.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBio(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sobre',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900.withOpacity(0.3)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: isDark ? Border.all(color: Colors.grey.shade800) : null,
            ),
            child: Text(
              widget.profile.bio,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isDark, Map<String, bool> likeStatus) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: likeStatus['liked']!
                    ? Icons.favorite
                    : Icons.favorite_border,
                label: 'Curtir',
                color: Colors.red,
                isActive: likeStatus['liked']!,
                onTap: () => _handleAction('like'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: likeStatus['superLiked']!
                    ? Icons.star
                    : Icons.star_border,
                label: 'Super Like',
                color: Colors.amber,
                isActive: likeStatus['superLiked']!,
                onTap: () => _handleAction('super'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: likeStatus['gifted']!
                    ? Icons.card_giftcard
                    : Icons.card_giftcard_outlined,
                label: 'Presente',
                color: Colors.purple,
                isActive: likeStatus['gifted']!,
                onTap: () => _handleAction('gift'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: isActive ? 0 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.white : color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.profile.status) {
      case 'online':
        return Colors.green;
      case 'away':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (widget.profile.status) {
      case 'online':
        return 'Online';
      case 'away':
        return 'Ausente';
      default:
        return 'Offline';
    }
  }

  void _handleAction(String action) {
    HapticFeedback.mediumImpact();

    switch (action) {
      case 'like':
        final isLiked = ref.read(
          profileLikeStatusProvider(widget.profile.id),
        )['liked']!;
        if (isLiked) {
          ref.read(profilesProvider.notifier).removeLike(widget.profile.id);
        } else {
          ref.read(profilesProvider.notifier).likeProfile(widget.profile.id);
        }
        break;
      case 'super':
        ref.read(profilesProvider.notifier).superLikeProfile(widget.profile.id);
        break;
      case 'gift':
        ref.read(profilesProvider.notifier).sendGift(widget.profile.id);
        break;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
