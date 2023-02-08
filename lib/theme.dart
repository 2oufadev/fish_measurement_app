import 'package:flutter/material.dart';

class ThemeUtils {
  ThemeData buildTheme() {
    final ThemeData base = ThemeData.light();

    // // Typography
    // String fontFamily = Strings.fontFamily;
    // //get(fields, ['fontFamily'], Strings.fontFamily);
    // String fontFamilyBody = Strings.fontFamily;

    Color displayColor = Colors.black;
    Color bodyColor = Colors.black;
    Color cardColor = Colors.white;

    // Text theme body
    TextTheme textTheme = base.textTheme;

    // Colors Schema
    ColorScheme baseSchema = base.colorScheme;

    Color primary = Color.fromRGBO(63, 141, 143, 1);

    ColorScheme _fishpixColorScheme = ColorScheme(
      primary: primary,
      primaryVariant: baseSchema.primaryVariant,
      secondary: baseSchema.secondary,
      secondaryVariant: baseSchema.secondaryVariant,
      surface: baseSchema.surface,
      background: baseSchema.background,
      error: baseSchema.error,
      onPrimary: baseSchema.onPrimary,
      onSecondary: baseSchema.onSecondary,
      onSurface: baseSchema.onSurface,
      onBackground: baseSchema.onBackground,
      onError: baseSchema.onError,
      brightness: Brightness.light,
    );

    // Appbar
    Color appbarBackgroundColor = Colors.white;
    Color appBarIconColor = Colors.black;

    Color appBarTextColor = Colors.black;

    Color appBarShadowColor = Colors.black;

    double appBarElevation = 4;

    // Scaffold
    Color scaffoldBackgroundColor = Colors.white;

    // Text Fields
    String textFieldsType = 'filled';
    double textFieldsBorderRadius = 8;
    double textFieldsBorderWidth = 1;
    Color textFieldsBorderColor = Colors.black;
    Color textFieldsLabelColor = displayColor;

    double textFieldsLabelFontSize = 14;
    int textFieldsLabelFontWeight = 3;

    double textFieldsPaddingLeft = 0;
    double textFieldsPaddingRight = 0;
    double textFieldsPaddingBottom = 0;
    double textFieldsPaddingTop = 0;

    // Button
    double buttonBorderRadius = 8;

    // Divider
    Color dividerColor = Color.fromRGBO(239, 239, 239, 1);

    // Full theme all app
    TextTheme _textTheme = _buildTextTheme(textTheme, displayColor, bodyColor);

    // Status bar
    int brightnessLight = 1;
    int brightnessDark = 0;

    return base.copyWith(
      cardColor: cardColor,
      colorScheme: _fishpixColorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      // textTheme: _textTheme,
      iconTheme: _customIconTheme(base.iconTheme, bodyColor),
      bottomSheetTheme:
          BottomSheetThemeData(backgroundColor: scaffoldBackgroundColor),
      appBarTheme: AppBarTheme(
        backgroundColor: appbarBackgroundColor,
        iconTheme: _customIconTheme(base.iconTheme, appBarIconColor),
        // brightness: Brightness.values[brightnessLight],
        // textTheme: TextTheme(
        //   headline6: _textTheme.headline6.copyWith(
        //       fontWeight: FontWeight.w500,
        //       fontSize: 16,
        //       color: appBarTextColor),
        // ),
        // titleTextStyle: _textTheme.subtitle1.copyWith(
        //     fontWeight: FontWeight.w500, fontSize: 16, color: appBarTextColor),
        shadowColor: appBarShadowColor,
        elevation: appBarElevation,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        enabledBorder: _buildInputBorder(
          textFieldsType,
          textFieldsBorderRadius,
          textFieldsBorderColor,
          textFieldsBorderWidth,
        ),
        border: _buildInputBorder(
          textFieldsType,
          textFieldsBorderRadius,
          textFieldsBorderColor,
          textFieldsBorderWidth,
        ),
        focusedBorder: _buildInputBorder(
          textFieldsType,
          textFieldsBorderRadius,
          textFieldsBorderColor,
          textFieldsBorderWidth,
        ),
        errorBorder: _buildInputBorder(
          textFieldsType,
          textFieldsBorderRadius,
          textFieldsBorderColor,
          textFieldsBorderWidth,
        ),
        labelStyle: TextStyle(
          color: textFieldsLabelColor,
          fontWeight: FontWeight.values[textFieldsLabelFontWeight],
          fontSize: textFieldsLabelFontSize,
        ),
        contentPadding: EdgeInsetsDirectional.only(
          start: textFieldsPaddingLeft,
          end: textFieldsPaddingRight,
          top: textFieldsPaddingTop,
          bottom: textFieldsPaddingBottom,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(buttonBorderRadius)),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(buttonBorderRadius)),
          ),
        ),
      ),
      dividerColor: dividerColor,
      primaryColor: primary,
    );
  }

  InputBorder _buildInputBorder(
    String textFieldsType,
    textFieldsBorderRadius,
    textFieldsBorderColor,
    textFieldsBorderWidth,
  ) {
    return textFieldsType == 'filled'
        ? UnderlineInputBorder(
            borderRadius: BorderRadius.circular(textFieldsBorderRadius),
            borderSide: BorderSide(
                color: textFieldsBorderColor, width: textFieldsBorderWidth),
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(textFieldsBorderRadius),
            borderSide: BorderSide(
                color: textFieldsBorderColor, width: textFieldsBorderWidth),
          );
  }

  TextTheme _buildTextTheme(TextTheme base, displayColor, bodyColor) {
    return base
        .copyWith(
          headline1: TextStyle(
            color: displayColor,
          ),

          // GoogleFonts.getFont(
          //   fontFamily,
          //   textStyle: base.headline1!.copyWith(
          //     color: displayColor,
          //   ),
          // ),
          headline2: TextStyle(
            color: displayColor,
          ),

          headline3: TextStyle(
            color: displayColor,
          ),
          headline4: TextStyle(
            color: displayColor,
          ),
          headline5: TextStyle(
            color: displayColor,
          ),
          headline6: TextStyle(
            color: displayColor,
          ),
          subtitle1: TextStyle(
            fontWeight: FontWeight.w500,
            color: displayColor,
          ),

          subtitle2: TextStyle(
            fontWeight: FontWeight.w500,
            color: displayColor,
          ),
          button: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: displayColor,
          ),
          bodyText1: TextStyle(color: bodyColor, fontSize: 16),
          bodyText2: TextStyle(color: bodyColor, fontSize: 14),
          caption: TextStyle(
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            fontSize: 12,
            color: bodyColor,
          ),
          overline: TextStyle(
            color: bodyColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            fontSize: 10,
          ),
        )
        .apply(fontFamily: 'MierA');
  }

  IconThemeData _customIconTheme(
      IconThemeData original, Color appBarIconColor) {
    return original.copyWith(color: appBarIconColor);
  }
}
