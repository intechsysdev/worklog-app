import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import 'auth_controller.dart';

/// "Crea tu contraseña": the administrator gave a temporary password, and the app asks for the
/// person's own before anything else. The rules match the API (8+ characters, letters and numbers).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _visible = false;
  String? _error;

  /// The temporary password was typed seconds ago in the login: it is not asked again.
  late final String? _recent = ref.read(authControllerProvider.notifier).recentPassword;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  static String? _rules(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Usa al menos 8 caracteres.';
    if (!v.contains(RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]')) || !v.contains(RegExp(r'\d'))) return 'Combina letras y números.';
    return null;
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).changePassword(_recent ?? _current.text, _password.text);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    InputDecoration field(String hint) => InputDecoration(
      hintText: hint,
      suffixIcon: IconButton(
        tooltip: _visible ? 'Ocultar' : 'Mostrar',
        icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        onPressed: () => setState(() => _visible = !_visible),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: Column(
            children: [
              BackHeader(title: 'Crea tu contraseña', onBack: () => ref.read(authControllerProvider.notifier).signOut()),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 16),
                  children: [
                    Text(
                      'Ingresaste con una contraseña temporal. Crea la tuya para seguir: solo tú la conocerás.',
                      style: TextStyle(fontSize: 15, height: 22 / 15, color: c.inkStrong),
                    ),
                    const SizedBox(height: 18),
                    if (_recent == null) ...[
                      TextFormField(
                        controller: _current,
                        obscureText: !_visible,
                        autofillHints: const [AutofillHints.password],
                        decoration: field('Contraseña temporal'),
                        validator: (v) => v == null || v.isEmpty ? 'Escribe la contraseña temporal.' : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _password,
                      obscureText: !_visible,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: field('Nueva contraseña'),
                      validator: _rules,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirm,
                      obscureText: !_visible,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: field('Repite la nueva contraseña'),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => v != _password.text ? 'Las contraseñas no coinciden.' : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Al menos 8 caracteres, con letras y números.',
                      style: TextStyle(fontSize: 13, color: c.inkMuted),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      InfoBanner(icon: Icons.error_outline, child: Text(_error!)),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(kScreenPadding, 0, kScreenPadding, 20),
                child: PrimaryButton(label: 'Guardar y continuar', loading: _busy, onPressed: _submit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
