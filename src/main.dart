import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:firebase/firebase_io.dart';
import 'util/sensitive_info.dart' as private;
import 'util/user_model.dart';
import 'util/payment.dart' as pay;
import 'package:path/path.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

final DB_PATH = private.FIREBASE_PATH;
final BOT_TOKEN = private.TELEGRAM_BOT_TOKEN;
final bot = Telegram(BOT_TOKEN);
final firebasedb = FirebaseClient.anonymous();
final store = StoreRef.main();
Database userDB;
Database awaitingWithdrawalDB;
TeleDart teledart;

String balance = "💰 Balance",
    task = "🛠 Tasks",
    sVid = "📺 Video Ads",
    referrals = "👬 Referrals",
    pp = "🕐 Payment Proof",
    withdraw = "💵 Withdraw",
    back = "🔝 Main Menu",
    cancel = "❌ Cancel",
    ads = "📊 Place Ads";

void main() {
  initialize();

  // When User wants to withdraw with airtime
  teledart.onPhoneNumber().listen((event) async {
    dynamic withdrawalDetails =
        await getDetail(awaitingWithdrawalDB, event.from.id);

    if (withdrawalDetails != null &&
        withdrawalDetails["amount"] !=
            null) if (withdrawalDetails["address"] == null)
      await dealWithPaymentAddress(event, withdrawalDetails);
    else
      event.reply(
          "Please confirm or /cancel the the pending withdrawal request.");
  });

  // Command Listener
  teledart.onCommand().listen((event) async {
    commandReceived(event);
  });

// Message Listener
  teledart.onMessage().listen((event) async {
    event.text != null ? messageReceived(event) : null;
  });

  teledart.onCallbackQuery().listen((event) {
    if (event.data.length > 1) {
      // prevents double specifing withdrawal on if user clicks the inline button of SELECTED PAYMENT MODE
      specifyWithdrawal(event);
    }
  });
}

Future<void> dealWithWithdrawal(TeleDartMessage event,
    {String withdrawAmount}) async {
  var user = MyUser.fromJson(await getDetail(userDB, event.chat.id));

  if (withdrawAmount != null) {
    try {
      double withdrawAmountd = double.parse(withdrawAmount);
      if (withdrawAmountd <= user.balance) {
        if (withdrawAmountd < private.MIN_WITHDRAWAL)
          event.reply(
              "\$*${event.text}* is lower than the minimum withdrawal\n\nMinimum Withdrawal: \$*${private.MIN_WITHDRAWAL.toStringAsFixed(2)}*\n\nInput Amount To Withdraw again. 👇",
              parse_mode: "markdown");
        else {
          patch(awaitingWithdrawalDB, event.from.id,
              {"amount": withdrawAmount}); // Specify Amount to Withdraw
          event.reply("Please Select A Withdrawal Method:",
              parse_mode: "markdown",
              reply_markup: InlineKeyboardMarkup(inline_keyboard: [
                [
                  InlineKeyboardButton(
                      text: "Airtime", callback_data: "airtime")
                ],
                [
                  InlineKeyboardButton(
                      text: "BitcoinCash (BCH)",
                      callback_data: "Bitcoin Cash (BCH)")
                ],
              ]));
        }
      } else
        event.reply(
            "Insufficient Fund\n\nYour Available balance is *\$${user.balance.toStringAsFixed(2)}*\nUse /max to withdraw your total balance\n\nInput Amount To Withdraw again. 👇",
            parse_mode: "markdown");
    } catch (FormatException) {
      event.reply("Please input a valid number!");
    }
  } else if (user.balance >= private.MIN_WITHDRAWAL) {
    store
        .record(event.from.id)
        .add(awaitingWithdrawalDB, {"type": "Initiated Withdrawal"});
    event.reply(
        "Click /max to withdraw total balance\n                      *OR*\nInput Amount To Withdraw. 👇\n\nMinimum: *\$${private.MIN_WITHDRAWAL.toStringAsFixed(2)}*",
        parse_mode: "markdown",
        reply_markup: ReplyKeyboardMarkup(keyboard: [
          [KeyboardButton(text: cancel)],
        ], resize_keyboard: true));
  } else
    event.reply(
        "Your Available balance is lower than the minimum withdrawal.\n\nAvailable balance:  \$${user.balance.toStringAsFixed(2)}\n\nMinimum withdrawal: \$${private.MIN_WITHDRAWAL.toStringAsFixed(2)}");
} // Places User ID in the database to inidicate a withdrawal has been initiated and asks for amount to Withdraw

