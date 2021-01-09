import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';

void main() {
  var teledart = TeleDart(Telegram('1521485998:AAENG6jUxU0gPITHe_5v62qOuGDxt56pYJE'), Event());

  teledart.start().then((me) => print('${me.username} is initialised'));

  teledart
      .onMessage(keyword: 'Fight for freedom')
      .listen((message) => message.reply('Ori E ti baje'));

  print("reached last line");

}