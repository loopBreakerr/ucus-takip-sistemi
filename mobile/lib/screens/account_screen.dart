import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/account_api_client.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _api = AccountApiClient();
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  Account? _account;
  bool _registering = false;
  bool _restored = false;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await operation();
    } on AccountApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on PlatformException {
      if (mounted) setState(() => _error = 'Oturum bilgisine erişilemedi.');
    } on FormatException {
      if (mounted) {
        setState(() => _error = 'Hesap servisi geçersiz yanıt verdi.');
      }
    } on TypeError {
      if (mounted) {
        setState(() => _error = 'Hesap servisi geçersiz yanıt verdi.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() => _run(() async {
    final account = await _api.restore();
    if (!mounted) return;
    setState(() {
      _account = account;
      _restored = true;
    });
  });

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final password = _password.text;
    await _run(() async {
      if (_registering) {
        await _api.register(email, password);
        if (!mounted) return;
        _password.clear();
        setState(() {
          _registering = false;
          _notice = 'Hesabın oluşturuldu. Şimdi giriş yapabilirsin.';
        });
      } else {
        final account = await _api.login(email, password);
        if (!mounted) return;
        _password.clear();
        setState(() => _account = account);
      }
    });
  }

  Future<void> _logout() => _run(() async {
    await _api.logout();
    if (!mounted) return;
    _email.clear();
    setState(() => _account = null);
  });

  void _openUsers() => Navigator.of(context)
      .push<void>(MaterialPageRoute(builder: (_) => _UsersScreen(api: _api)))
      .then((_) {
        if (mounted) _restore();
      });

  @override
  Widget build(BuildContext context) {
    final account = _account;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Hesabım')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                if (_busy) const LinearProgressIndicator(),
                if (_error case final error?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (_notice case final notice?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(notice),
                  ),
                if (!_restored) ...[
                  if (!_busy)
                    OutlinedButton(
                      onPressed: _restore,
                      child: const Text('Yeniden dene'),
                    ),
                ] else if (account != null) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.account_circle_outlined),
                      title: Text(account.email),
                      subtitle: Text(account.roleLabel),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (account.isAdmin)
                    FilledButton.icon(
                      onPressed: _busy ? null : _openUsers,
                      icon: const Icon(Icons.group_outlined),
                      label: const Text('Kullanıcılar'),
                    ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Çıkış yap'),
                  ),
                ] else
                  _buildForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final action = _registering ? 'Kayıt ol' : 'Giriş yap';
    return AutofillGroup(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(action, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                final email = value?.trim() ?? '';
                return email.length <= 254 &&
                        RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(email)
                    ? null
                    : 'Geçerli bir e-posta adresi gir.';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Parola',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofillHints: [
                _registering
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) return 'Parolanı gir.';
                if (_registering &&
                    (password.length < 6 ||
                        !RegExp(r'[0-9]').hasMatch(password))) {
                  return 'Parola en az 6 karakter ve 1 rakam içermeli.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(action),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      _password.clear();
                      _form.currentState?.reset();
                      setState(() {
                        _registering = !_registering;
                        _error = null;
                        _notice = null;
                      });
                    },
              child: Text(
                _registering
                    ? 'Zaten hesabın var mı? Giriş yap'
                    : 'Hesabın yok mu? Kayıt ol',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersScreen extends StatefulWidget {
  const _UsersScreen({required this.api});
  final AccountApiClient api;

  @override
  State<_UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<_UsersScreen> {
  late Future<List<Account>> _users = widget.api.users();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kullanıcılar')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: FutureBuilder<List<Account>>(
          future: _users,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error is AccountApiException
                          ? error.message
                          : 'Kullanıcı listesi yüklenemedi.',
                    ),
                    if (error is! AccountApiException ||
                        error.statusCode != 401 && error.statusCode != 403)
                      TextButton(
                        onPressed: () =>
                            setState(() => _users = widget.api.users()),
                        child: const Text('Yeniden dene'),
                      ),
                  ],
                ),
              );
            }
            final accounts = snapshot.requireData;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      account.isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.person_outline,
                    ),
                    title: Text(account.email),
                    subtitle: Text(account.roleLabel),
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
