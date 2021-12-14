// ignore_for_file: public_member_api_docs, library_private_types_in_public_api

import 'package:flutter/material.dart';

class AnimatedError extends StatefulWidget {
  const AnimatedError({
    Key? key,
    this.show = false,
    required this.text,
  }) : super(key: key);
  final bool show;
  final String text;

  @override
  _AnimatedErrorState createState() => _AnimatedErrorState();
}

class _AnimatedErrorState extends State<AnimatedError>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedSize(
        curve: Curves.easeInOut,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        duration: const Duration(milliseconds: 180),
        child: Visibility(
          key: ValueKey(widget.show),
          visible: widget.show,
          child: Container(
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(5),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                widget.show ? widget.text : '',
                key: ValueKey<String>(widget.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
