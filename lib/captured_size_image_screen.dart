import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pytorch_lite/pigeon.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:flutter/rendering.dart';
import '../../main.dart';
import 'colors.dart';
import 'utils.dart';

class CapturedSizeImage extends StatefulWidget {
  final bool fromGallery;
  final File imageFile;
  const CapturedSizeImage({
    Key? key,
    required this.imageFile,
    required this.fromGallery,
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
  double pix_to_mm = 0;
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
  double? x0_crp;
  double? y0_crp;
  bool _busy = false;
  File? _image;

  bool _canProcess = false;
  bool _isBusy = false;
  String? _text;
  CustomPaint? _customPaint;
  var interpreter;

  Uint8List? byteList;
  img.Image? rotatedImage;
  GlobalKey _imageKey = GlobalKey();

  ModelObjectDetection? objectModel;
  Uint8List? screen_shot;

  Future<void> _captureImage() async {
    try {
      RenderRepaintBoundary boundary =
          _imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      screen_shot = byteData!.buffer.asUint8List();
    } catch (e) {
      print(e);
    }
  }

  loadTfModel() async {
    objectModel = await PytorchLite.loadObjectDetectionModel(
      "assets/best_1.torchscript",
      1,
      640,
      640,
      labelPath: "assets/labels.txt",
    );
    print("MODEL LOADED");
    _captureImage();
  }

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
    // await GalleryRepository().addImageToGallery(file);
    return path;
  }

  _checkImageDimensions() async {
    var decodedImage =
        await decodeImageFromList(widget.imageFile.readAsBytesSync());
    print(decodedImage.width);
    print(decodedImage.height);
    if (decodedImage.height > decodedImage.width) {
      _wide = false;
    } else {
      _wide = true;
    }

    setState(() {});
  }

  measureSize() {
    print("Measure Length");
    measuredSizeMm = sqrt(pow(
                ((secondCircleX != null
                        ? secondCircleX!
                        : MediaQuery.of(context).size.width) -
                    (firstCircleX != null ? firstCircleX! : 0)),
                2) +
            pow(
                ((secondCircleY != null
                        ? secondCircleY!
                        : MediaQuery.of(context).size.height) -
                    (firstCircleY != null
                        ? firstCircleY!
                        : MediaQuery.of(context).size.height)),
                2)) *
        (1 / zoomScale) *
        pix_to_mm;
    // (coinRealRadiusMm / coinVirtualRadius!);
    measuredSizeInch = sqrt(pow(
                ((secondCircleX != null
                        ? secondCircleX!
                        : MediaQuery.of(context).size.width) -
                    (firstCircleX != null ? firstCircleX! : 0)),
                2) +
            pow(
                ((secondCircleY != null
                        ? secondCircleY!
                        : MediaQuery.of(context).size.height) -
                    (firstCircleY != null
                        ? firstCircleY!
                        : MediaQuery.of(context).size.height)),
                2)) *
        (1 / zoomScale) *
        (pix_to_mm / 25.4);

    // print(measuredSizeInch);

    // print(firstCircleX);
    // print(secondCircleX);
    // (coinRealRadiusInch / coinVirtualRadius!);

    // pix_to_inch;

    setState(() {});
  }

  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null) return [];
    if (_imageHeight == null || _imageWidth == null) return [];

    Color blue = const Color.fromRGBO(37, 213, 253, 1.0);

    double factorX = (screen.width / (_imageWidth!));

    double fac1 = _imageWidth! / 640;
    double fac2 = _imageHeight! / 640;

