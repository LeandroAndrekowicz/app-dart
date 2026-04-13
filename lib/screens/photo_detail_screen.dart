// lib/screens/photo_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import '../models/models.dart';
import 'map_screen.dart';


const String coordinatorPhone = '+554299987362';

class PhotoDetailScreen extends StatelessWidget {
  final PhotoModel photo;
  final VoidCallback onDelete;

  const PhotoDetailScreen({
    Key? key,
    required this.photo,
    required this.onDelete,
  }) : super(key: key);

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  String _buildReportText() {
    final sb = StringBuffer();
    sb.writeln('Relatório - GeoUnião');
    sb.writeln('');
    sb.writeln('Nome: ${photo.name}');
    sb.writeln('Descrição: ${photo.description}');
    sb.writeln('Data: ${_formatDateTime(photo.timestamp)}');
    sb.writeln('Latitude: ${photo.latitude.toStringAsFixed(6)}');
    sb.writeln('Longitude: ${photo.longitude.toStringAsFixed(6)}');
    sb.writeln('');
    final lat = photo.latitude;
    final lng = photo.longitude;
    sb.writeln('Local no mapa: https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=18/$lat/$lng');
    sb.writeln('');
    sb.writeln('Enviado via GeoUnião');
    return sb.toString();
  }

  Future<void> _shareWithImageFallback(BuildContext context) async {
    final file = File(photo.path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arquivo de imagem não encontrado')));
      return;
    }

    final text = _buildReportText();

    try {
      final xfile = XFile(file.path);
      await Share.shareXFiles([xfile], text: text);
    } catch (e) {
      debugPrint('shareWithImageFallback error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao abrir compartilhamento')));
    }
  }

  Future<void> _sendImageToWhatsapp(BuildContext context) async {
    final file = File(photo.path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arquivo de imagem não encontrado')));
      return;
    }

    final text = _buildReportText();

    try {
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'action_send',
          arguments: <String, dynamic>{
            'android.intent.extra.TEXT': text,
            'android.intent.extra.STREAM': Uri.file(file.path).toString(),
          },
          type: 'image/*',
          package: 'com.whatsapp',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );

        try {
          await intent.launch();
          return;
        } catch (e) {
          debugPrint('Android intent whatsapp failed: $e');
        }
      }

      await _shareWithImageFallback(context);
    } catch (e) {
      debugPrint('sendImageToWhatsapp error: $e');
      await _shareWithImageFallback(context);
    }
  }

  Future<void> _openSmsComposer(BuildContext context, {required String phone}) async {
    final text = _buildReportText();
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: <String, String>{'body': text},
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o app de SMS')));
      }
    } catch (e) {
      debugPrint('openSmsComposer error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao abrir SMS')));
    }
  }

  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final regex = RegExp(r'^\+?\d{8,15}$');
    return regex.hasMatch(cleaned);
  }

  Future<void> _askPhoneAndSendSms(BuildContext context) async {
    final controller = TextEditingController(text: coordinatorPhone);
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setState) {
          return AlertDialog(
            title: const Text('Enviar SMS'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Digite o telefone para o qual deseja enviar o relatório (formato recomendado: +5511999999999).'),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Telefone',
                    hintText: '+5511999999999',
                    errorText: errorText,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  final phoneInput = controller.text.trim();
                  if (!_isValidPhone(phoneInput)) {
                    setState(() {
                      errorText = 'Telefone inválido. Inclua apenas números e opcional +';
                    });
                    return;
                  }
                  Navigator.of(ctx).pop();
                  _openSmsComposer(context, phone: phoneInput.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
                },
                child: const Text('Enviar'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showReportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Enviar relatório', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Escolha como deseja enviar o relatório desta foto (imagem, descrição e localização).', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 18),

                ListTile(
                  leading: Image.asset('assets/whats.png', width: 36, height: 36, fit: BoxFit.contain),
                  title: const Text('Enviar via WhatsApp (com imagem)'),
                  subtitle: const Text('Selecione o contato para quem deseja enviar as informações do relatório.'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _sendImageToWhatsapp(context);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.sms, color: Colors.green),
                  title: const Text('Enviar SMS para número personalizado'),
                  subtitle: Text('Nº padrão: $coordinatorPhone'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _askPhoneAndSendSms(context);
                  },
                ),

                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final file = File(photo.path);
    final exists = file.existsSync();
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: exists
                        ? Image.file(File(photo.path), fit: BoxFit.contain)
                        : const Icon(Icons.broken_image, size: 80, color: Colors.white30),
                  ),
                ),

                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(photo.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 6),
                      Text(photo.description),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${photo.latitude.toStringAsFixed(6)}  Lon: ${photo.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text('Data: ${df.format(photo.timestamp)}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send, color: Colors.white),
                          label: const Text('Enviar Relatório', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B4EFF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _showReportOptions(context),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              label: const Text('Excluir', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirmar'),
                                    content: const Text('Deseja excluir esta foto?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          onDelete();
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.map_rounded, color: Colors.white),
                              label: const Text('Ver no mapa', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B4EFF),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MapScreen(photos: [photo], initialIndex: 0),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Positioned(
              top: topPadding + 8,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}