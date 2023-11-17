import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kanpai/components/profile_card/profile_card.dart';
import 'package:kanpai/components/tab_button.dart';
import 'package:kanpai/components/user_icon_panel.dart';
import 'package:kanpai/models/user_model.dart';
import 'package:kanpai/util/bluetooth_ext.dart';
import 'package:kanpai/view_models/auth_view_model.dart';
import 'package:kanpai/view_models/kanpai_view_model.dart';

enum KanpaiTab {
  list,
  history,
}

class KanpaiScreen extends HookConsumerWidget {
  KanpaiScreen({
    super.key,
    required this.targetDevice,
  });

  final BluetoothDevice? targetDevice;
  late StreamSubscription<List<int>> _kanpaiSubscription;

  void startKanpaiListener(
    void Function(String fromUserId, String toBleUserId) handler,
  ) async {
    await targetDevice!.connectAndUpdateStream();
    final characteristic = await targetDevice!.getNotifyCharacteristic();
    final fromUserId = fba.FirebaseAuth.instance.currentUser?.uid;
    if (characteristic == null || fromUserId == null) return;

    _kanpaiSubscription = characteristic.lastValueStream.listen((value) {
      print('arrivezvalue: $value');
      if (value.isEmpty) return;

      final toBleUserId = utf8.decode(value);

      debugPrint('cheers occurred from $fromUserId to $toBleUserId');
      handler(fromUserId, toBleUserId);
    });

    await characteristic.setNotifyValue(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final meId = authState.appUser?.id;

    final selectedTab = useState<KanpaiTab>(KanpaiTab.list);

    final homeViewModel = ref.watch(homeViewModelProvider.notifier);
    final users = ref
        .watch(homeViewModelProvider)
        .maybeWhen(data: (data) => data, orElse: () => <User>[]);

    final me = users.where((u) => u.id == meId).firstOrNull;
    final meBleUserId = me?.bleUserId;

    useEffect(() {
      homeViewModel.fetchUsers();
      return () {};
    }, []);

    final kanpaiCount = me?.cheerUserIds?.length ?? 0;

    final alreadyCheersUserCount = useMemoized(
        () => users
            .where((u) => u.cheerUserIds?.contains(meBleUserId) ?? false)
            .length,
        [users, meId]);

    final allUserCount = useMemoized(() => users.length - 1, [users]);

    final latestCheeredUser = useMemoized(() {
      try {
        final latestCheeredUserId =
            me?.cheerUserIds?.lastWhere((id) => id != meBleUserId);
        return users.firstWhere((u) => u.bleUserId == latestCheeredUserId);
      } on StateError catch (_) {
        return null;
      }
    }, [users, meBleUserId]);

    final filteredUsers = useMemoized(() {
      if (selectedTab.value == KanpaiTab.history) {
        final cheerUserIds = me?.cheerUserIds ?? [];

        // 乾杯した回数をカウントする
        final cheerUserIdsCountMap = users
            .where((user) => user.id != meId && user.bleUserId != null)
            .map((user) => user.bleUserId!)
            .fold<Map<String, int>>(
                {}, (map, bleUserId) => {...map, bleUserId: 0});
        for (String bleUserId in cheerUserIds) {
          cheerUserIdsCountMap[bleUserId] =
              (cheerUserIdsCountMap[bleUserId] ?? 0) + 1;
        }

        // 乾杯した回数に応じてソートする
        final sortedCheerUserIds = cheerUserIdsCountMap.entries.toList();
        sortedCheerUserIds.sort((a, b) => b.value.compareTo(a.value));
        return sortedCheerUserIds
            .map((e) => users.firstWhere((user) => user.bleUserId == e.key));
      }
      return users.where((user) => user.id != meBleUserId);
    }, [users, selectedTab.value, meBleUserId, meId]);

    final viewmodel = ref.watch(homeViewModelProvider.notifier);

    useEffect(() {
      if (targetDevice == null) {
        return () {};
      }
      startKanpaiListener(viewmodel.cheers);
      return () => _kanpaiSubscription.cancel();
    }, []);

    final appbar = AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: const Text(
        "JPHACKS 2023",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      leading: IconButton(
        onPressed: () async {
          await targetDevice?.disconnect();
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pop();
        },
        icon: const Icon(
          Icons.arrow_back,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.account_circle_outlined,
            color: Colors.white,
          ),
        )
      ],
    );

    return Scaffold(
        appBar: appbar,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(kanpaiCount == 0
                        ? "assets/images/kanpai-bg-black.png"
                        : "assets/images/kanpai-bg-blue.png"),
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter)),
            child: Padding(
              padding: EdgeInsets.only(
                  top: appbar.preferredSize.height + 30, bottom: 160),
              child: Column(
                children: [
                  const SizedBox(
                    height: 40,
                  ),
                  _buildCounter(kanpaiCount),
                  const SizedBox(
                    height: 20,
                  ),
                  Stack(
                    alignment: AlignmentDirectional.bottomCenter,
                    children: [
                      if (latestCheeredUser != null)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 28),
                          child: ProfileCard(
                            user: latestCheeredUser,
                            hasBottomPadding: true,
                          ),
                        )
                      else
                        const SizedBox(height: 200),
                      Image.asset(
                        "assets/images/partition.png",
                      )
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildTabbar(context,
                            selectedTab: selectedTab,
                            label: "$alreadyCheersUserCount / $allUserCount"),
                        const SizedBox(
                          height: 24,
                        ),
                        if (me != null)
                          _buildUserGrid(context, me: me, users: filteredUsers),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }

  Column _buildCounter(int kanpaiCount) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text("乾杯した総回数",
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text("$kanpaiCount",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontFamily: "Chillax",
                height: 1,
                fontWeight: FontWeight.w600)),
        SvgPicture.asset(
          "assets/svgs/kanpai-logo.svg",
          height: 20,
          theme: const SvgTheme(currentColor: Colors.white),
        ),
      ],
    );
  }

  Row _buildTabbar(BuildContext context,
      {required ValueNotifier<KanpaiTab> selectedTab, required String label}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            TabButton(
                isSelected: selectedTab.value == KanpaiTab.list,
                onSelected: () => selectedTab.value = KanpaiTab.list,
                child: _buildTabButtonText(context,
                    label: "名前",
                    isSelected: selectedTab.value == KanpaiTab.list)),
            const SizedBox(
              width: 4,
            ),
            TabButton(
                isSelected: selectedTab.value == KanpaiTab.history,
                onSelected: () => selectedTab.value = KanpaiTab.history,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTabButtonIcon(selectedTab.value == KanpaiTab.history),
                    _buildTabButtonText(context,
                        label: " した順",
                        isSelected: selectedTab.value == KanpaiTab.history),
                  ],
                )),
          ],
        ),
        Text(label,
            style: const TextStyle(
                fontSize: 24,
                fontFamily: "Chillax",
                fontWeight: FontWeight.w600))
      ],
    );
  }

  Widget _buildUserGrid(BuildContext context,
      {required User me, required Iterable<User> users}) {
    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: SizedBox(
          width: 40,
          child: Image.asset(
            "assets/images/kanpai-1.png",
            width: 100,
            height: 100,
          ),
        ),
      );
    }

    final deviceWidth = MediaQuery.of(context).size.width;

    return Wrap(
        spacing: 16,
        runSpacing: 24,
        children: users.map((user) {
          final cheersCount =
              me.cheerUserIds?.where((id) => id == user.bleUserId).length ?? 0;
          return SizedBox(
              width: (deviceWidth - 60) / 2,
              child: UserIconPanel(
                user: user,
                count: cheersCount,
              ));
        }).toList());
  }

  SvgPicture _buildTabButtonIcon(bool isSelected) {
    return SvgPicture.asset(
      "assets/svgs/kanpai-logo.svg",
      height: 22,
      theme:
          SvgTheme(currentColor: isSelected ? Colors.black87 : Colors.black54),
    );
  }

  Text _buildTabButtonText(BuildContext context,
      {required String label, required bool isSelected}) {
    return Text(label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.black87 : Colors.black54,
            fontWeight: FontWeight.bold));
  }
}
