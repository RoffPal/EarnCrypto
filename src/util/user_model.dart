import 'sensitive_info.dart' as private;

// This class holds all details for user, e.g balance, referral-balance etc
// I am using MyUser to avoid naming conflict with Telegram User class
class MyUser {
  int id; // this ryhmes with the user's ID on telegram to enhance uniqueness
  String
      upline, // this is the id of the this user's upline (the user who referred this.user)
      link;

  double balance = 0.10,
      refBal = 0,
      rewardPercent = 1; // referralBalance and (Cost Per Click)
  int referrals = 0;

  MyUser.fromJson(dynamic db) {
    id = db["id"];
    upline = db["upline"];
    balance = db["balance"];
    rewardPercent = db["%"];
    referrals = db["referrals"];
    refBal = db["refBal"];
    link = db["link"];
  }

  MyUser(this.id, {this.upline})
      : link = private.getUserUniqueID(
            id); // Upline is optional because some users might not be referred

  Map<String, dynamic> toMap() => {
        "id": id,
        "upline": upline,
        "balance": balance,
        "%": rewardPercent,
        "referrals": referrals,
        "refBal": refBal,
        "link": link
      };
}
