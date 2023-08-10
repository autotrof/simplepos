import 'package:flutter/widgets.dart';
import 'package:quickalert/quickalert.dart';

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