void specifyWithdrawal(CallbackQuery event) {
  bot.editMessageText("*Selected Withdrawal Method*✅",
      parse_mode: "markdown",
      chat_id: event.message.chat.id,
      message_id: event.message.message_id,
      reply_markup: InlineKeyboardMarkup(inline_keyboard: [
        [
          InlineKeyboardButton(
              text: "✅ ${event.data.toUpperCase()}", callback_data: "i")
        ]
      ]));
  patch(awaitingWithdrawalDB, event.from.id, {"type": event.data});

  // You can create a method to request for specific address if payment is more dan jst bch and airtime
  Future.delayed(
      Duration(seconds: 1),
      () => bot.sendMessage(
          event.message.chat.id,
          event.data.contains("BCH")
              ? "Input your Bitcoin Cash address: 👇"
              : "Input the mobile number to top up: 👇"));
}

void dealWithPaymentAddress(TeleDartMessage event, dynamic withdrawalDetails) {
  switch (withdrawalDetails["type"]) {
    case "Bitcoin Cash (BCH)":
      if (event.text.length < 15)
        event.reply("The Bitcoin Cash address you entered is invalid");
      else
        event.reply(
            "Are you sure you want to send ${withdrawalDetails["amount"]} worth of *BCH* to ${event.text}?\n\nFX rate is blah blah blah",
            reply_markup: ReplyKeyboardMarkup(keyboard: [
              [KeyboardButton(text: "✅ Confirm"), KeyboardButton(text: cancel)]
            ], resize_keyboard: true),
            parse_mode: "markdowm");
      patch(awaitingWithdrawalDB, event.from.id, {
        "address": event.text
      }); // Adds withdrawal address to the awaiting database
      break;
    default:
      pay.Airtime.determineOperator(event, withdrawalDetails);
  }
} // Determines where to send payment to

void registerUser(TeleDartMessage event) async {
  int userID = event.from.id;
  String msg = event.text;
  var ref = msg.split(" ").length > 1
      ? msg.split(" ")[1]
      : null; // Holds reference to the Id of the upline if /start carries along a parameter

// Here Ensures that a user never gets registered twice by first checking to see if the user already exits
  if (await getDetail(userDB, userID) == null) {
    if (ref != null) {
      // Deals with making sure the upline gets its count of referrals updated
      ref = private.resolveUniqueID(ref);
      dynamic upline = await getDetail(userDB, int.parse(ref));

      int cReferralsofUpline =
          upline["referrals"]; // current number of referrals of upline
      patch(userDB, int.parse(ref), {"referrals": ++cReferralsofUpline});
    }

    store
        .record(event.from.id)
        .add(userDB, MyUser(userID, upline: ref).toMap());
  } else
    print("User is already registered");
} // Registers new Users into the database

Future<dynamic> getDetail(Database db, int userID) =>
    store.record(userID).get(db);
Future<dynamic> deleteFromDatabase(Database db, dynamic toDelete) =>
    store.record(toDelete).delete(db);

Future<dynamic> patch(
        Database db, int userID, Map<dynamic, dynamic> changeTo) =>
    store.record(userID).update(db, changeTo);

Future<void> dealWithReferral(TeleDartMessage event) async {
  var user = await getDetail(userDB, event.chat.id); // looks too complex
  String r = private.rCheck(user["referrals"], user["refBal"], user["link"]);
  event.reply(
    r,
    parse_mode: "markdown",
  );
}

Future<void> showBalance(TeleDartMessage event) async {
  var user = MyUser.fromJson(await getDetail(userDB, event.chat.id));
  String b = private.bCheck(user.balance.toStringAsFixed(2));
  event.reply(b, parse_mode: "markdown", reply_markup: showBalanceMenu());
}

ReplyMarkup showMainMenu() => ReplyKeyboardMarkup(keyboard: [
      [KeyboardButton(text: task), KeyboardButton(text: sVid)],
      [
        KeyboardButton(text: balance),
        KeyboardButton(text: referrals),
        KeyboardButton(text: ads)
      ],
      [KeyboardButton(text: pp)]
    ], resize_keyboard: true);
ReplyMarkup showBalanceMenu() => ReplyKeyboardMarkup(keyboard: [
      [KeyboardButton(text: private.hi), KeyboardButton(text: withdraw)],
      [KeyboardButton(text: back)]
    ], resize_keyboard: true);

