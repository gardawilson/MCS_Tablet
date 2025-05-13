import 'package:flutter/material.dart';
import '../view_models/status_so_view_model.dart'; // Import ViewModel

class StatusSODialog {
  static void show(BuildContext context) {
    TextEditingController textController = TextEditingController();
    StatusSOViewModel viewModel = StatusSOViewModel(); // Inisialisasi ViewModel

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Status SO'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Masukkan status SO:'),
              SizedBox(height: 8.0),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Simpan'),
              onPressed: () async {
                String inputText = textController.text.trim();

                if (inputText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Status tidak boleh kosong')),
                  );
                  return;
                }

                // Tampilkan loading dialog
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (_) => Center(child: CircularProgressIndicator()),
                );

                try {
                  await viewModel.sendStatus(inputText);

                  Navigator.of(context)
                      .pop(); // tutup CircularProgressIndicator
                  Navigator.of(context)
                      .pop(); // tutup AlertDialog utama

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Status berhasil dikirim')),
                  );
                } catch (e) {
                  Navigator.of(context).pop(); // tutup loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengirim status')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
