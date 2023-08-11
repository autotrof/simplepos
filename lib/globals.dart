import 'package:flutter/widgets.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter/services.dart';

const String appName = 'Simple POS';
const String debugCode = '46UN664N73NG53K4L1';

void alertSuccess({String text = 'Berhasil Melakukan Operasi', required BuildContext context}) {
  QuickAlert.show(
    context: context,
    type: QuickAlertType.success,
    text: text,
    autoCloseDuration: const Duration(seconds: 2),
  );
}

void alertError({String text = 'Terjadi Kesalahan', required BuildContext context}) {
  QuickAlert.show(
    context: context,
    type: QuickAlertType.error,
    text: text,
    autoCloseDuration: const Duration(seconds: 2),
  );
}


class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ','; // Change this to '.' for other locales

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Short-circuit if the new value is empty
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Handle "deletion" of separator character
    String oldValueText = oldValue.text.replaceAll(separator, '');
    String newValueText = newValue.text.replaceAll(separator, '');

    if (oldValue.text.endsWith(separator) &&
        oldValue.text.length == newValue.text.length + 1) {
      newValueText = newValueText.substring(0, newValueText.length - 1);
    }

    // Only process if the old value and new value are different
    if (oldValueText != newValueText) {
      int selectionIndex =
          newValue.text.length - newValue.selection.extentOffset;
      final chars = newValueText.split('');

      String newString = '';
      for (int i = chars.length - 1; i >= 0; i--) {
        if ((chars.length - 1 - i) % 3 == 0 && i != chars.length - 1) {
          newString = separator + newString;
        }
        newString = chars[i] + newString;
      }

      return TextEditingValue(
        text: newString.toString(),
        selection: TextSelection.collapsed(
          offset: newString.length - selectionIndex,
        ),
      );
    }

    // If the new value and old value are the same, just return as-is
    return newValue;
  }
}