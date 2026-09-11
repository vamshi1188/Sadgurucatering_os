import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

class PersistentCookieStorage {
  const PersistentCookieStorage();

  static const String _cookieDirectoryName = 'network_cookies';

  Future<PersistCookieJar> createCookieJar() async {
    final directory = await getApplicationSupportDirectory();
    final cookieDirectory = '${directory.path}/$_cookieDirectoryName';

    return PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage(cookieDirectory),
    );
  }
}
