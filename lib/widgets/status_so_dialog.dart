import 'package:flutter/material.dart';
import '../view_models/status_so_view_model.dart';
import 'package:provider/provider.dart';

class StatusSODialog {
  static void show(BuildContext context) {
    TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Tambah Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Batal'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          String inputText = textController.text.trim();

                          if (inputText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Status tidak boleh kosong')),
                            );
                            return;
                          }

                          StatusSOViewModel viewModel = Provider.of<StatusSOViewModel>(context, listen: false);

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => Center(child: CircularProgressIndicator()),
                          );

                          try {
                            await viewModel.sendStatus(inputText);
                            await viewModel.fetchStatuses();

                            Navigator.of(context).pop(); // Close loading
                            Navigator.of(context).pop(); // Close dialog

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Status berhasil dikirim')),
                            );
                          } catch (e) {
                            Navigator.of(context).pop(); // Close loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal mengirim status')),
                            );
                          }
                        },
                        child: Text('Simpan'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
