import 'dart:io';

import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';

void main() {

  var teledart = TeleDart(Telegram(Platform.environment["BOT_TOKEN"]), Event());

  teledart.start().then((me) => print('${me.username} is initialised'));

  teledart
      .onMessage(keyword: 'Fight for freedom')
      .listen((message) => message.reply('Ori E ti baje'));

  print(Platform.environment["BOT_TOKEN"]);

}