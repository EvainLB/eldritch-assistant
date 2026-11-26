import 'package:flutter/material.dart';

import 'partida.dart';
import 'pantallas/carga.dart';
import 'pantallas/inicio.dart';
import 'pantallas/preparacion.dart';
import 'tema.dart';

final partida = Partida();

/// Tiempo mínimo que se ve la pantalla de carga (aunque los datos carguen antes).
const _duracionCarga = Duration(milliseconds: 2800);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  partida.iniciar();
  runApp(const EldritchAssistantApp());
}

class EldritchAssistantApp extends StatefulWidget {
  const EldritchAssistantApp({super.key});

  @override
  State<EldritchAssistantApp> createState() => _EldritchAssistantAppState();
}

class _EldritchAssistantAppState extends State<EldritchAssistantApp> {
  bool _tiempoCumplido = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(_duracionCarga, () {
      if (mounted) setState(() => _tiempoCumplido = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eldritch Assistant',
      debugShowCheckedModeBanner: false,
      theme: temaOscuro(),
      home: ListenableBuilder(
        listenable: partida,
        builder: (context, _) {
          final listo = partida.cargada && _tiempoCumplido;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: !listo
                ? const PantallaCarga(key: ValueKey('carga'))
                : partida.hayPartida
                    ? const PantallaInicio(key: ValueKey('inicio'))
                    : const PantallaPreparacion(key: ValueKey('preparacion')),
          );
        },
      ),
    );
  }
}
