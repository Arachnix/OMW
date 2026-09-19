import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../api/omw_api.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import '../widgets/pill_button.dart';

/// "Sign_android" / "Sign_iOS" frames. iOS shows "Continue with Apple";
/// Android shows "Continue with Email".
///
/// Email sign-in goes to POST /api/auth/login. Google/Apple are not wired to
/// real providers and sign in to the backend's seeded demo students.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _emailFocus = FocusNode();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _continueWithEmail() {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    _run(() => context.read<AppState>().signIn(_email.text.trim()));
  }

  /// Google / Apple aren't wired to real providers; they sign in to the
  /// backend's seeded demo students (requester and runner).
  void _demoProvider(String provider, {required bool runner}) {
    if (_busy) return;
    _run(() async {
      await context.read<AppState>().signInDemo(runner: runner);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demo: signed in as ${context.read<AppState>().user?.name} '
            '($provider sign-in is not connected in this build)',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.authGutter,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 327),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        _mascot(constraints.maxHeight),
                        const SizedBox(height: 40),
                        Semantics(
                          header: true,
                          child: Text(
                            'Create an account',
                            textAlign: TextAlign.center,
                            style: AppText.authTitle,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Enter your email to sign up for this app',
                          textAlign: TextAlign.center,
                          style: AppText.authBody,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        TextFormField(
                          controller: _email,
                          focusNode: _emailFocus,
                          validator: _validate,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          style: AppText.fieldText,
                          onFieldSubmitted: (_) => _continueWithEmail(),
                          decoration: const InputDecoration(
                            hintText: 'email@domain.com',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PillButton(
                          label: 'Continue',
                          busy: _busy,
                          height: 40,
                          radius: AppRadii.field,
                          textStyle: AppText.button.copyWith(
                            color: AppColors.surface,
                          ),
                          onPressed: _continueWithEmail,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        const _OrDivider(),
                        const SizedBox(height: AppSpacing.xxl),
                        SoftButton(
                          label: 'Continue with Google',
                          // Multicolour logo, so no ink recolouring.
                          leading: SvgPicture.asset(
                            AppIcons.google,
                            width: 20,
                            height: 20,
                            excludeFromSemantics: true,
                          ),
                          onPressed: () =>
                              _demoProvider('Google', runner: false),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (isIOS)
                          SoftButton(
                            label: 'Continue with Apple',
                            leading: Image.asset(
                              AppImages.apple,
                              width: 20,
                              height: 20,
                              excludeFromSemantics: true,
                            ),
                            onPressed: () =>
                                _demoProvider('Apple', runner: true),
                          )
                        else
                          SoftButton(
                            label: 'Continue with Email',
                            onPressed: _emailFocus.requestFocus,
                          ),
                        const SizedBox(height: AppSpacing.xxl),
                        const _LegalCopy(),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Figma draws the mascot at 206×209; shrink it on short screens so the
  /// form stays reachable.
  Widget _mascot(double viewportHeight) {
    final size = (viewportHeight * 0.26).clamp(120.0, 206.0);
    return Center(
      child: Image.asset(
        AppImages.mascotLogo,
        width: size,
        height: size * 209 / 206,
        fit: BoxFit.cover,
        semanticLabel: 'OnMyWay mushroom mascot',
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'or',
            style: AppText.fieldText.copyWith(color: AppColors.textMuted),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _LegalCopy extends StatelessWidget {
  const _LegalCopy();

  @override
  Widget build(BuildContext context) {
    final link = AppText.legal.copyWith(color: AppColors.ink);
    return Text.rich(
      TextSpan(
        style: AppText.legal,
        children: [
          const TextSpan(text: 'By clicking continue, you agree to our '),
          TextSpan(text: 'Terms of Service', style: link),
          const TextSpan(text: ' and '),
          TextSpan(text: 'Privacy Policy', style: link),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
