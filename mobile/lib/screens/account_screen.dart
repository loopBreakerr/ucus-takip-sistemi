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
  bool _showPassword = false;
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
          _showPassword = false;
          _notice = 'Hesabın oluşturuldu. Şimdi giriş yapabilirsin.';
        });
      } else {
        final account = await _api.login(email, password);
        if (!mounted) return;
        _password.clear();
        setState(() {
          _account = account;
          _showPassword = false;
        });
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
                if (!_restored || account != null) _feedback(context),
                if (!_restored) ...[
                  if (!_busy)
                    OutlinedButton(
                      onPressed: _restore,
                      child: const Text('Yeniden dene'),
                    ),
                ] else if (account != null)
                  _buildProfile(context, account)
                else
                  _buildForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, Account account) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card.outlined(
          margin: EdgeInsets.zero,
          color: colors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: Icon(
                    account.isAdmin
                        ? Icons.admin_panel_settings_outlined
                        : Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  account.isAdmin ? 'Yönetici paneli' : 'Hesap bilgileri',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(account.email, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                _RoleBadge(account: account),
              ],
            ),
          ),
        ),
        if (account.isAdmin) ...[
          const SizedBox(height: 16),
          Card.outlined(
            margin: EdgeInsets.zero,
            child: ListTile(
              enabled: !_busy,
              onTap: _busy ? null : _openUsers,
              leading: Icon(Icons.group_outlined, color: colors.primary),
              title: const Text('Kullanıcılar'),
              subtitle: const Text('Kayıtlı hesapları ve rollerini görüntüle.'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _busy ? null : _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Çıkış yap'),
        ),
      ],
    );
  }

  void _switchMode(bool registering) {
    if (_registering == registering) return;
    FocusScope.of(context).unfocus();
    final email = _email.value;
    _form.currentState?.reset();
    _email.value = email;
    _password.clear();
    setState(() {
      _registering = registering;
      _showPassword = false;
      _error = null;
      _notice = null;
    });
  }

  Widget _feedback(BuildContext context) {
    final message = _error ?? _notice;
    if (message == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final isError = _error != null;
    final foreground = isError
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isError ? colors.errorContainer : colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: foreground,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(message, style: TextStyle(color: foreground)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final action = _registering ? 'Hesap oluştur' : 'Giriş yap';

    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.flight_takeoff_rounded,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _registering ? 'Hesabını oluştur' : 'Tekrar hoş geldin',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _registering
                      ? 'E-posta adresin ve bir parola ile Uçuş Takip hesabı oluştur.'
                      : 'Uçuş Takip hesabına e-posta adresinle giriş yap.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('Giriş yap')),
                    ButtonSegment(value: true, label: Text('Kayıt ol')),
                  ],
                  selected: {_registering},
                  onSelectionChanged: _busy
                      ? null
                      : (selection) => _switchMode(selection.single),
                ),
                const SizedBox(height: 20),
                _feedback(context),
                TextFormField(
                  controller: _email,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: const Icon(Icons.alternate_email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    return email.length <= 254 &&
                            RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(email)
                        ? null
                        : 'Geçerli bir e-posta adresi gir.';
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: 'Parola',
                    prefixIcon: const Icon(Icons.lock_outline),
                    helperText: _registering
                        ? 'En az 6 karakter ve 1 rakam'
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    suffixIcon: IconButton(
                      tooltip: _showPassword
                          ? 'Parolayı gizle'
                          : 'Parolayı göster',
                      onPressed: _busy
                          ? null
                          : () =>
                                setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  obscureText: !_showPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
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
                      return 'En az 6 karakter ve 1 rakam gir.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: Icon(
                    _registering ? Icons.person_add_alt_1 : Icons.login,
                  ),
                  label: Text(_busy ? 'İşleniyor…' : action),
                ),
              ],
            ),
          ),
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

  void _reload() => setState(() => _users = widget.api.users());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcılar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: FutureBuilder<List<Account>>(
            future: _users,
            builder: (context, snapshot) {
              final loading = snapshot.connectionState != ConnectionState.done;
              final accounts = snapshot.data ?? const <Account>[];
              final error = snapshot.error;

              final header = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Kayıtlı hesaplar',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Listeyi yenile',
                        onPressed: loading ? null : _reload,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (loading)
                    const LinearProgressIndicator()
                  else if (error != null) ...[
                    Text(
                      error is AccountApiException
                          ? error.message
                          : 'Kullanıcı listesi yüklenemedi.',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    if (error is! AccountApiException ||
                        (error.statusCode != 401 && error.statusCode != 403))
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: _reload,
                          child: const Text('Yeniden dene'),
                        ),
                      ),
                  ] else ...[
                    Text(
                      accounts.isEmpty
                          ? 'Kayıtlı hesap yok.'
                          : '${accounts.length} hesap',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: loading || error != null ? 1 : accounts.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return header;
                  final account = accounts[index - 1];
                  return Card.outlined(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: theme.colorScheme.surfaceContainerLowest,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          account.isAdmin
                              ? Icons.admin_panel_settings_outlined
                              : Icons.person_outline,
                        ),
                      ),
                      title: Text(account.email),
                      subtitle: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _RoleBadge(account: account),
                        ),
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

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: account.isAdmin
            ? colors.primaryContainer
            : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          account.roleLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: account.isAdmin
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
