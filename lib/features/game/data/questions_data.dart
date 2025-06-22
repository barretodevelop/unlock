import 'package:unlock/features/game/models/question_model.dart';

class QuestionsData {
  static final List<QuestionModel> allQuestions = [
    // Perguntas de Interesses Gerais
    QuestionModel(
      id: 'q_music_genre',
      text: 'Qual gênero musical te faz vibrar?',
      options: ['Pop', 'Rock', 'Eletrônica', 'Hip Hop', 'Clássica', 'Outro'],
      type: 'multiple_choice',
      relatedInterests: ['Música'],
    ),
    QuestionModel(
      id: 'q_movie_type',
      text: 'Qual tipo de filme você mais gosta de assistir?',
      options: [
        'Comédia',
        'Ação',
        'Drama',
        'Ficção Científica',
        'Terror',
        'Documentário',
      ],
      type: 'multiple_choice',
      relatedInterests: ['Filmes'],
    ),
    QuestionModel(
      id: 'q_book_preference',
      text: 'Você prefere livros de ficção ou não-ficção?',
      options: ['Ficção', 'Não-ficção', 'Ambos'],
      type: 'multiple_choice',
      relatedInterests: ['Leitura'],
    ),
    QuestionModel(
      id: 'q_sport_activity',
      text: 'Qual atividade física você mais pratica ou gostaria de praticar?',
      options: [
        'Corrida',
        'Natação',
        'Musculação',
        'Yoga',
        'Esportes coletivos',
        'Dança',
      ],
      type: 'multiple_choice',
      relatedInterests: ['Esportes'],
    ),
    QuestionModel(
      id: 'q_cooking_style',
      text: 'Qual sua especialidade na cozinha?',
      options: [
        'Doces',
        'Salgados',
        'Churrasco',
        'Comida Internacional',
        'Não cozinho',
      ],
      type: 'multiple_choice',
      relatedInterests: ['Culinária'],
    ),

    // Perguntas de Estilo de Vida
    QuestionModel(
      id: 'q_social_setting',
      text: 'Você prefere uma festa grande ou um encontro íntimo com amigos?',
      options: ['Festa grande', 'Encontro íntimo', 'Depende do humor'],
      type: 'multiple_choice',
      relatedInterests: ['Festas', 'Cafés'],
    ),
    QuestionModel(
      id: 'q_travel_dream',
      text: 'Qual seu destino de viagem dos sonhos?',
      type: 'text_input',
      relatedInterests: ['Viagens'],
    ),
    QuestionModel(
      id: 'q_game_platform',
      text: 'Qual sua plataforma de jogos favorita?',
      options: ['PC', 'Console', 'Mobile', 'Board Games', 'Não jogo'],
      type: 'multiple_choice',
      relatedInterests: ['Jogos'],
    ),
    QuestionModel(
      id: 'q_pet_preference',
      text: 'Cachorro ou gato?',
      options: ['Cachorro', 'Gato', 'Ambos', 'Nenhum'],
      type: 'multiple_choice',
      relatedInterests: ['Pets'],
    ),

    // Perguntas de Criatividade e Conhecimento
    QuestionModel(
      id: 'q_art_form',
      text: 'Qual forma de arte mais te atrai?',
      options: [
        'Pintura',
        'Escultura',
        'Música',
        'Dança',
        'Literatura',
        'Fotografia',
      ],
      type: 'multiple_choice',
      relatedInterests: ['Arte', 'Fotografia'],
    ),
    QuestionModel(
      id: 'q_tech_interest',
      text: 'Qual tecnologia você acha mais fascinante atualmente?',
      type: 'text_input',
      relatedInterests: ['Tecnologia'],
    ),
    QuestionModel(
      id: 'q_nature_activity',
      text: 'Qual sua atividade favorita ao ar livre?',
      options: [
        'Caminhada',
        'Piquenique',
        'Observar estrelas',
        'Jardinagem',
        'Acampar',
      ],
      type: 'multiple_choice',
      relatedInterests: ['Natureza'],
    ),
    QuestionModel(
      id: 'q_writing_style',
      text: 'Você prefere escrever contos, poemas ou artigos?',
      options: ['Contos', 'Poemas', 'Artigos', 'Não escrevo'],
      type: 'multiple_choice',
      relatedInterests: ['Escrita'],
    ),

    // Perguntas de Bem-Estar e Desenvolvimento Pessoal
    QuestionModel(
      id: 'q_stress_relief',
      text: 'Como você relaxa depois de um dia estressante?',
      type: 'text_input',
      relatedInterests: ['Yoga', 'Relaxar'],
    ),
    QuestionModel(
      id: 'q_personal_goal',
      text: 'Qual um objetivo pessoal que você está buscando alcançar?',
      type: 'text_input',
      relatedInterests: ['Objetivos', 'Carreira'],
    ),
    QuestionModel(
      id: 'q_fashion_style',
      text: 'Qual estilo de moda mais te representa?',
      type: 'text_input',
      relatedInterests: ['Moda'],
    ),
  ];
}
