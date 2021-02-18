import 'dart:convert';
import 'package:teledart/model.dart';

import 'sensitive_info.dart' as private;
import 'package:http/http.dart' as http;
import '../main.dart' as main;
import 'user_model.dart';

final RELOADLY_AUDIENCE = "https://topups-sandbox.reloadly.com";

class Airtime {
  static int expiry, timeTokenGenerated;
  static String token;
  static Map<String, String> headers;

  static Future<void> getToken() {
    Map<String, String> header = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };

    dynamic body = "{\"client_id\": \"${private.RELOADLY_CLIENT_ID}\"," +
        "\"client_secret\": \"${private.RELOADLY_API_SECRET}\"," +
        "\"grant_type\": \"client_credentials\",\"audience\": \"${RELOADLY_AUDIENCE}\"\n}";
    if (token == null ||
        DateTime.now().millisecondsSinceEpoch - timeTokenGenerated >= expiry)
      return http
          .post("https://auth.reloadly.com/oauth/token",
              headers: header, body: body)
          .then((value) {
        token = JsonDecoder().convert(value.body)["access_token"];
        expiry = JsonDecoder().convert(value.body)["expires_in"];
        timeTokenGenerated = DateTime.now().millisecondsSinceEpoch;
        headers = {
          'Accept': 'application/com.reloadly.topups-v1+json',
          'Authorization': 'Bearer $token'
        };
      });
  }

  Future<dynamic> getBalance() async {
    await getToken();
    return http
        .get("$RELOADLY_AUDIENCE/accounts/balance", headers: headers)
        .then((value) => JsonDecoder().convert(value.body));
  }

  static Future<void> determineOperator(
      TeleDartMessage event, dynamic details) async {
    await getToken();
    http
        .get(
            "$RELOADLY_AUDIENCE/operators/auto-detect/phone/${event.text}/countries/NG?&includeBundles=true",
            headers: headers)
        .then((value) async {
      dynamic air = JsonDecoder().convert(value.body);
      int fx = await main.firebasedb.get("${main.DB_PATH}/FX-rate.json");
      event.reply(
          'Are you sure you want to send *\$${double.parse(details["amount"]).toStringAsFixed(2)}* Worth of  *${air["name"].split(" ")[0]} Top Up*  to *"${event.text}"*?\n\nFX rate: *$fx / \$1.00*',
          reply_markup: ReplyKeyboardMarkup(keyboard: [
            [
              KeyboardButton(text: "✅ Confirm"),
              KeyboardButton(text: main.cancel)
            ]
          ], resize_keyboard: true),
          parse_mode: "markdown");
      main.patch(main.awaitingWithdrawalDB, event.from.id, {
        "address": event.text
      }); // Adds withdrawal address to the awaiting database
      main.patch(main.awaitingWithdrawalDB, event.from.id,
          {'type': air['id'], 'fx': fx});
    });
  }

  static Future<void> topUpNumber(
      TeleDartMessage event, dynamic details) async {
    await getToken();
    // To finalize Top Up
    String dailCode = '234';
    String number = (details['address'].length == 11)
        ? dailCode.padRight(
            dailCode.length + 1, details['address'].substring(1))
        : details['address'];

    dynamic header = {
      'Content-Type': 'application/json',
      'Accept': 'application/com.reloadly.topups-v1+json',
      'Authorization': 'Bearer $token'
    };

    dynamic body = '''
{
  "recipientPhone": {
    "countryCode": "NG",
    "number": $number
  },
  "senderPhone": {
    "countryCode": "US",
    "number": "234836791612" 
  },
  "operatorId": ${details['type']},
  "amount": ${(double.parse(details['amount']) * details['fx']).toString()}
}''';

    print('${double.parse(details['amount']) * details['fx']}');
    http
        .post('$RELOADLY_AUDIENCE/topups', headers: header, body: body)
        .then((value) async {
      dynamic response = JsonDecoder().convert(value.body);
      if (response.keys.contains('errorCode') ||
          response.keys.contains('error'))
        event.reply('${response['message']}\n\n*Please retry again.*',
            parse_mode: 'markdown', reply_markup: main.showMainMenu());
      else {
        main.deleteFromDatabase(main.awaitingWithdrawalDB, event.from.id);
        var balance = await main
            .getDetail(main.userDB, event.from.id)
            .then((value) => MyUser.fromJson(value).balance);
        main.patch(main.userDB, event.from.id,
            {'balance': balance - double.parse(details['amount'])});
        event.reply('Successful🤑',
            parse_mode: 'markdown', reply_markup: main.showMainMenu());
      }
    });
  }
}

class Crypto {
  static Future<void> sendCoins(TeleDartMessage event, dynamic details) {
    // Still yet to implement
  }
}
