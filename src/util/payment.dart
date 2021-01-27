import 'dart:convert';

import 'sensitive_info.dart' as private;
import 'package:http/http.dart' as http;



String access_token = private.changeableAccessToken;  // Today's Token.........would later expire
final RELOADLY_AUDIENCE = "https://topups-sandbox.reloadly.com";



class Airtime{
static int expiry, timeTokenGenerated;
static String token;
static Map<String, String> headers;

Future<void> getToken(){
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

Future<String> getOperatorsOFCountry(String isoCode) async{
  await getToken();
  return http.get("$RELOADLY_AUDIENCE/operators/countries/$isoCode", headers: headers).then((value) => value.body);
}

}