    bool flg = true;
    return _recognitions.map<Widget>((result) {
      double left_ = ((((result.rect.left * 640) * fac1)));

      double y_val = ((((result.rect.top * 640) * fac2)));
      double top_ = y_val;

      double h_ = ((result.rect.height * 640) * fac2);
      double w_ = ((result.rect.width * 640) * fac1);

      double coin_dia = (w_ + h_) / 2;
      if (flg) {
        pix_to_mm = (23.8 / ((coin_dia - 3.7)));
        flg = false;
      } else {
        left_ = 0;
        top_ = 0;
        h_ = 0;
        w_ = 0;
      }
      // print(w_);

      return Positioned(
          left: (left_),
          top: (top_), //
          child: GestureDetector(
            //onPanUpdate: (event) => imageClick(event),
            child: Transform.scale(
              scale: _scaleFactor,
              child: Container(
                height: (h_),
                width: (w_),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: Colors.red,
                    width: 1,
                  ),
                ),
              ),
            ),
          ));
    }).toList();
  }

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    loadTfModel();
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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light));
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
                              child: RepaintBoundary(
                                key: _imageKey,
                                child: Image.file(
                                  widget.imageFile,
                                  fit: BoxFit.contain,
                                  // alignment: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_recognitions != null)
                          ...renderBoxes(MediaQuery.of(context).size),
                        // Container(
                        //     decoration: BoxDecoration(
                        //         image: DecorationImage(
                        //             alignment: Alignment.topCenter,
                        //             image: MemoryImage(_recognitions),
                        //             fit: BoxFit.fill)),
                        //     child: Opacity(
                        //         opacity: 0.3, child: Image.file(_image!))),
                        // !showCoinSelection && coinVirtualRadius != null
                        //     ? Transform(
                        //         alignment: Alignment.topCenter,
                        //         transform: Matrix4.identity()
                        //           ..translate(
                        //               firstCircleX != null
                        //                   ? firstCircleX! - 25
                        //                   : 25.0,
                        //               firstCircleY != null
                        //                   ? firstCircleY! + 25
                        //                   : MediaQuery.of(context).size.height -
                        //                       175,
                        //               0.0)
                        //           ..rotateZ(atan2(
                        //                   (secondCircleY != null
                        //                           ? secondCircleY!
                        //                           : MediaQuery.of(context)
                        //                                   .size
                        //                                   .height -
                        //                               200) -
                        //                       (firstCircleY != null
                        //                           ? firstCircleY!
                        //                           : MediaQuery.of(context)
                        //                                   .size
                        //                                   .height -
                        //                               200),
                        //                   (secondCircleX != null
                        //                           ? secondCircleX!
                        //                           : MediaQuery.of(context)
                        //                                   .size
                        //                                   .width -
                        //                               110) -
                        //                       (firstCircleX != null
                        //                           ? firstCircleX!
                        //                           : 50)) -
                        //               1.5708),
                        //         child: Image.asset(
                        //           'assets/images/ruler4.png',
                        //           color: MyColors.primaryWithDarkBackground,
                        //           width: 100,
                        //           height: sqrt(pow(
                        //                   (secondCircleX != null
                        //                           ? secondCircleX!
                        //                           : MediaQuery.of(context)
                        //                                   .size
                        //                                   .width -
                        //                               110) -
                        //                       (firstCircleX != null
                        //                           ? firstCircleX!
                        //                           : 50),
                        //                   2) +
                        //               pow(
                        //                   (secondCircleY != null
                        //                           ? secondCircleY!
                        //                           : MediaQuery.of(context)
                        //                                   .size
                        //                                   .height -
                        //                               200) -
                        //                       (firstCircleY != null
                        //                           ? firstCircleY!
                        //                           : MediaQuery.of(context)
                        //                                   .size
                        //                                   .height -
                        //                               200),
                        //                   2)),
                        //           fit: BoxFit.cover,
                        //         ),
                        //       )
                        //     : Container(),
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
                            : (MediaQuery.of(context).size.height / 2) - 35,
                        left: coinLeftPosition != null
                            ? coinLeftPosition
                            : (MediaQuery.of(context).size.width / 2) - 35,
                        child: GestureDetector(
                          onPanUpdate: (event) {
                            setState(() {
                              coinTopPosition = coinTopPosition != null
                                  ? coinTopPosition! + event.delta.dy
                                  : (MediaQuery.of(context).size.height / 2) -
                                      35 +
                                      event.delta.dy;

                              coinLeftPosition = coinLeftPosition != null
                                  ? coinLeftPosition! + event.delta.dx
                                  : (MediaQuery.of(context).size.width / 2) -
                                      35 +
                                      event.delta.dx;
                            });
                          },
                          child: Transform.scale(
                            scale: _scaleFactor,
                            child: Container(
                              height: 70,
                              width: 70,
                              decoration: BoxDecoration(
                                  border: Border(
                                      left: BorderSide(color: Colors.white),
                                      right: BorderSide(color: Colors.white))),
                              child: Center(
                                child: Container(
                                  height: 70,
                                  width: 70,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white38,
                                      border:
                                          Border.all(color: Colors.white38)),
                                ),
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
                        bottom: 5,
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                coinTopPosition = coinTopPosition != null
                                    ? coinTopPosition! - 1
                                    : (MediaQuery.of(context).size.height / 2) -
                                        35 -
                                        1;
                                setState(() {});
                              },
                              child: Icon(
                                Icons.keyboard_arrow_up_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    coinLeftPosition = coinLeftPosition != null
                                        ? coinLeftPosition! - 1
                                        : (MediaQuery.of(context).size.width /
                                                2) -
                                            35 -
                                            1;
                                    setState(() {});
                                  },
                                  child: Icon(
                                    Icons.chevron_left,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                InkWell(
                                    onTap: () {
                                      setState(() {
                                        _scaleFactor = _scaleFactor -
                                            (_scaleFactor * 0.02);
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
                                        _scaleFactor = _scaleFactor +
                                            (_scaleFactor * 0.02);
                                      });
                                    },
                                    child: Icon(
                                      Icons.add_box_rounded,
                                      size: 30,
                                      color: Colors.white,
                                    )),
                                SizedBox(
                                  width: 5,
                                ),
                                InkWell(
                                  onTap: () {
                                    coinLeftPosition = coinLeftPosition != null
                                        ? coinLeftPosition! + 1
                                        : (MediaQuery.of(context).size.width /
                                                2) -
                                            35 +
                                            1;
                                    setState(() {});
                                  },
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            InkWell(
                              onTap: () {
                                coinTopPosition = coinTopPosition != null
                                    ? coinTopPosition! + 1
                                    : (MediaQuery.of(context).size.height / 2) -
                                        35 +
                                        1;
                                setState(() {});
                              },
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
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
                          // print("SSSSSSSSS");
                          // Matrix4 matrix4 = transformController.value;
                          // if (matrix4.entry(0, 0) == 2) {
                          // } else {
                          //   matrix4.setEntry(0, 0, 2);
                          //   matrix4.setEntry(1, 1, 2);
                          //   matrix4.setEntry(2, 2, 2);
                          //   matrix4.setEntry(0, 3, -details.globalPosition.dx);
                          //   matrix4.setEntry(1, 3, -details.globalPosition.dy);
                          //   animateScale = Matrix4Tween(
                          //     end: matrix4,
                          //     begin: Matrix4.identity(),
                          //   ).animate(_animationController);

                          //   animateScale!.addListener(() {
                          //     transformController.value = animateScale!.value;
                          //   });
                          //   _animationController.forward();

                          //   setState(() {
                          //     // zoomScale = 2;
                          //     // showCoinSelectionMessage = false;
                          //     // coinLeftPosition = details.globalPosition.dx - 35;
                          //     // coinTopPosition = details.globalPosition.dy - 70;
                          //     // showCoinSelection = true;
                          //   });
                          // }
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
                              if (widget.fromGallery) {
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
                              }
                            },
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/download.png',
                                  height: 24,
                                  width: 24,
                                  color:
                                      widget.fromGallery ? Colors.grey : null,
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Submit \nTicket',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: widget.fromGallery
                                          ? Colors.grey
                                          : Colors.white),
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          InkWell(
                            onTap: () async {
                              setState(() {
                                showLoading = true;
                              });
                              final bytes = await Utils.capture(renderKey);
                              setState(() {
                                modifiedImage = bytes;
                              });
                              await saveImage();
                              setState(() {
                                showLoading = false;
                              });
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Image Saved',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Icon(Icons.file_download_done_rounded,
                                        color: Colors.green)
                                  ],
                                ),
                              ));
                            },
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/gallery.png',
                                  height: 24,
                                  width: 24,
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text('Save to\nGallery',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white))
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          InkWell(
                            onTap: () async {
                              // setState(() {
                              //   showLoading = true;
                              // });
                              // final bytes = await Utils.capture(renderKey);
                              // setState(() {
                              //   modifiedImage = bytes;
                              // });
                              // String paath = await saveImage();
                              // await Share.shareXFiles([XFile(paath)],
                              //     text: 'Check my captured fish');
                              // setState(() {
                              //   showLoading = false;
                              // });
                            },
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/share.png',
                                  height: 24,
                                  width: 24,
                                ),
                                SizedBox(height: 5),
                                Text('Share',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white))
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context, {
                                'submit': false,
                              });
                            },
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/discard.png',
                                  height: 24,
                                  width: 24,
                                ),
                                SizedBox(height: 5),
                                Text('Discard',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white))
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
                            onTap: () async {
                              _animationController.forward();

                              // File? imageF = File(widget.imageFile.path);
                              // var byte = imageF.readAsBytesSync();
                              var image_n = img.decodeImage(screen_shot!);

                              if (image_n!.width > image_n.height) {
                                // image_ = img.copyRotate(image_n, 90);
                                rotatedImage =
                                    img.copyRotate(image_n, angle: 90);
                              } else {
                                rotatedImage = image_n;
                              }

                              _imageWidth = rotatedImage!.width.toDouble();
                              _imageHeight = rotatedImage!.height.toDouble();

                              double half_w = _imageWidth! / 2;
                              double half_h = _imageHeight! / 2;

                              x0_crp = 0; //half_w - 320
                              y0_crp = half_h - 320;
                              var cropImage;
                              if (false) {
                                //_imageHeight! > 640
                                cropImage = img.copyCrop(rotatedImage!,
                                    x: x0_crp!.toInt(),
                                    y: y0_crp!.toInt(),
                                    width: _imageWidth!.toInt(),
                                    height: _imageHeight!.toInt() - 100);
                              } else {
                                x0_crp = 0;
                                y0_crp = 0;
                                cropImage = rotatedImage;
                              }

                              List<int> pngBytes = img.encodeJpg(cropImage!);
                              byteList = Uint8List.fromList(pngBytes);

                              _imageWidth = cropImage!.width.toDouble();
                              _imageHeight = cropImage!.height.toDouble();

                              List<ResultObjectDetection?> recognitions =
                                  await objectModel!.getImagePrediction(
                                      byteList!,
                                      minimumScore: 0.8,
                                      iOUThreshold: 0.9);

                              setState(() {
                                coinVirtualRadius =
                                    _scaleFactor * 35 * (1 / zoomScale);
                                showCoinSelection = false;
                                print(coinVirtualRadius);
                                zoomScale = 1;
                                _recognitions = recognitions;

                                // zoomScale = 1;
                                // showCoinSelection = !showCoinSelection;
                                // showCoinSelectionMessage = false;

                                measureSize();
                                // print("DDDDDDDDDDDDDDDDDDDD  Continue---");
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
