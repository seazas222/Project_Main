import 'package:flutter/foundation.dart';
import '../models/user.dart';

class CurrentUserService extends ChangeNotifier {
  static final CurrentUserService instance = CurrentUserService._();

  CurrentUserService._();

  User? _user;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}