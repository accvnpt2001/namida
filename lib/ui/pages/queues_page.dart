import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:namida/controller/queue_controller.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';
import 'package:namida/ui/widgets/library/queue_tile.dart';

class QueuesPage extends StatelessWidget {
  const QueuesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => NamidaListView(
        itemBuilder: (context, i) {
          final q = QueueController.inst.queueList.toList()[QueueController.inst.queueList.length - i - 1];
          return AnimatingTile(
            key: ValueKey(i),
            position: i,
            child: QueueTile(
              queue: q,
            ),
          );
        },
        itemCount: QueueController.inst.queueList.length,
        itemExtents: QueueController.inst.queueList.map((element) => 68.0 + 18.0).toList(),
      ),
    );
  }
}
