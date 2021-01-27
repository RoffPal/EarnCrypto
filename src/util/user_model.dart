import 'sensitive_info.dart' as private;

// This class holds all details for user, e.g balance, referral-balance etc
// I am using MyUser to avoid naming conflict with Telegram User class
class MyUser{
  final id; // this ryhmes with the user's ID on telegram to enhance uniqueness
  String upline; // this is the id of the this user's upline (the user who referred this.user)
  String link;

  double balance = 0.1, refBal = 0, cpc; // referralBalance and (Cost Per Click)
  int referrals = 0;


  MyUser(this.id,{this.upline}): link = private.getUserUniqueID(id);   // Upline is optional because some users might not be referred

  Map<String, dynamic> toMap() => {
    "id":id,
    "upline":upline,
    "balance":balance,
    "cpc":cpc,
    "referrals":referrals,
    "refBal":refBal,
    "link": link
    };
}
