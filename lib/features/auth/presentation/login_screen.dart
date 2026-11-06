import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../onboarding/data/device_info.dart';
import '../data/sso_service.dart';
import 'auth_controller.dart';

/// "Ingreso". In development mode only the email is asked (token `dev:<email>`).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _ssoBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (ref.read(appConfigProvider).isMock) {
      _email.text = 'andres.mora@intechsys.co';
      _password.text = 'demo';
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final config = ref.read(appConfigProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authControllerProvider.notifier);
      if (config.isDevelopment) {
        await auth.signInDevelopment(_email.text);
      } else {
        await auth.signInWithPassword(_email.text, _password.text);
      }
    } on ApiException catch (e) {
      setState(
        () => _error = e.requiresTwoFactor
            ? 'Tu cuenta tiene verificación en dos pasos. Usa el botón «Ingresar con la cuenta de la empresa».'
            : e.statusCode == 401
            ? 'Correo o contraseña incorrectos.'
            : e.message,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sso() async {
    setState(() {
      _ssoBusy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).signInWithSso();
    } on SsoCancelledException {
      // The user closed the browser.
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } on Exception {
      setState(() => _error = 'No se pudo completar el inicio de sesión con la cuenta de la empresa.');
    } finally {
      if (mounted) setState(() => _ssoBusy = false);
    }
  }

  void _forgotPassword() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Olvidaste tu contraseña?'),
        content: const Text(
          'La contraseña es la de tu cuenta de INTECHSYS ONE. Recupérala desde el portal de ONE o pide ayuda a soporte TI.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final config = ref.watch(appConfigProvider);
    final auth = ref.watch(authControllerProvider);
    final device = ref.watch(deviceInfoProvider).value;
    final expired = auth is SignedOut ? auth.message : null;
    final message = _error ?? expired;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: OneLogo(large: true)),
                      const SizedBox(height: 16),
                      Text(
                        'WorkLog',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: c.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bitácora de actividades',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: c.inkMuted),
                      ),
                      const SizedBox(height: 32),
                      _Label(
                        text: 'Usuario corporativo',
                        hint: config.isDevelopment ? ' · modo desarrollo' : ' · asignado a este dispositivo',
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: config.isDevelopment ? TextInputAction.done : TextInputAction.next,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(hintText: 'usuario@empresa.com'),
                        onFieldSubmitted: config.isDevelopment ? (_) => _submit() : null,
                        validator: (v) => v == null || !v.contains('@') || v.trim().length < 5
                            ? 'Escribe tu correo corporativo.'
                            : null,
                      ),
                      if (!config.isDevelopment) ...[
                        const SizedBox(height: 16),
                        const _Label(text: 'Contraseña'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(hintText: 'Tu contraseña'),
                          onFieldSubmitted: (_) => _submit(),
                          validator: (v) => v == null || v.isEmpty ? 'Escribe tu contraseña.' : null,
                        ),
                      ],
                      if (config.isMock) ...[
                        const SizedBox(height: 16),
                        const InfoBanner(
                          tone: BannerTone.neutral,
                          child: Text('Modo demostración: ingresa con cualquier correo y contraseña.'),
                        ),
                      ],
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        InfoBanner(icon: Icons.error_outline, child: Text(message)),
                      ],
                      const SizedBox(height: 20),
                      PrimaryButton(label: 'Ingresar', loading: _busy, onPressed: _ssoBusy ? null : _submit),
                      if (!config.isDevelopment) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(color: c.borderCard)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('o', style: TextStyle(fontSize: 13, color: c.inkMuted)),
                            ),
                            Expanded(child: Divider(color: c.borderCard)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SecondaryButton(
                          label: 'Ingresar con la cuenta de la empresa',
                          icon: Icons.domain_outlined,
                          loading: _ssoBusy,
                          onPressed: _busy ? null : _sso,
                        ),
                        Center(
                          child: TextButton(
                            onPressed: _forgotPassword,
                            style: TextButton.styleFrom(minimumSize: const Size(0, 44), foregroundColor: c.primary),
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Text(
                          'Modo desarrollo: se ingresa con el token dev:<correo> contra ${config.worklogApiUrl}.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: c.inkMuted),
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: 24),
                      Text(
                        'Conectamos tecnología.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: c.inkStrong),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Impulsamos negocios.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.inkStrong),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dispositivo administrado por SOTI MobiControl${device == null ? '' : ' · ${device.model}'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: c.inkMuted),
                      ),
                      Text(
                        'INTECHSYS ONE · WorkLog ${config.appVersion}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Text.rich(
      TextSpan(
        text: text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
        children: [
          if (hint != null)
            TextSpan(
              text: hint,
              style: TextStyle(fontWeight: FontWeight.w400, color: c.inkMuted),
            ),
        ],
      ),
    );
  }
}
