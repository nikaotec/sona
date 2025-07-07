import 'dart:convert';
import 'package:dio/dio.dart';
import '../model/onboarding_model.dart';

class OpenAIService {
  final Dio _dio = Dio();
  
  // IMPORTANTE: Substitua pela sua chave da API OpenAI
  static const String _apiKey = 'SUA_CHAVE_OPENAI_AQUI';
  static const String _baseUrl = 'https://api.openai.com/v1';

  OpenAIService() {
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
  }

  Future<String> generateRecommendation(OnboardingData data) async {
    try {
      final prompt = _buildPrompt(data);
      
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Você é um terapeuta digital especializado em recomendações personalizadas de trilhas sonoras e técnicas de relaxamento. Suas respostas devem ser empáticas, acolhedoras e personalizadas.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return content.toString().trim();
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw Exception('Chave da API inválida. Verifique sua configuração.');
        } else if (e.response?.statusCode == 429) {
          throw Exception('Limite de requisições excedido. Tente novamente em alguns minutos.');
        }
      }
      throw Exception('Erro ao conectar com a IA: $e');
    }
  }

  String _buildPrompt(OnboardingData data) {
    final objetivoTexto = _getObjetivoTexto(data.objetivo);
    final humorTexto = _getHumorTexto(data.humor);
    final estiloTexto = _getEstiloTexto(data.estilo);
    final horarioTexto = _getHorarioTexto(data.horario);

    return '''
Você é um terapeuta digital que recomenda trilhas sonoras e técnicas de relaxamento personalizadas.

Baseado nas respostas do usuário:
- Objetivo: $objetivoTexto
- Emoção atual: $humorTexto
- Estilo preferido: $estiloTexto
- Horário preferido: $horarioTexto

Crie uma mensagem breve e empática (máximo 150 palavras) recomendando uma trilha sonora ou sessão guiada ideal para ele(a). A recomendação deve parecer personalizada, humana e reconfortante. Termine com uma sugestão de ação específica.

Exemplo de tom:
"Como você está se sentindo ansioso e prefere sons da natureza à noite, criamos uma trilha com chuva suave e flauta para você relaxar e dormir tranquilo."

Fale com proximidade, como se fosse um guia emocional. Use "você" e seja acolhedor.
''';
  }

  String _getObjetivoTexto(String objetivo) {
    switch (objetivo) {
      case 'dormir_melhor':
        return 'Melhorar a qualidade do sono';
      case 'reduzir_ansiedade':
        return 'Reduzir ansiedade';
      case 'focar_estudos':
        return 'Focar nos estudos/trabalho';
      case 'relaxar':
        return 'Relaxar após um dia agitado';
      case 'meditar':
        return 'Meditar com regularidade';
      default:
        return objetivo;
    }
  }

  String _getHumorTexto(String humor) {
    switch (humor) {
      case 'calmo':
        return 'Calmo(a)';
      case 'estressado':
        return 'Estressado(a)';
      case 'ansioso':
        return 'Ansioso(a)';
      case 'cansado':
        return 'Cansado(a)';
      case 'distraido':
        return 'Distraído(a)';
      default:
        return humor;
    }
  }

  String _getEstiloTexto(String estilo) {
    switch (estilo) {
      case 'natureza':
        return 'Sons da natureza (chuva, mar, vento)';
      case 'binaural':
        return 'Batidas suaves (binaural, ASMR)';
      case 'instrumental':
        return 'Música instrumental relaxante';
      case 'voz_guiada':
        return 'Voz suave guiando a meditação';
      case 'nao_sei':
        return 'Não tem certeza ainda';
      default:
        return estilo;
    }
  }

  String _getHorarioTexto(String horario) {
    switch (horario) {
      case 'deitar_dormir':
        return 'Ao deitar para dormir';
      case 'durante_dia':
        return 'Durante o dia (pausa mental)';
      case 'antes_estudar':
        return 'Antes de estudar ou trabalhar';
      case 'ao_acordar':
        return 'Quando acordo';
      case 'tarde_por_sol':
        return 'À tarde ou no pôr do sol';
      default:
        return horario;
    }
  }
}

