import 'dart:io';

import 'package:flutter/material.dart';

GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();


Future<Directory> getDownloadsDir() async {
  final userProfile = Platform.environment['USERPROFILE'];

  if (userProfile == null) {
    throw Exception('USERPROFILE не найден');
  }

  return Directory('$userProfile\\Downloads');
}