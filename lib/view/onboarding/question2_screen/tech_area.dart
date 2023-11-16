import 'package:flutter/material.dart';

extension ColorExt on Color {
  String toCustomString() {
    return 'color($red,$green,$blue)';
  }
}

enum TechArea {
  frontend('フロントエンド', Color(0xfff03e3e)),
  backend('バックエンド', Color(0xfff76707)),
  infra('インフラ', Color(0xffae3ec9)),
  hardware('ハードウェア', Color(0xff7048e8)),
  designer('デザイナー', Color(0xff1c7ed6)),
  other('その他', Color(0xff37b24d));

  const TechArea(this.displayName, this.color);

  final String displayName;
  final Color color;

  factory TechArea.fromName(String name) {
    switch (name) {
      case 'フロントエンド':
        return TechArea.frontend;
      case 'バックエンド':
        return TechArea.backend;
      case 'インフラ':
        return TechArea.infra;
      case 'ハードウェア':
        return TechArea.hardware;
      case 'デザイナー':
        return TechArea.designer;
    }
    return TechArea.other;
  }
}
