
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MonsatakApp());
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
          seedColor: const Color(0xFF2457C5),
        ),
        useMaterial3: true,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: StudentApp(),
      ),
    );
  }
}

class StudentApp extends StatefulWidget {
  const StudentApp({super.key});

  @override
  State<StudentApp> createState() => _StudentAppState();
}

class _StudentAppState extends State<StudentApp> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String message = '';

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
      if (mounted) setState(() {});
    } catch (e) {
      message = 'تعذر تسجيل الدخول. تأكد من البيانات وإعداد الاتصال.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    if (client.auth.currentSession != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('منصتك التعليمية'),
          actions: [
            IconButton(
              onPressed: () async {
                await client.auth.signOut();
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: const Center(
          child: Text(
            'أهلًا بك في منصتك!\nسنضيف الكورسات هنا في الخطوة التالية.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('منصتك — تسجيل الدخول')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.school, size: 70),
          const SizedBox(height: 20),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(color: Colors.red)),
          FilledButton(
            onPressed: loading ? null : signIn,
            child: Text(loading ? 'جارٍ الدخول...' : 'تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}
