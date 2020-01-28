import 'package:flutter/material.dart';
import 'package:parallax_travel_cards_list/rotation_3d.dart';

import 'demo_data.dart';
import 'travel_card_renderer.dart';

class TravelCardList extends StatefulWidget {
  final List<City> cities;
  final Function onCityChange;

  const TravelCardList({Key key, this.cities, @required this.onCityChange})
      : super(key: key);

  @override
  TravelCardListState createState() => TravelCardListState();
}

class TravelCardListState extends State<TravelCardList>
    with SingleTickerProviderStateMixin {
  final double _maxRotation = 20;

  PageController _pageController;

  double _cardWidth = 160;
  double _cardHeight = 200;
  double _normalizedOffset = 0;
  double _prevScrollX = 0;
  bool _isScrolling = false;
  //int _focusedIndex = 0;

  AnimationController _tweenController;
  Tween<double> _tween;
  Animation<double> _tweenAnim;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    _cardHeight = (size.height * .48).clamp(300.0, 400.0);
    _cardWidth = _cardHeight * .8;
    //Calculate the viewPort fraction for this aspect ratio, since PageController does not accept pixel based size values
    _pageController = PageController(
        initialPage: 1, viewportFraction: _cardWidth / size.width);

    //Create our main list
    Widget listContent = Container(
      //Wrap list in a container to control height and padding
      height: _cardHeight,
      //Use a ListView.builder, calls buildItemRenderer() lazily, whenever it need to display a listItem
      child: PageView.builder(
        //Use bounce-style scroll physics, feels better with this demo
        physics: BouncingScrollPhysics(),

        controller: _pageController,
        itemCount: 8,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) => _buildItemRenderer(i),
      ),
    );

    //Wrap our list content in a Listener to detect PointerUp events, and a NotificationListener to detect ScrollStart and ScrollUpdate
    //We have to use both, because NotificationListener does not inform us when the user has lifted their finger.
    //We can not use GestureDetector like we normally would, ListView suppresses it while scrolling.
    //스크롤 여부 확인
    return Listener(
      onPointerUp: _handlePointerUp,
      child: NotificationListener(
        onNotification: _handleScrollNotifications,
        child: listContent, //카드 컨텐츠
      ),
    );
  }

  //Create a renderer for each list item
  //각각의 호텔 카드 설정
  Widget _buildItemRenderer(int itemIndex) {
    return Container(
      //Vertically pad all the non-selected items, to make them smaller. AnimatedPadding widget handles the animation.
      child: Rotation3d(
        //스크롤 시 카드 좌우로 움직임 변환
        rotationY: _normalizedOffset * _maxRotation,
        //Create the actual content renderer for our list
        child: TravelCardRenderer(
          //호텔 카드 외관 설정
          //Pass in the offset, renderer can update it's own view from there
          _normalizedOffset,
          //Pass in city path for the image asset links
          city: widget.cities[itemIndex % widget.cities.length],
          cardWidth: _cardWidth,
          cardHeight: _cardHeight,
        ),
      ),
    );
  }

  //Check the notifications bubbling up from the ListView, use them to update our currentOffset and isScrolling state
  bool _handleScrollNotifications(Notification notification) {
    //Scroll Update, add to our current offset, but clamp to -1 and 1
    if (notification is ScrollUpdateNotification) {
      //스크롤 포지션이 바뀌었을 때
      if (_isScrolling) {
        //스크롤 중일 때
        double dx = notification.metrics.pixels - _prevScrollX;
        double scrollFactor = 1; //좌우로 스크롤되는 정도
        double newOffset = (_normalizedOffset + dx * scrollFactor);
        _setOffset(newOffset.clamp(-1.0, 1.0)); // 좌우로 움직이는 정도
      }
      //스크롤이 끝났을 때
      _prevScrollX = notification.metrics.pixels;
      //Calculate the index closest to middle
      //_focusedIndex = (_prevScrollX / (_itemWidth + _listItemPadding)).round();
      widget.onCityChange(widget.cities.elementAt(
          _pageController.page.round() % widget.cities.length)); //스크롤 후 city 설정
    }
    //Scroll Start
    else if (notification is ScrollStartNotification) {
      _isScrolling = true;
      _prevScrollX = notification.metrics.pixels;
      if (_tween != null) {
        _tweenController.stop();
      }
    }
    return true;
  }

  //If the user has released a pointer, and is currently scrolling, we'll assume they're done scrolling and tween our offset to zero.
  //This is a bit of a hack, we can't be sure this event actually came from the same finger that was scrolling, but should work most of the time.
  void _handlePointerUp(PointerUpEvent event) {
    if (_isScrolling) {
      _isScrolling = false;
      _startOffsetTweenToZero();
    }
  }

  //Helper function, any time we change the offset, we want to rebuild the widget tree, so all the renderers get the new value.
  void _setOffset(double value) {
    setState(() {
      _normalizedOffset = value;
    });
  }

  //Tweens our offset from the current value, to 0
  void _startOffsetTweenToZero() {
    //The first time this runs, setup our controller, tween and animation. All 3 are required to control an active animation.
    int tweenTime = 1000;
    if (_tweenController == null) {
      //Create Controller, which starts/stops the tween, and rebuilds this widget while it's running
      _tweenController = AnimationController(
          vsync: this, duration: Duration(milliseconds: tweenTime));
      //Create Tween, which defines our begin + end values
      _tween = Tween<double>(begin: -1, end: 0);
      //Create Animation, which allows us to access the current tween value and the onUpdate() callback.
      _tweenAnim = _tween.animate(new CurvedAnimation(
          parent: _tweenController, curve: Curves.elasticOut))
        //Set our offset each time the tween fires, triggering a rebuild
        ..addListener(() {
          _setOffset(_tweenAnim.value);
        });
    }
    //Restart the tweenController and inject a new start value into the tween
    _tween.begin = _normalizedOffset;
    _tweenController.reset();
    _tween.end = 0;
    _tweenController.forward();
  }
}
