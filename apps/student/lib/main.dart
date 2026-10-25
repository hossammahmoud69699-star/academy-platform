
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    runApp(const SetupRequiredApp());
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  runApp(const MonsatakApp());
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

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'اكتب البريد الإلكتروني وكلمة المرور.');
      return;
    }

    if (!_isLogin && password.length < 6) {
      setState(() => _error = 'كلمة المرور يجب ألا تقل عن 6 أحرف.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await _supabase.auth.signUp(
          email: email,
          password: password,
        );
      }

      if (!mounted) return;

      if (_supabase.auth.currentSession != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const CoursesPage(),
          ),
        );
      } else {
        setState(() {
          _error =
              'تم إرسال طلب التسجيل. تحقق من بريدك الإلكتروني '
              'إذا كان تأكيد البريد مطلوبًا.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'حدث خطأ أثناء الاتصال. تحقق من الإعدادات.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.school,
                        size: 64,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'منصتك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'تسجيل دخول الطالب' : 'إنشاء حساب طالب',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _loading
                                ? 'جارٍ التنفيذ...'
                                : _isLogin
                                    ? 'تسجيل الدخول'
                                    : 'إنشاء الحساب',
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _error = null;
                                });
                              },
                        child: Text(
                          _isLogin
                              ? 'ليس لديك حساب؟ أنشئ حسابًا'
                              : 'لديك حساب بالفعل؟ سجّل الدخول',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  late Future<List<Map<String, dynamic>>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _loadCourses();
  }

  Future<List<Map<String, dynamic>>> _loadCourses() async {
    final response = await Supabase.instance.client
        .from('courses')
        .select('id, title, description')
        .eq('is_published', true)
        .order('title');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('كورسات منصتك'),
          actions: [
            IconButton(
              onPressed: _signOut,
              tooltip: 'تسجيل الخروج',
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() => _coursesFuture = _loadCourses());
            await _coursesFuture;
          },
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _coursesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: const [
                    Icon(Icons.cloud_off, size: 55),
                    SizedBox(height: 12),
                    Text(
                      'تعذر تحميل الكورسات. اسحب الشاشة للتحديث '
                      'وتحقق من اتصال قاعدة البيانات وصلاحيات الوصول.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }

              final courses = snapshot.data ?? [];

              if (courses.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: const [
                    Icon(Icons.menu_book, size: 60),
                    SizedBox(height: 12),
                    Text(
                      'لا توجد كورسات منشورة حاليًا.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.play_lesson),
                      ),
                      title: Text(
                        course['title']?.toString() ?? 'كورس',
                      ),
                      subtitle: Text(
                        course['description']?.toString() ??
                            'لا يوجد وصف للكورس.',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
