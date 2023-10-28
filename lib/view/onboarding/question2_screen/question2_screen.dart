import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kanpai/components/select_option.dart';
import 'package:kanpai/view/onboarding/onboarding_layout.dart';
import 'package:kanpai/view/onboarding/question2_screen/tech_area.dart';
import 'package:kanpai/view/onboarding/question3_screen/question3_screen.dart';

class Question2Screen extends HookConsumerWidget {
  const Question2Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techArea = useState<TechArea?>(null);

    return OnboardingLayout(
      title: "好き・得意な領域は？",
      hide: techArea.value == null,
      onNextPressed: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const Question3Screen()));
      },
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: TechArea.values.map((item) {
            final isSelected = techArea.value == item;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectOption(
                isSelected: isSelected,
                onSelected: () {
                  techArea.value = item;
                },
                child: Text(item.label),
              ),
            );
          }).toList()),
    );
  }
}
