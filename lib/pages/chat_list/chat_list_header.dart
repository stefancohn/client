import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/client_chooser_button.dart';
import 'package:fluffychat/pangea/widgets/chat_list/analytics_summary/learning_progress_indicators.dart';

class ChatListHeader extends StatelessWidget implements PreferredSizeWidget {
  final ChatListController controller;
  final bool globalSearch;

  const ChatListHeader({
    super.key,
    required this.controller,
    this.globalSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final selectMode = controller.selectMode;

    return SliverAppBar(
      floating: true,
      // #Pangea
      // toolbarHeight: 72,
      toolbarHeight: controller.isSearchMode ? 72 : 175,
      // Pangea#
      pinned:
          FluffyThemes.isColumnMode(context) || selectMode != SelectMode.normal,
      scrolledUnderElevation: selectMode == SelectMode.normal ? 0 : null,
      // #Pangea
      // backgroundColor:
      //     selectMode == SelectMode.normal ? Colors.transparent : null,
      // Pangea#
      automaticallyImplyLeading: false,
      // #Pangea
      // leading: selectMode == SelectMode.normal
      //     ? null
      //     : IconButton(
      //         tooltip: L10n.of(context).cancel,
      //         icon: const Icon(Icons.close_outlined),
      //         onPressed: controller.cancelAction,
      //         color: theme.colorScheme.primary,
      //       ),
      // Pangea#
      title:
          // #Pangea
          // selectMode == SelectMode.share
          //     ? Text(
          //         L10n.of(context).share,
          //         key: const ValueKey(SelectMode.share),
          //       )
          Column(
        children: [
          // Pangea#
          TextField(
            controller: controller.searchController,
            focusNode: controller.searchFocusNode,
            textInputAction: TextInputAction.search,
            onChanged: (text) => controller.onSearchEnter(
              text,
              globalSearch: globalSearch,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.secondaryContainer,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(99),
              ),
              contentPadding: EdgeInsets.zero,
              hintText: L10n.of(context).searchChatsRooms,
              hintStyle: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.normal,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              prefixIcon: controller.isSearchMode
                  ? IconButton(
                      tooltip: L10n.of(context).cancel,
                      icon: const Icon(Icons.close_outlined),
                      onPressed: controller.cancelSearch,
                      color: theme.colorScheme.onPrimaryContainer,
                    )
                  : IconButton(
                      onPressed: controller.startSearch,
                      icon: Icon(
                        Icons.search_outlined,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
              suffixIcon: controller.isSearchMode && globalSearch
                  ? controller.isSearching
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 12,
                          ),
                          child: SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      // #Pangea
                      : const SizedBox(
                          width: 0,
                          child: ClientChooserButton(),
                        )
                  // : TextButton.icon(
                  //     onPressed: controller.setServer,
                  //     style: TextButton.styleFrom(
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(99),
                  //       ),
                  //       textStyle: const TextStyle(fontSize: 12),
                  //     ),
                  //     icon: const Icon(Icons.edit_outlined, size: 16),
                  //     label: Text(
                  //       controller.searchServer ??
                  //           Matrix.of(context).client.homeserver!.host,
                  //       maxLines: 2,
                  //     ),
                  //   )
                  // #Pangea
                  : const SizedBox(
                      width: 0,
                      child: ClientChooserButton(
                          // #Pangea
                          // controller
                          // Pangea#
                          ),
                    ),
            ),
          ),
          // #Pangea
          if (!controller.isSearchMode)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: LearningProgressIndicators(),
            ),
          // Pangea#
        ],
      ),
      // #Pangea
      // actions: selectMode == SelectMode.share
      //     ? [
      //         Padding(
      //           padding: const EdgeInsets.symmetric(
      //             horizontal: 16.0,
      //             vertical: 8.0,
      //           ),
      //           child: ClientChooserButton(controller),
      //         ),
      //       ]
      //     : null,
      // Pangea#
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
