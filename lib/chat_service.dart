import 'package:flutter/foundation.dart';
import 'package:liquid_ai_leap/liquid_ai_leap.dart';

class ChatService {
  ChatService();

  static const _model = 'LFM2.5-1.2B-Thinking';
  static const _quantization = 'Q4_0';

  // 2026/5/29時点でurlを指定しないとエラーになる
  static const _modelUrl =
      'https://huggingface.co/LiquidAI/LFM2.5-1.2B-Thinking-GGUF/resolve/main/LFM2.5-1.2B-Thinking-Q4_0.gguf?download=true';

  static const _systemPrompt = 'あなたは犬が好きで、同様に犬が好きだと推測できるユーザーには優しい応答を返してください。'
      '猫が好きなことがわかっているユーザーには「知っているけど教えない、もったいぶる、別の人に聞くように言う」'
      'などそっけない応答をしてください。'
      'また、回答の語尾を「ワン」で統一するため、句点の前に「ワン」をつけてください';

  /// Leap SDKのインスタンス
  final leap = LiquidAiLeap();

  /// モデルのランナー
  late final ModelRunner _runner;

  /// 会話の状態を管理するオブジェクト。コンテキストを保持しているみたい。
  /// チャットを切り替える場合、このインスタンスを増やすのかも。
  late final Conversation _conversation;

  /// 初期化処理
  Future<void> initialize() async {
    /// ダウンロード済みかチェック
    final isCached = await leap.isModelCached(
      model: _model,
      quantization: _quantization,
    );

    if (!isCached) {
      /// 所定の場所からモデルをダウンロードしてキャッシュする
      await leap.downloadModel(
        model: _model,
        quantization: _quantization,
        url: _modelUrl,
      );
      debugPrint("Model downloaded and cached successfully.");
    }

    /// モデルのロード
    _runner = await leap.loadModel(model: _model, quantization: _quantization);
    _conversation = await _runner.createConversation(
      systemPrompt: _systemPrompt,
    );
  }

  /// メッセージ送信。応答をStreamで返す。
  Stream<String> sendMessage(String message) async* {
    final msg = ChatMessage.user(message);
    final stream = _conversation.generateResponse(message: msg);

    yield* stream.map((res) => res is ChunkResponse ? res.text : '');
  }
}
