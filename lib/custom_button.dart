import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final Color color;
  final Function onTap;
  final String? title;
  final double width;
  final double? height;
  final bool? loading;
  final Widget? titleWidget;
  final double? margin;
  const CustomButton(
      {Key? key,
      required this.color,
      required this.onTap,
      this.title,
      this.titleWidget,
      this.height,
      this.margin,
      this.loading,
      required this.width})
      : super(key: key);

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.color,
      margin: widget.margin != null
          ? EdgeInsets.all(widget.margin!)
          : EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: InkWell(
        onTap: () => widget.onTap(),
        child: Container(
            height: widget.height != null ? widget.height : 50,
            width: widget.width,
            child: Center(
                child: widget.loading != null && widget.loading!
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : widget.titleWidget != null
                        ? widget.titleWidget
                        : Text(widget.title!,
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)))),
      ),
    );
  }
}
