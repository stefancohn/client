import 'package:flutter/material.dart';

import 'package:fluffychat/pangea/enum/activity_type_enum.dart';
import 'package:fluffychat/pangea/models/pangea_token_model.dart';
import 'package:fluffychat/pangea/widgets/practice_activity/word_zoom_activity_button.dart';

class EmojiPracticeButton extends StatelessWidget {
  final PangeaToken token;
  final VoidCallback onPressed;
  final bool isSelected;

  const EmojiPracticeButton({
    required this.token,
    required this.onPressed,
    this.isSelected = false,
    super.key,
  });

  bool get _shouldDoActivity => token.shouldDoActivity(
        a: ActivityTypeEnum.emoji,
        feature: null,
        tag: null,
      );

  @override
  Widget build(BuildContext context) {
    final emoji = token.getEmoji();
    return _shouldDoActivity || emoji != null
        ? WordZoomActivityButton(
            icon: emoji == null
                ? const Icon(Icons.add_reaction_outlined)
                : Text(emoji),
            isSelected: isSelected,
            onPressed: onPressed,
          )
        : const SizedBox(width: 40);
  }
}
