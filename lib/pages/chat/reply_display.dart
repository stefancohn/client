import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import '../../config/themes.dart';
import 'chat.dart';
import 'events/reply_content.dart';

class ReplyDisplay extends StatelessWidget {
  final ChatController controller;
  const ReplyDisplay(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: FluffyThemes.animationDuration,
      curve: FluffyThemes.animationCurve,
      height: controller.editEvent != null || controller.replyEvent != null
          ? 56
          : 0,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        // #Pangea
        borderRadius: const BorderRadius.all(Radius.circular(28.0)),
        // Pangea#
        color: Theme.of(context).colorScheme.onInverseSurface,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: L10n.of(context)!.close,
            icon: const Icon(Icons.close),
            onPressed: controller.cancelReplyEventAction,
          ),
          Expanded(
            child: controller.replyEvent != null
                ? ReplyContent(
                    controller.replyEvent!,
                    timeline: controller.timeline!,
                    backgroundColor: Colors.transparent,
                  )
                : _EditContent(
                    controller.editEvent?.getDisplayEvent(controller.timeline!),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EditContent extends StatelessWidget {
  final Event? event;

  const _EditContent(this.event);

  @override
  Widget build(BuildContext context) {
    final event = this.event;
    if (event == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: <Widget>[
        Icon(
          Icons.edit,
          color: Theme.of(context).colorScheme.primary,
        ),
        // #Pangea
        // Container(width: 15.0),
        Container(width: 8.0),
        Flexible(
          child:
              // Pangea#
              Text(
            event.calcLocalizedBodyFallback(
              MatrixLocals(L10n.of(context)!),
              withSenderNamePrefix: false,
              hideReply: true,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
        ),
        // #Pangea
        Container(width: 10.0),
        // Pangea#
      ],
    );
  }
}
