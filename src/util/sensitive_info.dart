import 'dart:math';

import 'package:teledart/model.dart';

String hi = "➕ Deposit", reminder = "guy....... implement the reminder shit";

User bot;
final TELEGRAM_BOT_TOKEN = "1674002102:AAF8cDeVCiI_o2TG1r3BiSVnxXZlEaL5u4A";
final FIREBASE_PATH = "https://cryptofx-0-default-rtdb.firebaseio.com";
final RELOADLY_CLIENT_ID = "Oh8L6vawsDH3HP3v8ZFjLo4oMz5KpmFr";
final RELOADLY_API_SECRET =
    "2dA60YbgnE-zjNzahuu5bFR0KwO5xm-RcqVQ9FtmEgvtvXjvR42c8f7IL7X2gbV";
final MIN_WITHDRAWAL = 0.1;

String welcomeMsg(String name) =>
    "Hi *$name*🔥\n\nWelcome to *${bot.first_name} BOT* 🚀\n__Earn Instant Rewards!__\n\n🔹 Earn by completing tasks  *🛠 Tasks*\n🔹 Earn by watching video ads  *📺 Short Videos*\n\nYou can also place your own ads with /newad and generate more traffic to your business\n\nUse the /help command for more info.";

String rCheck(dynamic downlines, double refBal, dynamic link) =>
    "*👬 REFERRAL SYSTEM*\n\nYou have *$downlines* referrals, and earned \$*${refBal.toStringAsFixed(2)}*.\n\nReferral Link:\n[https://t.me/${bot.username}?start=$link](https://t.me/${bot.username}?start=$link)\n\nYou earn *10%* from your referral earnings";

String bCheck(dynamic balance) => "Available Balance: *\$$balance* ";

String getUserUniqueID(int passedID) {
  String id = passedID.toString();
  String uniqueID = "";

  for (int i = 0; i < id.length; i++)
    uniqueID =
        "$uniqueID${Random().nextBool() ? alpha[int.parse(id[i])].toUpperCase() : alpha[int.parse(id[i])]}";

  return uniqueID;
}

String resolveUniqueID(String passedID) {
  passedID = passedID.toLowerCase();
  String resolvedID = "";

  for (int i = 0; i < passedID.length; i++)
    resolvedID = "$resolvedID${alpha.indexOf(passedID[i])}";

  return resolvedID;
}

List<String> alpha = [
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z",
];
