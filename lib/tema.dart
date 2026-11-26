import 'package:flutter/material.dart';

/// Paleta negra con acento verde azulado (inspirado en el botón Start del APK).
abstract final class Paleta {
  static const fondo = Color(0xFF000000);
  static const superficie = Color(0xFF111114);
  static const superficieAlta = Color(0xFF1A1A1F);
  static const borde = Color(0xFF2A2A31);
  static const acento = Color(0xFF7FC4B4);
  static const acentoOscuro = Color(0xFF3E7D70);
  static const texto = Color(0xFFECE8E1);
  static const textoTenue = Color(0xFF8D8A85);
  static const oro = Color(0xFFD9B970);
}

const fuenteTitulo = 'Cinzel';
const fuenteTexto = 'Garamond';

/// Peso para fuentes variables (Cinzel y EB Garamond lo son).
List<FontVariation> peso(double w) => [FontVariation('wght', w)];

ThemeData temaOscuro() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: fuenteTexto,
    colorScheme: const ColorScheme.dark(
      surface: Paleta.fondo,
      primary: Paleta.acento,
      onPrimary: Colors.black,
      secondary: Paleta.oro,
      outline: Paleta.borde,
    ),
    scaffoldBackgroundColor: Paleta.fondo,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Paleta.fondo,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Paleta.texto,
      elevation: 0,
      titleTextStyle: TextStyle(fontFamily: fuenteTitulo, fontSize: 20, color: Paleta.texto),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Paleta.superficieAlta,
      textStyle: TextStyle(fontFamily: fuenteTexto, fontSize: 17, color: Paleta.texto),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Paleta.superficieAlta),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Paleta.superficieAlta,
      contentTextStyle: TextStyle(fontFamily: fuenteTexto, fontSize: 16, color: Paleta.texto),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: base.textTheme.apply(bodyColor: Paleta.texto, displayColor: Paleta.texto),
  );
}
