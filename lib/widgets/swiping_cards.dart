import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../animals.dart';
import '../api.dart';
import '../colors.dart';
import '../details.dart';
import 'draggable_card.dart';

class SwipingCards extends StatefulWidget {
  SwipingCards({this.feed});
  final AnimalFeed feed;
  @override
  _SwipingCardsState createState() => _SwipingCardsState();
}

class _SwipingCardsState extends State<SwipingCards>
    with AutomaticKeepAliveClientMixin<SwipingCards> {
  @override
  bool get wantKeepAlive => true;

  bool loading = false;

  double _backCardScale = 0.9;

  @override
  void initState() {
    super.initState();
    widget.feed.notifier.addListener(_onSwipeChange);
  }

  _onSwipeChange() {
    if (widget.feed.notifier.swiped == Swiped.undo) {
      setState(() {
        widget.feed.getRecentlySkipped();
      });
    }
  }

  @override
  void dispose() {
    widget.feed.notifier.removeListener(_onSwipeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      Size screenSize = MediaQuery.of(context).size;
      double _screenWidth = screenSize.width;
      double _screenHeight = screenSize.height;
      return Container(
          height: _screenHeight / 1.65,
          width: _screenWidth / 1.2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(strokeWidth: 1.0),
            ],
          ));
    }
    if (widget.feed.currentList.isEmpty) return _buildNoPetsLeftPage();
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        widget.feed.nextPet == null
            ? SizedBox()
            : Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(_backCardScale, _backCardScale),
                child: PetCard(widget.feed.nextPet),
              ),
        DraggableCard(
          onLeftSwipe: () {
            setState(() {
              widget.feed.skip(widget.feed.currentPet);
              widget.feed.removeCurrentPet();
              widget.feed.updateList();
            });
          },
          onRightSwipe: () {
            setState(() {
              if (!widget.feed.liked.contains(widget.feed.currentPet)) {
                widget.feed.liked.add(widget.feed.currentPet);
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setStringList(
                      'liked',
                      widget.feed.liked
                          .map((animal) => animal.toString())
                          .toList());
                });
              }
              widget.feed.removeCurrentPet();
              widget.feed.updateList();
            });
          },
          onSwipe: (Offset offset) {
            setState(() {
              _backCardScale =
                  0.9 + (0.1 * (offset.distance / 150)).clamp(0.0, 0.1);
            });
          },
          notifier: widget.feed.notifier,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      DetailsPage(pet: widget.feed.currentPet))),
          child: PetCard(
            widget.feed.currentPet,
          ),
        ),
      ],
    );
  }

  _buildNoPetsLeftPage() {
    Size screenSize = MediaQuery.of(context).size;
    double _screenWidth = screenSize.width;
    double _screenHeight = screenSize.height;
    return Container(
      height: _screenHeight / 1.65,
      width: _screenWidth / 1.2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Icon(Icons.sentiment_dissatisfied, size: 90.0),
          Text("No more pets"),
          FlatButton(
            onPressed: () {
              setState(() {
                loading = true;
                widget.feed.reInitialize().then((result) {
                  if (result)
                    setState(() {
                      loading = false;
                    });
                });
              });
            },
            child: Text("Start over"),
          ),
        ],
      ),
    );
  }
}

/// Widget to allow for better handling of pet cards and swiping them.
class PetCard extends StatelessWidget {
  final Animal pet;
  PetCard(this.pet);

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double _screenWidth = screenSize.width;
    double _screenHeight = screenSize.height;

    var sideInfo = TextStyle(
      color: Colors.grey[600],
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0.0, 2.0),
            spreadRadius: 0.5,
            blurRadius: 4.0,
            color: Colors.black.withOpacity(.1),
          )
        ],
      ),
      height: _screenHeight / 1.65,
      width: _screenWidth / 1.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                height: _screenHeight / 1.65 - 110,
                decoration: BoxDecoration(
                  color: Colors.black,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(pet.info.imgUrl[0]),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: pet.info.imgUrl.map((_) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    width: 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Container(
                    child: Text(
                      '${pet.info.name},',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.headline,
                    ),
                  ),
                ),
                SizedBox(width: 5.0),
                Expanded(
                  child: Text(
                    pet.info.age,
                    overflow: TextOverflow.fade,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.subhead,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(pet.info.gender, style: sideInfo),
                Row(
                  children: <Widget>[
                    Icon(Icons.location_on, size: 15.0, color: Colors.grey),
                    Text(pet.info.cityState, style: sideInfo),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                pet.info.breed,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sideInfo,
              ),
            ),
          ),
          _buildTags(pet),
        ],
      ),
    );
  }

  Widget _buildTags(Animal pet) {
    if (pet.info.options.isEmpty) return SizedBox();
    return Container(
      padding: const EdgeInsets.only(left: 8.0),
      height: 30.0,
      child: Row(
        children: <Widget>[
          pet.spayedNeutered
              ? Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(pet.info.gender == 'Male' ? "Neutered" : "Spayed",
                      style: const TextStyle(
                          color: kPetThemecolor, fontWeight: FontWeight.bold)),
                )
              : SizedBox(),
          pet.info.options.length > 1
              ? Icon(
                  Icons.more,
                  color: kPetThemecolor,
                )
              : SizedBox(),
        ],
      ),
    );
  }
}
