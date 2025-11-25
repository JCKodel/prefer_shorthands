void main() {
  displayAvatar(() => randomUser ?? User.defaultUser);
  display(randomUser ?? User.defaultUser);
}

void displayAvatar(UserAvatar Function() avatarBuilder) {}
void display(UserAvatar avatar) {}
UserAvatar getAvatar() => randomUser ?? User.defaultUser;
UserAvatar getAvatar2() {
  return randomUser ?? User.defaultUser;
}

class User with UserAvatar {
  const User({required this.avatar});

  static const defaultUser = User(avatar: 'default');

  @override
  final String avatar;
}

mixin UserAvatar {
  String get avatar;
}

User? get randomUser => null;
