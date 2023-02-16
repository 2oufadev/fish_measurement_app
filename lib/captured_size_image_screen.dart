import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:showcaseview/showcaseview.dart';

import '../../main.dart';
import 'colors.dart';
import 'utils.dart';

class CapturedSizeImage extends StatefulWidget {
  var imageFile;
  List<double> coords;
  CapturedSizeImage({
    Key? key,
    required this.imageFile,
    required this.coords
  }) : super(key: key);

  @override
  _CapturedSizeImageState createState() => _CapturedSizeImageState();
}

class _CapturedSizeImageState extends State<CapturedSizeImage>
    with TickerProviderStateMixin {
  bool showInstructions = false;
  bool showCoinSelection = false;
  bool showCoinSelectionMessage = true;
  double? coinTopPosition;
  double? coinLeftPosition;
  double? coinSize;
  double _scaleFactor = 1.0;
  double _baseScaleFactor = 1.0;
  double coinRealRadiusMm = 11.94;
  double coinRealRadiusInch = 0.47007874;
  double? coinVirtualRadius;
  double? firstCircleX;
  double? firstCircleY;
  double? secondCircleX;
  double? secondCircleY;
  double? horizontalLineCoor;
  double? verticalLineCoor;
  double? measuredSizeMm;
  double? measuredSizeInch;
  bool _wide = false;
  bool showLoading = false;
  String unit = 'MM';
  int selectedUnitGroupValue = 2;
  GlobalKey renderKey = GlobalKey();
  GlobalKey coinKey = GlobalKey();
  Uint8List? modifiedImage;
  double zoomScale = 1;
  bool horizontal = true;
  BuildContext? myContext;
  TransformationController transformController = TransformationController();
  Animation<Matrix4>? animateScale;
  late final AnimationController _animationController;
  var _recognitions;
  double? _imageHeight;
  double? _imageWidth;
  bool _busy = false;
  File? _image;
  bool _canProcess = false;
  bool _isBusy = false;
  String? _text;
  CustomPaint? _customPaint;
  var interpreter;


  Future<String> saveImage() async {
    String path = '';
    Directory? directory = Platform.isAndroid
        ? await getExternalStorageDirectory() //FOR ANDROID
        : await getApplicationSupportDirectory(); //FOR iOS
    final String filePath =
        '${directory!.path}/${DateTime.now().millisecondsSinceEpoch}.png';

    final File file = File(filePath);
    if (!await file.exists()) {
      await file.writeAsBytes(modifiedImage!).then((value) {
        print(value.path);
        path = value.path;
        return path;
      });
    }
    return path;
  }

  _checkImageDimensions() async {
    var decodedImage =//widget.imageFile;
    await decodeImageFromList(widget.imageFile);
    print(decodedImage.width);
    print(decodedImage.height);
    if (decodedImage.height > decodedImage.width) {
      _wide = false;
    } else {
      _wide = true;
    }
    // coinTopPosition = widget.coords[1];
    // coinLeftPosition = widget.coords[0];
    setState(() {});
  }

  measureSize() {
    measuredSizeMm = sqrt(pow(
        ((secondCircleX != null
            ? secondCircleX!
            : MediaQuery.of(context).size.width - 110) -
            (firstCircleX != null ? firstCircleX! : 50)),
        2) +
        pow(
            ((secondCircleY != null
                ? secondCircleY!
                : MediaQuery.of(context).size.height - 200) -
                (firstCircleY != null
                    ? firstCircleY!
                    : MediaQuery.of(context).size.height - 200)),
            2)) *
        (1 / zoomScale) *
        (coinRealRadiusMm / coinVirtualRadius!);
    measuredSizeInch = sqrt(pow(
        ((secondCircleX != null
            ? secondCircleX!
            : MediaQuery.of(context).size.width - 110) -
            (firstCircleX != null ? firstCircleX! : 50)),
        2) +
        pow(
            ((secondCircleY != null
                ? secondCircleY!
                : MediaQuery.of(context).size.height - 200) -
                (firstCircleY != null
                    ? firstCircleY!
                    : MediaQuery.of(context).size.height - 200)),
            2)) *
        (1 / zoomScale) *
        (coinRealRadiusInch / coinVirtualRadius!);

    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    // WidgetsBinding.instance.addPostFrameCallback(
    //   (_) => ShowCaseWidget.of(myContext!).startShowCase([coinKey]),
    // );
    super.initState();
    _checkImageDimensions();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _canProcess = false;
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (firstCircleX == null ||
        secondCircleX == null ||
        firstCircleY == null ||
        secondCircleY == null) {
      setState(() {
        if (firstCircleX == null) {
          firstCircleX = 50;
        }
        if (secondCircleX == null) {
          secondCircleX = MediaQuery.of(context).size.width - 110;
        }

        if (firstCircleY == null) {
          firstCircleY = MediaQuery.of(context).size.height - 200;
        }

        if (secondCircleY == null) {
          secondCircleY = MediaQuery.of(context).size.height - 200;
        }
      });
    }
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ShowCaseWidget(
          onFinish: () {
            setState(() {
              showInstructions = false;
            });
          },
          builder: Builder(builder: (context) {
            myContext = context;
            return Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    key: renderKey,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RotatedBox(
                            quarterTurns: _wide ? 1 : 0,
                            child: InteractiveViewer(
                              scaleEnabled: true,
                              minScale: 1,
                              maxScale: 2.5,
                              transformationController: transformController,
                              onInteractionUpdate: (details) {
                                setState(() {
                                  zoomScale = transformController.value.row0.r;
                                  print(zoomScale);
                                });
                                if (!showInstructions &&
                                    !showCoinSelectionMessage &&
                                    !showCoinSelection) {
                                  measureSize();
                                }
                              },
                              child: Image.memory(
                                widget.imageFile,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                        if (_recognitions != null)
                          Container(
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      alignment: Alignment.topCenter,
                                      image: MemoryImage(_recognitions),
                                      fit: BoxFit.fill)),
                              child: Opacity(
                                  opacity: 0.3, child: Image.file(_image!))),
                        !showCoinSelection && coinVirtualRadius != null
                            ? Transform(
                          alignment: Alignment.topCenter,
                          transform: Matrix4.identity()
                            ..translate(
                                firstCircleX != null
                                    ? firstCircleX! - 25
                                    : 25.0,
                                firstCircleY != null
                                    ? firstCircleY! + 25
                                    : MediaQuery.of(context).size.height -
                                    175,
                                0.0)
                            ..rotateZ(atan2(
                                (secondCircleY != null
                                    ? secondCircleY!
                                    : MediaQuery.of(context)
                                    .size
                                    .height -
                                    200) -
                                    (firstCircleY != null
                                        ? firstCircleY!
                                        : MediaQuery.of(context)
                                        .size
                                        .height -
                                        200),
                                (secondCircleX != null
                                    ? secondCircleX!
                                    : MediaQuery.of(context)
                                    .size
                                    .width -
                                    110) -
                                    (firstCircleX != null
                                        ? firstCircleX!
                                        : 50)) -
                                1.5708),
                          child: Image.asset(
                            'assets/images/ruler4.png',
                            color: MyColors.primaryWithDarkBackground,
                            width: 100,
                            height: sqrt(pow(
                                (secondCircleX != null
                                    ? secondCircleX!
                                    : MediaQuery.of(context)
                                    .size
                                    .width -
                                    110) -
                                    (firstCircleX != null
                                        ? firstCircleX!
                                        : 50),
                                2) +
                                pow(
                                    (secondCircleY != null
                                        ? secondCircleY!
                                        : MediaQuery.of(context)
                                        .size
                                        .height -
                                        200) -
                                        (firstCircleY != null
                                            ? firstCircleY!
                                            : MediaQuery.of(context)
                                            .size
                                            .height -
                                            200),
                                    2)),
                            fit: BoxFit.cover,
                          ),
                        )
                            : Container(),
                        !showCoinSelection && coinVirtualRadius != null
                            ? Positioned(
                            left: firstCircleX != null ? firstCircleX : 50,
                            top: firstCircleY != null
                                ? firstCircleY
                                : MediaQuery.of(context).size.height - 200,
                            child: GestureDetector(
                                onPanUpdate: (event) {
                                  setState(() {
                                    firstCircleX = firstCircleX != null
                                        ? firstCircleX! + event.delta.dx
                                        : 50 + event.delta.dy;

                                    firstCircleY = firstCircleY != null
                                        ? firstCircleY! + event.delta.dy
                                        : (MediaQuery.of(context)
                                        .size
                                        .height -
                                        200) +
                                        event.delta.dy;

                                    if (horizontal) {
                                      secondCircleY = firstCircleY;
                                    } else {
                                      secondCircleX = firstCircleX;
                                    }
                                  });

                                  if (firstCircleX != null &&
                                      firstCircleY != null &&
                                      secondCircleX != null &&
                                      secondCircleY != null) {
                                    measureSize();
                                  }
                                },
                                child: Image.asset(
                                  'assets/images/EllipseCenter.png',
                                  height: 50,
                                  width: 50,
                                )))
                            : Container(),
                        !showCoinSelection && coinVirtualRadius != null
                            ? Positioned(
                            left: secondCircleX != null
                                ? secondCircleX
                                : MediaQuery.of(context).size.width - 110,
                            top: secondCircleY != null
                                ? secondCircleY
                                : MediaQuery.of(context).size.height - 200,
                            child: GestureDetector(
                                onPanUpdate: (event) {
                                  setState(() {
                                    secondCircleX = secondCircleX != null
                                        ? secondCircleX! + event.delta.dx
                                        : MediaQuery.of(context)
                                        .size
                                        .width -
                                        110 +
                                        event.delta.dy;

                                    secondCircleY = secondCircleY != null
                                        ? secondCircleY! + event.delta.dy
                                        : (MediaQuery.of(context)
                                        .size
                                        .height -
                                        200) +
                                        event.delta.dy;
                                    if (horizontal) {
                                      firstCircleY = secondCircleY;
                                    } else {
                                      firstCircleX = secondCircleX;
                                    }
                                  });
                                  if (firstCircleX != null &&
                                      firstCircleY != null &&
                                      secondCircleX != null &&
                                      secondCircleY != null) {
                                    measureSize();
                                  }
                                },
                                child: Image.asset(
                                  'assets/images/EllipseCenter.png',
                                  height: 50,
                                  width: 50,
                                )))
                            : Container(),
                        measuredSizeMm != null && !showCoinSelection && _wide
                            ? Positioned(
                            top: 30,
                            width: MediaQuery.of(context).size.width,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(0, 0, 0, 0.5),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${measuredSizeMm!.toStringAsFixed(2)} ',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'MM',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        ' / ',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${measuredSizeInch!.toStringAsFixed(2)} ',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Inch',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ))
                            : measuredSizeMm != null && !showCoinSelection
                            ? Align(
                          alignment: Alignment.centerLeft,
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: Padding(
                              padding:
                              const EdgeInsets.only(bottom: 10.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(
                                          0, 0, 0, 0.5),
                                      borderRadius:
                                      BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${measuredSizeMm!.toStringAsFixed(2)} ',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight:
                                              FontWeight.bold),
                                        ),
                                        Text(
                                          'MM',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight:
                                              FontWeight.bold),
                                        ),
                                        Text(
                                          ' / ',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight:
                                              FontWeight.bold),
                                        ),
                                        Text(
                                          '${measuredSizeInch!.toStringAsFixed(2)} ',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight:
                                              FontWeight.bold),
                                        ),
                                        Text(
                                          'Inch',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight:
                                              FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            : Container()
                      ],
                    ),
                  ),
                ),
                showCoinSelection
                    ? Positioned(
                    top: coinTopPosition != null
                        ? coinTopPosition
                        : (MediaQuery.of(context).size.height / 2) - 55,
                    left: coinLeftPosition != null
                        ? coinLeftPosition
                        : (MediaQuery.of(context).size.width / 2) - 25,
                    child: GestureDetector(
                      onPanUpdate: (event) {
                        setState(() {
                          coinTopPosition = coinTopPosition != null
                              ? coinTopPosition! + event.delta.dy
                              : (MediaQuery.of(context).size.height / 2) -
                              55 +
                              event.delta.dy;

                          coinLeftPosition = coinLeftPosition != null
                              ? coinLeftPosition! + event.delta.dx
                              : (MediaQuery.of(context).size.width / 2) -
                              55 +
                              event.delta.dx;
                        });
                      },
                      child: Transform.scale(
                        scale: _scaleFactor,
                        child: Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/images/Ellipse.png',
                            fit: BoxFit.fill,
                            height: 70,
                            width: 70,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ))
                    : Container(),
                showCoinSelection
                    ? Positioned(
                    bottom: 40,
                    left: 20,
                    height: 30,
                    child: Center(
                      child: GestureDetector(
                          onTap: () {
                            _animationController.animateBack(0.0);
                            setState(() {
                              zoomScale = 1;
                              showCoinSelection = false;
                              showCoinSelectionMessage = true;
                            });
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          )),
                    ))
                    : Container(),
                showCoinSelection
                    ? Positioned(
                    bottom: 40,
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                            onTap: () {
                              setState(() {
                                _scaleFactor =
                                    _scaleFactor - (_scaleFactor * 0.025);
                              });
                            },
                            child: Icon(
                              Icons.indeterminate_check_box_rounded,
                              size: 30,
                              color: Colors.white,
                            )),
                        SizedBox(width: 5),
                        InkWell(
                            onTap: () {
                              setState(() {
                                _scaleFactor =
                                    _scaleFactor + (_scaleFactor * 0.025);
                              });
                            },
                            child: Icon(
                              Icons.add_box_rounded,
                              size: 30,
                              color: Colors.white,
                            )),
                      ],
                    ))
                    : Container(),
                showCoinSelection
                    ? Positioned(
                  bottom: 40,
                  right: 20,
                  height: 30,
                  child: Center(
                    child: InkWell(
                        onTap: () {
                          print(_animationController.value);
                          _animationController.animateBack(0.0);
                          setState(() {
                            coinVirtualRadius =
                                _scaleFactor * 35 * (1 / zoomScale);
                            showCoinSelection = false;
                            print(coinVirtualRadius);
                            zoomScale = 1;

                            measureSize();
                          });
                        },
                        child: Text(
                          'Save',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        )),
                  ),
                )
                    : Container(),
                // showInstructions
                //     ? Positioned.fill(
                //         child: Container(
                //         color: Color.fromRGBO(0, 0, 0, 0.5),
                //       ))
                //     : Container(),
                // showInstructions
                //     ? Positioned(
                //         top: 30,
                //         left: 20,
                //         child: GestureDetector(
                //           onTap: () {
                //             setState(() {
                //               showInstructions = false;
                //             });
                //           },
                //           child: Text(
                //             'Skip',
                //             style: TextStyle(
                //                 color: Colors.white,
                //                 fontSize: 16,
                //                 fontWeight: FontWeight.bold),
                //           ),
                //         ))
                //     : Container(),
                showInstructions
                    ? Align(
                    alignment: Alignment.center,
                    child: Showcase(
                      key: coinKey,
                      onTargetClick: () {
                        setState(() {
                          showInstructions = false;
                        });
                      },
                      onToolTipClick: () {
                        setState(() {
                          showInstructions = false;
                        });
                      },
                      targetPadding: EdgeInsets.all(-2),
                      disposeOnTap: true,
                      description: 'Tap on the coin',
                      targetShapeBorder: CircleBorder(),
                      child: Image.asset(
                        'assets/images/coin.png',
                        fit: BoxFit.cover,
                        height: 50,
                        width: 50,
                      ),
                    ))
                    : Container(),
                showLoading
                    ? Positioned.fill(
                  child: Container(
                    color: Color.fromRGBO(0, 0, 0, 0.5),
                    child: Center(
                        child: SizedBox(
                          height: 40,
                          width: 40,
                          child: LoadingIndicator(
                              indicatorType: Indicator.ballSpinFadeLoader,

                              /// Required, The loading type of the widget
                              colors: [MyColors.primaryWithDarkBackground],

                              /// Optional, The color collections
                              strokeWidth: 2,

                              /// Optional, The stroke of the line, only applicable to widget which contains line
                              backgroundColor: Colors.transparent,

                              /// Optional, Background of the widget
                              pathBackgroundColor: Colors.white

                            /// Optional, the stroke backgroundColor
                          ),
                        )),
                  ),
                )
                    : Container(),
                !showInstructions && showCoinSelectionMessage
                    ? Positioned.fill(child: GestureDetector(
                  onTapDown: (details) {
                    print(details.globalPosition);
                    Matrix4 matrix4 = transformController.value;
                    if (matrix4.entry(0, 0) == 2) {
                    } else {
                      matrix4.setEntry(0, 0, 2);
                      matrix4.setEntry(1, 1, 2);
                      matrix4.setEntry(2, 2, 2);
                      matrix4.setEntry(0, 3, -details.globalPosition.dx);
                      matrix4.setEntry(1, 3, -details.globalPosition.dy);
                      animateScale = Matrix4Tween(
                        end: matrix4,
                        begin: Matrix4.identity(),
                      ).animate(_animationController);

                      animateScale!.addListener(() {
                        transformController.value = animateScale!.value;
                      });
                      _animationController.forward();

                      setState(() {
                        zoomScale = 2;
                        showCoinSelectionMessage = false;
                        coinLeftPosition = details.globalPosition.dx - 35;
                        coinTopPosition = details.globalPosition.dy - 70;
                        showCoinSelection = true;
                      });
                    }
                  },
                ))
                    : Container(),
                Positioned(
                  right: 10,
                  top: 0,
                  height: MediaQuery.of(context).size.height - 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding:
                        EdgeInsets.symmetric(horizontal: 5, vertical: 30),
                        decoration: BoxDecoration(
                            color: Color.fromRGBO(0, 0, 0, 0.5),
                            borderRadius: BorderRadius.circular(50)),
                        child: Column(children: [
                          InkWell(
                            onTap: () async {
                              setState(() {
                                showLoading = true;
                              });
                              final bytes = await Utils.capture(renderKey);
                              setState(() {
                                modifiedImage = bytes;
                              });
                              String path = await saveImage();

                              Navigator.pop(context, {
                                'submit': true,
                                'measuredSizeMm': measuredSizeMm,
                                'measuredSizeInch': measuredSizeInch,
                                'imgFilePath': path
                              });
                            },
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/download.png',
                                  height: 24,
                                  width: 24,
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Submit \nTicket',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          InkWell(
                            onTap: () async {},
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/gallery.png',
                                  height: 24,
                                  width: 24,
                                  color: Colors.grey,
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text('Save to\nGallery',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey))
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          InkWell(
                            onTap: () async {},
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/share.png',
                                  height: 24,
                                  width: 24,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 5),
                                Text('Share',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey))
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          InkWell(
                            onTap: () {},
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/discard.png',
                                  height: 24,
                                  width: 24,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 5),
                                Text('Discard',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey))
                              ],
                            ),
                          ),
                          // SizedBox(height: 20),
                          // InkWell(
                          //   onTap: () {
                          //     _chooseMeasureUnit();
                          //   },
                          //   child: Column(
                          //     children: [
                          //       Image.asset(
                          //         'assets/images/ruler.png',
                          //         height: 24,
                          //         width: 24,
                          //       ),
                          //       SizedBox(height: 5),
                          //       Text('Unit',
                          //           textAlign: TextAlign.center,
                          //           style: TextStyle(fontSize: 12, color: Colors.white))
                          //     ],
                          //   ),
                          // ),
                          SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              _animationController.forward();

                              setState(() {
                                zoomScale = 2;
                                showCoinSelection = !showCoinSelection;
                                showCoinSelectionMessage = false;
                              });
                            },
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/coin.png',
                                  height: 24,
                                  width: 24,
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text('Coin\nDetection',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white))
                              ],
                            ),
                          ),

                          !showCoinSelection && coinVirtualRadius != null
                              ? Column(
                            children: [
                              SizedBox(height: 20),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (horizontal) {
                                      secondCircleX = firstCircleX;
                                      secondCircleY = firstCircleY! - 200;
                                    } else {
                                      secondCircleY = firstCircleY;
                                      secondCircleX = firstCircleX! + 200;
                                    }
                                    horizontal = !horizontal;
                                    print(horizontal);
                                  });
                                },
                                child: Column(
                                  children: [
                                    Icon(Icons.rotate_right_rounded,
                                        size: 30, color: Colors.white),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text('Measure\nTools',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white))
                                  ],
                                ),
                              ),
                            ],
                          )
                              : Container(),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () => predictImagePicker(),
        //   tooltip: 'Pick Image',
        //   child: Icon(Icons.image),
        // ),
      ),
    );
  }
}
