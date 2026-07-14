import 'dart:async';
import 'package:flutter/material.dart';

Future<bool> showTimedConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required int seconds,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return _TimedConfirmationDialogContent(
        title: title,
        message: message,
        seconds: seconds,
      );
    },
  );
  return result ?? false;
}

class _TimedConfirmationDialogContent extends StatefulWidget {
  final String title;
  final String message;
  final int seconds;

  const _TimedConfirmationDialogContent({
    required this.title,
    required this.message,
    required this.seconds,
  });

  @override
  State<_TimedConfirmationDialogContent> createState() => _TimedConfirmationDialogContentState();
}

class _TimedConfirmationDialogContentState extends State<_TimedConfirmationDialogContent> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.seconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _remainingSeconds <= 0;

    return AlertDialog(
      title: Text(widget.title),
      content: Text(widget.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
          child: Text(
            canConfirm ? 'Confirmar' : 'Confirmar ($_remainingSeconds)',
          ),
        ),
      ],
    );
  }
}
