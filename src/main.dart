import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:firebase/firebase_io.dart';
import 'util/sensitive_info.dart' as private;
import 'util/user_model.dart';



final DB_PATH = private.FIREBASE_PATH;
final BOT_TOKEN = private.TELEGRAM_BOT_TOKEN;
final bot = Telegram(BOT_TOKEN);
FirebaseClient db = FirebaseClient.anonymous();
String bot_username;


void main() {
  var teledart = TeleDart(bot, Event());
  teledart.start().then((me){
    bot_username = me.username;
    print('${me.username} is initialised');
  });


// On_Start Command
  teledart
      .onCommand().listen((event) async {
        await initializeUser(event.from.id, event.text);
        event.reply(private.welcomeMsg(event.from.first_name),
        parse_mode: "markdown",
        reply_markup: private.showMainMenu());
      });


// Button b clicked
  teledart
      .onMessage(keyword: private.b.split(" ")[1].substring(1)).listen((event) async {
        var user = await getUserDetail(event.chat.id);
        event.reply("${private.bCheck}*\$${user[private.b.split(" ")[1].toLowerCase()]}*",
        parse_mode: "markdown",
        reply_markup: private.showBMenu());
  });


// Button r clicked
   teledart
      .onMessage(keyword: private.r.split(" ")[1].substring(1)).listen((event) async {
        dynamic user = await getUserDetail(event.chat.id);    // looks too complex
        String reff = private.rCheck(user[private.r.split(" ")[1].toLowerCase()],user[private.rb],user["link"]);
        event.reply(reff,//private.rCheck(user[private.r.split(" ")[1].toLowerCase()],user[private.rb],user["link"]),
        parse_mode: "markdown",);
  });

}



// Registers new Users into the database
Future<void> initializeUser(int userID, String msg) async{
  var ref = msg.split(" ").length > 1 ? msg.split(" ")[1] : null;  // Holds reference to the Id of the upline in the database  

// Here Ensures that a user never gets registered twice by first checking to see if the user already exits
  if (await db.get("$DB_PATH/Users/$userID.json") == null){      
      if (ref != null){                                           // Deals with making sure the upline gets its count of referrals updated
         ref = private.resolveUniqueID(ref);
         int cReferrals = await db.get("$DB_PATH/Users/$ref.json");
         db.patch("$DB_PATH/Users/$ref.json",{"referrals":"${++cReferrals}"});
      }
      db.put("$DB_PATH/Users.json", {"${userID.toString()}":MyUser(userID, upline: ref).toMap()});
      
     } else
         print("User is already regis5tered");
}

Future<dynamic> getUserDetail(int userID)  =>  db.get("$DB_PATH/Users/$userID.json");



