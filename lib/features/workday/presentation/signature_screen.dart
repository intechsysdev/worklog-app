import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/headers.dart';

/// Signature pad for the customer. Returns the PNG bytes.
class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  static Future<Uint8List?> open(BuildContext context) => Navigator.of(
    context,
  ).push<Uint8List>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const SignatureScreen()));

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  late final SignatureController _controller = SignatureController(
    penColor: AppPalette.ink,
    exportBackgroundColor: Colors.white,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );
  bool _empty = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_empty != _controller.isEmpty) setState(() => _empty = _controller.isEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final bytes = await _controller.toPngBytes();
    if (!mounted) return;
    Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader(title: 'Firma del cliente'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kScreenPadding),
              child: Text(
                'Pide al cliente que firme dentro del recuadro.',
                style: TextStyle(fontSize: 14, color: c.inkStrong),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: kScreenPadding),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppRadii.button),
                    border: Border.all(color: c.iconSubtle, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Semantics(
                    label: 'Área de firma',
                    child: Signature(controller: _controller, backgroundColor: c.surface),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 14, kScreenPadding, 20),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Borrar',
                      icon: Icons.backspace_outlined,
                      onPressed: _empty ? null : _controller.clear,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Guardar firma',
                      height: 52,
                      fontSize: 16,
                      radius: AppRadii.button,
                      loading: _saving,
                      onPressed: _empty ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
