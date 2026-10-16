import 'dart:js_interop';

@JS('enableWakeLock')
external void jsEnableWakeLock();

@JS('disableWakeLock')
external void jsDisableWakeLock();
