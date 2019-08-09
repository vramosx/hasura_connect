class User {
  int userId;

  User({this.userId});

  User.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  Map<String, dynamic>();
    data['user_id'] = this.userId;
    return data;
  }
}
