import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:s3editor/extensions/card_ext.dart';
import 'package:s3editor/extensions/string_ext.dart';

class InputShapeWidget extends HookWidget {
  const InputShapeWidget({
    super.key,
    required this.title,
    this.currentValue,
    this.bgColor,
    this.suffix,
    this.onLongPress,
    this.onTap,
    this.secretText = false,
  });
  final String title;
  final String? currentValue;
  final void Function()? onLongPress;
  final void Function()? onTap;
  final Color? bgColor;
  final Widget? suffix;
  final bool secretText;

  TextStyle get textStyle =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black);

  @override
  Widget build(BuildContext context) {
    Widget tmpChild = Text(
      currentValue ?? 'empty'.toCapitalize(),
      style: textStyle,
    );
    Widget tmpSuffix = suffix == null ? const SizedBox() : suffix!;
    if (secretText) {
      final isShowText = useState(false);
      if (isShowText.value) {
        tmpChild = Text(
          currentValue ?? 'empty'.toCapitalize(),
          style: textStyle,
        );
        tmpSuffix = Row(
          children: [
            tmpSuffix,
            IconButton(
              onPressed: () {
                isShowText.value = false;
              },
              icon: Icon(Icons.visibility_outlined),
            ),
          ],
        );
      } else {
        tmpChild = Text('****', style: textStyle);
        tmpSuffix = Row(
          children: [
            tmpSuffix,
            IconButton(
              onPressed: () {
                isShowText.value = true;
              },
              icon: Icon(Icons.visibility_off_outlined),
            ),
          ],
        );
      }
    }

    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(padding: const EdgeInsets.only(left: 16), child: Text(title)),
        InkWell(
          onLongPress: onLongPress,
          //onTap: () => showModal(context, ref),
          onTap: onTap,
          child: CardExt.casual(
            color: bgColor,
            padding: EdgeInsets.only(top: 4, bottom: 4, left: 16, right: 0),
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: tmpChild),
                  tmpSuffix,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
