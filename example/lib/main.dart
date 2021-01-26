import 'package:disposable_provider/disposable_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hop_swipe_cards/hop_swipe_cards.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(Example());
}

class Example extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(),
      home: ExampleHomePage.create(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  static Widget create() {
    return DisposableProvider(
      create: (context) => CardController(),
      child: ExampleHomePage(),
    );
  }

  @override
  _ExampleHomePageState createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage>
    with TickerProviderStateMixin {
  List<String> images = [
    "images/pic_one.jpg",
    "images/pic_two.jpg",
    "images/pic_three.jpg",
    "images/pic_four.jpg",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment(0, 0.9),
            child: Container(
              height: 80,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomButton(
                    icon: Icons.close,
                    onTap: () {
                      context.read<CardController>().triggerLeftOnCard();
                    },
                  ),
                  SizedBox(
                    width: 60,
                  ),
                  CustomButton(
                    icon: Icons.favorite_border,
                    onTap: () {
                      context.read<CardController>().triggerRightOnCard();
                    },
                  ),
                  CustomButton(
                    icon: Icons.favorite_border,
                    onTap: () {
                      context.read<CardController>().triggerRewind();
                    },
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              child: HopSwipeCards(
                noMoreSwipeCardsLeft: Center(child: Text('No more users left')),
                totalNum: images.length,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.width * 0.9,
                minWidth: MediaQuery.of(context).size.width * 0.8,
                minHeight: MediaQuery.of(context).size.width * 0.8,
                cardBuilder: (context, index, a, b) =>
                    _SingleCard(image: images[index]),
                swipeCompleteCallback: (int index, direction) {
                  //direction gives the swipe direction after completion
                },
                cardController: context.watch(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleCard extends StatelessWidget {
  final String image;

  const _SingleCard({Key key, @required this.image}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Center(
        child: Container(
          height: MediaQuery.of(context).size.width * 0.9,
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(),
          child: Image.asset(
            image,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  const CustomButton({Key key, @required this.icon, @required this.onTap})
      : super(key: key);
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        width: 80,
        child: Icon(
          icon,
          size: 40,
        ),
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: Colors.amberAccent.withOpacity(0.7)),
      ),
    );
  }
}
