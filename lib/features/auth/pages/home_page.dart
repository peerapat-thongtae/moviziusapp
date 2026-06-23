import 'package:flutter/material.dart';

import '../../home/widgets/hero_slider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: HeroSlider());
  }
}
