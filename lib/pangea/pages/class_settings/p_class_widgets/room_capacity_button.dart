import 'package:fluffychat/pages/chat_details/chat_details.dart';
import 'package:fluffychat/pangea/extensions/pangea_room_extension/pangea_room_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';

class RoomCapacityButton extends StatefulWidget {
  final Room? room;
  final ChatDetailsController? controller;
  const RoomCapacityButton({
    super.key,
    this.room,
    this.controller,
  });

  @override
  RoomCapacityButtonState createState() => RoomCapacityButtonState();
}

class RoomCapacityButtonState extends State<RoomCapacityButton> {
  Room? room;
  ChatDetailsController? controller;
  String? capacity;

  RoomCapacityButtonState({Key? key});

  @override
  void initState() {
    super.initState();
    room = widget.room;
    controller = widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.bodyLarge!.color;
    // Edit - use FutureBuilder to allow async call
    // String nonAdmins = (await room.numNonAdmins).toString();
    return Column(
      children: [
        ListTile(
          onTap: () =>
              ((room?.isRoomAdmin ?? true) ? (setClassCapacity()) : null),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: iconColor,
            child: const Icon(Icons.reduce_capacity),
          ),
          subtitle: Text(
            // Edit
            // '$nonAdmins/${room.capacity}',
            (room?.capacity ?? capacity ?? L10n.of(context)!.capacityNotSet),
          ),
          title: Text(
            L10n.of(context)!.roomCapacity,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> setCapacity(String newCapacity) async {
    capacity = newCapacity;
  }

  Future<void> setClassCapacity() async {
    final TextEditingController myTextFieldController =
        TextEditingController(text: (room?.capacity ?? capacity ?? ''));
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          L10n.of(context)!.roomCapacity,
        ),
        content: TextFormField(
          controller: myTextFieldController,
          keyboardType: TextInputType.number,
          maxLength: 3,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        actions: [
          TextButton(
            child: Text(L10n.of(context)!.cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(L10n.of(context)!.ok),
            onPressed: () async {
              if (myTextFieldController.text == "") return;
              final success = await showFutureLoadingDialog(
                context: context,
                future: () => ((room != null)
                    ? (room!.updateRoomCapacity(myTextFieldController.text))
                    : setCapacity(myTextFieldController.text)),
              );
              if (success.error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      L10n.of(context)!.roomCapacityHasBeenChanged,
                    ),
                  ),
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
