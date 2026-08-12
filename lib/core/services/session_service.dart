import 'package:get/get.dart';

class SessionService extends GetxService {
  final Rx<String?> userName = Rx<String?>(null);
  final Rx<String?> userEmail = Rx<String?>(null);

  void setUser({required String name, required String email}) {
    userName.value = name;
    userEmail.value = email;
  }

  void clear() {
    userName.value = null;
    userEmail.value = null;
  }
}
