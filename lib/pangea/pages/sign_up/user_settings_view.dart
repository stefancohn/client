import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pangea/pages/sign_up/full_width_button.dart';
import 'package:fluffychat/pangea/pages/sign_up/pangea_login_scaffold.dart';
import 'package:fluffychat/pangea/pages/sign_up/user_settings.dart';
import 'package:fluffychat/pangea/widgets/signup/tos_checkbox.dart';
import 'package:fluffychat/pangea/widgets/user_settings/p_language_dropdown.dart';

class UserSettingsView extends StatelessWidget {
  final UserSettingsState controller;

  const UserSettingsView({
    required this.controller,
    super.key,
  });

  final double avatarSize = 55.0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> avatarOptions = controller.avatarPaths
        .mapIndexed((index, path) {
          return Padding(
            padding: const EdgeInsets.all(5),
            child: AvatarOption(
              onTap: () => controller.setSelectedAvatarPath(index),
              path: path,
              selected: controller.selectedAvatarIndex == index,
              size: avatarSize,
            ),
          );
        })
        .cast<Widget>()
        .toList();

    avatarOptions.add(
      Padding(
        padding: const EdgeInsets.all(5),
        child: InkWell(
          onTap: controller.uploadAvatar,
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: controller.avatar != null
                    ? AppConfig.activeToggleColor
                    : Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.upload,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          ),
        ),
      ),
    );

    return Form(
      key: controller.formKey,
      child: PangeaLoginScaffold(
        showAppName: false,
        mainAssetPath: controller.selectedAvatarPath ?? "",
        mainAssetBytes: controller.avatar,
        children: [
          Opacity(
            opacity: 0.9,
            child: Text(
              L10n.of(context).chooseYourAvatar,
              style: const TextStyle(
                fontWeight: FontWeight.w100,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: avatarOptions,
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: PLanguageDropdown(
              languages: controller.targetOptions,
              onChange: controller.setSelectedTargetLanguage,
              initialLanguage: controller.selectedTargetLanguage,
              isL2List: true,
              error: controller.selectedLanguageError,
            ),
          ),
          if (controller.isSSOSignup)
            FullWidthTextField(
              hintText: L10n.of(context).username,
              validator: (username) {
                if (username == null || username.isEmpty) {
                  return L10n.of(context).pleaseChooseAUsername;
                }
                return null;
              },
              controller: controller.displayNameController,
            ),
          if (controller.isSSOSignup)
            TosCheckbox(
              controller.isTncChecked,
              controller.setTncChecked,
              error: controller.tncError,
            ),
          FullWidthButton(
            title: L10n.of(context).letsStart,
            onPressed: controller.selectedTargetLanguage != null
                ? controller.createUserInPangea
                : null,
            error: controller.profileCreationError,
            loading: controller.loading,
            enabled: controller.selectedTargetLanguage != null &&
                (!controller.isSSOSignup || controller.isTncChecked),
          ),
        ],
      ),
    );
  }
}

class AvatarOption extends StatelessWidget {
  final VoidCallback onTap;
  final String path; // Path or URL of the SVG file
  final double size; // Diameter of the circle
  final bool selected;

  const AvatarOption({
    super.key,
    required this.onTap,
    required this.path,
    this.size = 40.0,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: selected
                ? AppConfig.activeToggleColor
                : Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            path,
            fit: BoxFit.cover, // scale properly without warping
          ),
        ),
      ),
    );
  }
}
