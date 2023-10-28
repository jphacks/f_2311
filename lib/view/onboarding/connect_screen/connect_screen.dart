import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kanpai/view/onboarding/onboarding_layout.dart';
import 'package:kanpai/view_models/connect_view_model.dart';

class ConnectScreen extends HookConsumerWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnecting = ref.watch(connectViewModelProvider).isConnecting;
    final viewmodel = ref.watch(connectViewModelProvider.notifier);
    final hasError = ref.watch(connectViewModelProvider).hasError;

    return OnboardingLayout(
      title: hasError ? "接続に失敗しました" : "接続を開始しますか？",
      // TODO: 注意書きがあれば追加
      // description: "注意書き",
      loading: isConnecting,
      nextLabel: isConnecting ? "接続中..." : "接続を開始",
      onNextPressed: () async {
        final connectedDevice = await viewmodel.connect();
        // connectedDevice を渡して画面遷移する
      },
      child: SizedBox(
        height: double.infinity,
        child: Center(
          child: Image.asset('assets/images/cup-image.png'),
        ),
      ),
    );
  }
}
