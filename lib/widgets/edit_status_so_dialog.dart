import 'package:flutter/material.dart';

class StatusEditDialog extends StatefulWidget {
  final String initialStatus;

  const StatusEditDialog({Key? key, required this.initialStatus}) : super(key: key);

  @override
  State<StatusEditDialog> createState() => _StatusEditDialogState();

  static Future<String?> show(BuildContext context, String initialStatus) {
    return showDialog<String>(
      context: context,
      builder: (_) => StatusEditDialog(initialStatus: initialStatus),
    );
  }
}

class _StatusEditDialogState extends State<StatusEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialStatus);
  }

  @override
  Widget build(BuildContext context) {
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
            children: [
              Text(
                'Edit Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _controller,
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
                    onPressed: () => Navigator.pop(context),
                    child: Text('Batal'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7a1b0c),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context, _controller.text.trim());
                    },
                    child: Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
