import 'package:flutter/material.dart';

class StadiaScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const StadiaScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        centerTitle: false,
      ),
      body: body,
    );
  }
}