void initialize() {
  teledart = TeleDart(bot, Event());
  teledart.start().then((me) {
    print('${me.username} is initialised');
    private.bot = me;
  });

  databaseFactoryIo.openDatabase(join("Database", "Users.db")).then((value) {
    userDB = value;
  });
  databaseFactoryIo
      .openDatabase(join("Database", "awaitingWithdrawal.db"))
      .then((value) {
    awaitingWithdrawalDB = value;
  });
}

Future commandReceived(TeleDartMessage event) async {
  // checks if User already has a pending Withdrawal
  dynamic withdrawalDetails =
      await getDetail(awaitingWithdrawalDB, event.from.id);

  if (withdrawalDetails != null) {
    if (event.text.contains("cancel")) {
      event.reply("Withdrawal has been Cancelled",
          reply_markup: showBalanceMenu());
      await store.record(event.from.id).delete(awaitingWithdrawalDB);
    } else if (event.text.contains("max") &&
        withdrawalDetails["amount"] == null)
      dealWithWithdrawal(event,
          withdrawAmount:
              (await getDetail(userDB, event.from.id))["balance"].toString());
    else
      event.reply(
          "Please Complete Withdrawal or Click /cancel to Stop the Process");
  }

  // On_Start Command
  else if (event.text.contains("start")) {
    print("UserID: ${event.from.id} And chatID: ${event.chat.id}");
    event.reply(private.welcomeMsg(event.from.first_name),
        parse_mode: "markdown", reply_markup: showMainMenu());
    registerUser(event);
  }

  // On referral command
  else if (event.text.contains(referrals.split(" ")[1].substring(1)))
    dealWithReferral(event);

  // On balance command
  else if (event.text.contains(balance.split(' ')[1].substring(1)))
    showBalance(event);

  // On withdraw command
  else if (event.text.contains(withdraw.split(' ')[1].substring(1)))
    dealWithWithdrawal(event);

  // On back or main command
  else if (event.text.contains(back.split(' ')[1].substring(1))) {
    event.reply(private.reminder,
        parse_mode: 'markdown', reply_markup: showMainMenu());
  } else
    event.reply(
      'I do not understand this command.\n\nClick the /help command to get all my available commands.',
    );
}

Future messageReceived(TeleDartMessage event) async {
  print('got the message: ${event.text}');
  dynamic withdrawalDetails =
      await getDetail(awaitingWithdrawalDB, event.from.id);

  if (withdrawalDetails != null) {
    if (event.text.contains(cancel.split(' ')[1].substring(1))) {
      event.reply('Withdrawal has been Cancelled',
          reply_markup: showBalanceMenu());
      await deleteFromDatabase(awaitingWithdrawalDB, event.from.id);
    } else if (withdrawalDetails['amount'] == null)
      dealWithWithdrawal(event,
          withdrawAmount: event.text); // Tries to get amount from User
    else if (withdrawalDetails['type'] == 'Initiated Withdrawal')
      event.reply(
          'Please Select a Withdrawal Method Above. 👆\n\nOr Click /cancel to Stop Withdrawal');
    else if (withdrawalDetails['address'] == null) {
      if (withdrawalDetails['type'] == 'airtime')
        event.reply('You entered an invalid number');
    } else if (event.text.contains('Confirm')) {
      deleteFromDatabase(awaitingWithdrawalDB, event.from.id);
      switch (withdrawalDetails['type']) {
        case '':
          pay.Crypto.sendCoins(event, withdrawalDetails);
          break;
        default:
          pay.Airtime.topUpNumber(event, withdrawalDetails);
      }
    } else
      event.reply(
          'Please complete or /cancel the the ongoing withdrawal request.');
  }

  // On referral message
  else if (event.text.contains(referrals.split(" ")[1].substring(1)))
    dealWithReferral(event);

  // On balance message
  else if (event.text.contains(balance.split(" ")[1].substring(1)))
    showBalance(event);

  // On withdraw message
  else if (event.text.contains(withdraw.split(" ")[1].substring(1)))
    dealWithWithdrawal(event);

  // On back or main menu message
  else if (event.text.contains(back.split(" ")[1].substring(1))) {
    event.reply(private.reminder,
        parse_mode: "markdown", reply_markup: showMainMenu());
  }
}
// {}   []
