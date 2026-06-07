import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListView.builder(
          itemCount: 4,
          itemBuilder: (_, __) => const ListTile(
            title: SizedBox(
              height: 16,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.white)),
            ),
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Center(child: Text(text));
}