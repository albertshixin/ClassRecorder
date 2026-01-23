import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ipgpfursfnkwlomqvxxj.supabase.co',
    anonKey: 'sb_publishable_cx3QorGBrCVcnkpQRw7rIA_4tDeU0zC',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  // Handle OAuth redirect on web (exchanges ?code= for a session).
  try {
    await Supabase.instance.client.auth.getSessionFromUrl(Uri.base);
  } catch (_) {
    // Ignore if there is no auth code in the URL.
  }
  runApp(const App());
}
