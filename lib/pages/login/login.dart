import 'dart:async';

import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pangea/constants/local.key.dart';
import 'package:fluffychat/pangea/controllers/pangea_controller.dart';
import 'package:fluffychat/pangea/pages/sign_up/pangea_login_view.dart';
import 'package:fluffychat/pangea/utils/firebase_analytics.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';
import '../../utils/platform_infos.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  LoginController createState() => LoginController();
}

class LoginController extends State<Login> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? usernameText;
  String? passwordText;

  String? usernameError;
  String? passwordError;

  bool loading = false;
  bool showPassword = false;

  // #Pangea
  final PangeaController pangeaController = MatrixState.pangeaController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool get enabledSignIn =>
      !loading &&
      usernameText != null &&
      usernameText!.isNotEmpty &&
      passwordText != null &&
      passwordText!.isNotEmpty;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loading = true;
    pangeaController.checkHomeServerAction().then((value) {
      setState(() {
        loading = false;
      });
    }).catchError((e) {
      final String err = e.toString();
      setState(() {
        loading = false;
        passwordError = err.toLocalizedString(context);
      });
    });

    usernameController.addListener(() {
      _setStateOnTextChange(usernameText, usernameController.text);
      usernameText = usernameController.text;
    });

    passwordController.addListener(() {
      _setStateOnTextChange(passwordText, passwordController.text);
      passwordText = passwordController.text;
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    loading = false;
    usernameError = null;
    passwordError = null;
    super.dispose();
  }

  void _setStateOnTextChange(String? oldText, String newText) {
    if ((oldText == null || oldText.isEmpty) && (newText.isNotEmpty)) {
      setState(() {});
    }
    if ((oldText != null && oldText.isNotEmpty) && (newText.isEmpty)) {
      setState(() {});
    }
  }
  // Pangea#

  void toggleShowPassword() =>
      setState(() => showPassword = !loading && !showPassword);

  void login() async {
    // #Pangea
    final valid = formKey.currentState!.validate();
    if (!valid) return;
    // Pangea#

    final matrix = Matrix.of(context);
    if (usernameController.text.isEmpty) {
      setState(() => usernameError = L10n.of(context).pleaseEnterYourUsername);
    } else {
      setState(() => usernameError = null);
    }
    if (passwordController.text.isEmpty) {
      setState(() => passwordError = L10n.of(context).pleaseEnterYourPassword);
    } else {
      setState(() => passwordError = null);
    }

    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      return;
    }

    setState(() => loading = true);

    _coolDown?.cancel();

    try {
      // #Pangea
      String username = usernameController.text;
      if (RegExp(r'^@(\w+):').hasMatch(username)) {
        username =
            RegExp(r'^@(\w+):').allMatches(username).elementAt(0).group(1)!;
      }
      // Pangea#
      AuthenticationIdentifier identifier;
      if (username.isEmail) {
        identifier = AuthenticationThirdPartyIdentifier(
          medium: 'email',
          address: username,
        );
      } else if (username.isPhoneNumber) {
        identifier = AuthenticationThirdPartyIdentifier(
          medium: 'msisdn',
          address: username,
        );
      } else {
        identifier = AuthenticationUserIdentifier(user: username);
      }
      // #Pangea
      // await matrix.getLoginClient().login(
      final loginRes = await matrix.getLoginClient().login(
            // Pangea#
            LoginType.mLoginPassword,
            identifier: identifier,
            // To stay compatible with older server versions
            // ignore: deprecated_member_use
            user: identifier.type == AuthenticationIdentifierTypes.userId
                ? username
                : null,
            password: passwordController.text,
            initialDeviceDisplayName: PlatformInfos.clientName,
          );
      MatrixState.pangeaController.pStoreService
          .save(PLocalKey.loginType, 'password');
      // #Pangea
      GoogleAnalytics.login("pangea", loginRes.userId);
      // Pangea#
    } on MatrixException catch (exception) {
      // #Pangea
      // setState(() => passwordError = exception.errorMessage);
      setState(() {
        passwordError = exception.errorMessage;
        usernameError = exception.errorMessage;
      });
      // Pangea#
      return setState(() => loading = false);
    } catch (exception) {
      // #Pangea
      // setState(() => passwordError = exception.toString());
      setState(() {
        passwordError = exception.toString();
        usernameError = exception.toString();
      });
      // Pangea#
      return setState(() => loading = false);
    }

    // #Pangea
    // if (mounted) setState(() => loading = false);
    // Pangea#
  }

  Timer? _coolDown;

  void checkWellKnownWithCoolDown(String userId) async {
    _coolDown?.cancel();
    _coolDown = Timer(
      const Duration(seconds: 1),
      () => _checkWellKnown(userId),
    );
  }

  void _checkWellKnown(String userId) async {
    if (mounted) setState(() => usernameError = null);
    if (!userId.isValidMatrixId) return;
    final oldHomeserver = Matrix.of(context).getLoginClient().homeserver;
    try {
      var newDomain = Uri.https(userId.domain!, '');
      Matrix.of(context).getLoginClient().homeserver = newDomain;
      DiscoveryInformation? wellKnownInformation;
      try {
        wellKnownInformation =
            await Matrix.of(context).getLoginClient().getWellknown();
        if (wellKnownInformation.mHomeserver.baseUrl.toString().isNotEmpty) {
          newDomain = wellKnownInformation.mHomeserver.baseUrl;
        }
      } catch (_) {
        // do nothing, newDomain is already set to a reasonable fallback
      }
      if (newDomain != oldHomeserver) {
        await Matrix.of(context).getLoginClient().checkHomeserver(newDomain);

        if (Matrix.of(context).getLoginClient().homeserver == null) {
          Matrix.of(context).getLoginClient().homeserver = oldHomeserver;
          // okay, the server we checked does not appear to be a matrix server
          Logs().v(
            '$newDomain is not running a homeserver, asking to use $oldHomeserver',
          );
          final dialogResult = await showOkCancelAlertDialog(
            context: context,
            useRootNavigator: false,
            message: L10n.of(context).noMatrixServer(newDomain, oldHomeserver!),
            okLabel: L10n.of(context).ok,
            cancelLabel: L10n.of(context).cancel,
          );
          if (dialogResult == OkCancelResult.ok) {
            if (mounted) setState(() => usernameError = null);
          } else {
            Navigator.of(context, rootNavigator: false).pop();
            return;
          }
        }
        usernameError = null;
        if (mounted) setState(() {});
      } else {
        Matrix.of(context).getLoginClient().homeserver = oldHomeserver;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      Matrix.of(context).getLoginClient().homeserver = oldHomeserver;
      usernameError = e.toLocalizedString(context);
      if (mounted) setState(() {});
    }
  }

  void passwordForgotten() async {
    final input = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context).passwordForgotten,
      message: L10n.of(context).enterAnEmailAddress,
      okLabel: L10n.of(context).ok,
      cancelLabel: L10n.of(context).cancel,
      fullyCapitalizedForMaterial: false,
      textFields: [
        DialogTextField(
          initialText:
              usernameController.text.isEmail ? usernameController.text : '',
          hintText: L10n.of(context).enterAnEmailAddress,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
    if (input == null) return;
    final clientSecret = DateTime.now().millisecondsSinceEpoch.toString();
    final response = await showFutureLoadingDialog(
      context: context,
      future: () =>
          Matrix.of(context).getLoginClient().requestTokenToResetPasswordEmail(
                clientSecret,
                input.single,
                sendAttempt++,
              ),
    );
    if (response.error != null) return;
    final password = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context).passwordForgotten,
      message: L10n.of(context).chooseAStrongPassword,
      okLabel: L10n.of(context).ok,
      cancelLabel: L10n.of(context).cancel,
      fullyCapitalizedForMaterial: false,
      textFields: [
        const DialogTextField(
          hintText: '******',
          obscureText: true,
          minLines: 1,
          maxLines: 1,
        ),
      ],
    );
    if (password == null) return;
    final ok = await showOkAlertDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context).weSentYouAnEmail,
      message: L10n.of(context).pleaseClickOnLink,
      okLabel: L10n.of(context).iHaveClickedOnLink,
      fullyCapitalizedForMaterial: false,
    );
    if (ok != OkCancelResult.ok) return;
    final data = <String, dynamic>{
      'new_password': password.single,
      'logout_devices': false,
      "auth": AuthenticationThreePidCreds(
        type: AuthenticationTypes.emailIdentity,
        threepidCreds: ThreepidCreds(
          sid: response.result!.sid,
          clientSecret: clientSecret,
        ),
      ).toJson(),
    };
    final success = await showFutureLoadingDialog(
      context: context,
      future: () => Matrix.of(context).getLoginClient().request(
            RequestType.POST,
            '/client/v3/account/password',
            data: data,
          ),
    );
    if (success.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).passwordHasBeenChanged)),
      );
      usernameController.text = input.single;
      passwordController.text = password.single;
      login();
    }
  }

  static int sendAttempt = 0;

  @override
  // #Pangea
  // Widget build(BuildContext context) => LoginView(this);
  Widget build(BuildContext context) => PangeaLoginView(this);
  // Pangea#
}

extension on String {
  static final RegExp _phoneRegex =
      RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
  static final RegExp _emailRegex = RegExp(r'(.+)@(.+)\.(.+)');

  bool get isEmail => _emailRegex.hasMatch(this);

  bool get isPhoneNumber => _phoneRegex.hasMatch(this);
}
