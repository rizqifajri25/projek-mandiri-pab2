import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../models/task_models.dart';
import '../providers/app_providers.dart';
import '../utils/helpers.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final FieldTask task;
  const VerificationScreen({super.key, required this.task});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  XFile? photo;
  Position? pos;
  final notes = TextEditingController();

  Future<void> _takePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (picked == null) return;

    if (!kIsWeb) {
      final target = '${picked.path}_compressed.jpg';

      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        target,
        quality: 65,
      );

      setState(() {
        photo = XFile(compressed!.path);
      });
    } else {
      setState(() {
        photo = picked;
      });
    }
  }

  Future<void> _getLoc() async {
    await Geolocator.requestPermission();

    final position = await Geolocator.getCurrentPosition();
    pos = position;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.task.title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Timestamp: ${DateTime.now()}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _takePhoto,
              child: Text(photo == null ? 'Ambil & kompres foto' : 'Ganti foto'),
            ),
           if (photo != null)
            FutureBuilder(
              future: photo!.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                return Image.memory(
                  snapshot.data!,
                  height: 160,
                  fit: BoxFit.cover,
                );
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _getLoc,
              child: Text(pos == null ? 'Ambil lokasi realtime' : 'Update lokasi'),
            ),
            if (pos != null) ...[
              Text('Lat: ${pos!.latitude}, Lng: ${pos!.longitude}'),
              SizedBox(
                height: 180,
                child: SizedBox(
                  height: 300,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(pos!.latitude, pos!.longitude),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              pos!.latitude,
                              pos!.longitude,
                            ),
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.location_pin, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            TextField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'Catatan verifikasi'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final done = DateTime.now();
                final record = VerificationRecord(
                  id: done.millisecondsSinceEpoch.toString(),
                  taskId: widget.task.id,
                  taskTitle: widget.task.title,
                  startedAt: widget.task.startAt,
                  completedAt: done,
                  photoPath: photo?.path,
                  latitude: pos?.latitude ?? widget.task.latitude,
                  longitude: pos?.longitude ?? widget.task.longitude,
                  notes: '${notes.text} | watermark:$done',
                );
                await ref.read(firebaseBackendProvider).submitVerification(
                      task: widget.task,
                      record: record,
                    );
                ref.invalidate(taskListProvider);
                ref.invalidate(verificationHistoryProvider);
                if (!context.mounted) return;
                SnackbarHelper.show(
                  context,
                  'Verifikasi tersimpan ke Firestore dan menunggu validasi '
                  'admin.',
                );
                Navigator.pop(context);
              },
              child: const Text('Submit Verifikasi'),
            )
          ],
        ),
      );
}
