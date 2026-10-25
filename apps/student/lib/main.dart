Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();




  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    runApp(const SetupRequiredApp());
    return;
  }
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
    runApp(const MonsatakApp());
  } catch (_) {
    runApp(const SetupRequiredApp());
  }
}




class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key});




  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.school, size: 70, color: Colors.blue),
                  SizedBox(height: 18),
                  Text(
                    'منصتك التعليمية',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'يلزم إعداد رابط Supabase والمفتاح العام '
                    'قبل تشغيل التطبيق.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}




class MonsatakApp extends StatelessWidget {
  const MonsatakApp({super.key});




  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصتك',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const AuthPage(),
    );
  }
}



