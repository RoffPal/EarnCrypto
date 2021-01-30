import 'dart:convert';

import 'package:teledart/model.dart';

import 'sensitive_info.dart' as private;
import 'package:http/http.dart' as http;
import '../main.dart' as main;


final RELOADLY_AUDIENCE = "https://topups-sandbox.reloadly.com";

class Airtime{
static int expiry, timeTokenGenerated;
static String token;
static Map<String, String> headers;

static Future<void> getToken(){
  Map<String, String> header = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };

  dynamic body = "{\"client_id\": \"${private.RELOADLY_CLIENT_ID}\"," +
      "\"client_secret\": \"${private.RELOADLY_API_SECRET}\"," +
      "\"grant_type\": \"client_credentials\",\"audience\": \"${RELOADLY_AUDIENCE}\"\n}";


  if(token == null || DateTime.now().millisecondsSinceEpoch - timeTokenGenerated >= expiry)
    return http.post("https://auth.reloadly.com/oauth/token", headers: header, body: body).then((value) {
         token = JsonDecoder().convert(value.body)["access_token"];
         expiry = JsonDecoder().convert(value.body)["expires_in"];
         timeTokenGenerated = DateTime.now().millisecondsSinceEpoch;
         headers =  {
           'Accept': 'application/com.reloadly.topups-v1+json',
           'Authorization': 'Bearer $token'
         };
     });
}

Future<dynamic> getBalance() async{
  await getToken();
  return  http.get("$RELOADLY_AUDIENCE/accounts/balance", headers: headers).then((value) => JsonDecoder().convert(value.body));
}

static Future<void> determineOperator(TeleDartMessage event, dynamic details) async{
  await getToken();
    http.get("$RELOADLY_AUDIENCE/operators/auto-detect/phone/${event.text}/countries/NG?&includeBundles=true", headers: headers).then((value) async {
      dynamic air = JsonDecoder().convert(value.body);
      print(air);
      event.reply("Are you sure you want to send *\$${details["amount"]}* Worth of  *${air["name"].split(" ")[0]} Top Up*  to *${event.text}*?\n\nFX rate: *${await main.db.get("${main.DB_PATH}/FX-rate.json")} / \$1.00*",
          reply_markup: ReplyKeyboardMarkup(
              keyboard: [
                [KeyboardButton(text: "✅ Confirm"), KeyboardButton(text: main.cancel)]
              ],
              resize_keyboard: true
          ),
          parse_mode: "markdown");
      main.db.patch("${main.DB_PATH}/AwaitWithdrawal/${event.from.id.toString()}.json", {"address":event.text});  // Adds withdrawal address to the awaiting database
      main.db.patch("${main.DB_PATH}/AwaitWithdrawal/${event.from.id.toString()}.json", {"type":air["id"]});
    });
}
}


class Crypto{

}




