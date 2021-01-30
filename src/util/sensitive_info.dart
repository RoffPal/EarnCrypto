import 'dart:math';

String hi = "🚀 Upgrade", reminder = "guy....... implement the reminder shit";

final BOT_NAME = "EarnCrypto";
final BOT_USERNAME = "earn_BCHbot";
final TELEGRAM_BOT_TOKEN = "1518165141:AAHA6giT4q4TQEKaa4p22DicOERjkETuzzw";
final FIREBASE_PATH = "https://cryptofx-0-default-rtdb.firebaseio.com";
final RELOADLY_CLIENT_ID = "Oh8L6vawsDH3HP3v8ZFjLo4oMz5KpmFr";
final RELOADLY_API_SECRET =
    "2dA60YbgnE-zjNzahuu5bFR0KwO5xm-RcqVQ9FtmEgvtvXjvR42c8f7IL7X2gbV";
final double MIN_WITHDRAWAL = 0.1;

String welcomeMsg(String name) =>
    "Welcome *$name* 🔥\n\nI'm *${BOT_NAME}*, I pay you for completing simple tasks and watching short Videos.\n\nClick *📊 Tasks* to earn by completing tasks\nClick *📺 Short Videos* to earn by watching video ads\n\nYou can also create your own ads with /newad.";

String rCheck(dynamic downlines, dynamic refBal, dynamic link) =>
    "You have *$downlines* referrals, and earned \$*${refBal}0*.\n\nTo refer people, send them to:\n\n[https://t.me/$BOT_USERNAME?start=$link](https://t.me/$BOT_USERNAME?start=$link)\n\nYou will earn *10%* of each user's earnings from tasks and short Videos";

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
