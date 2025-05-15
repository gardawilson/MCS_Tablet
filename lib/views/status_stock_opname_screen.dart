import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/status_so_view_model.dart';
import '../widgets/status_so_dialog.dart';
import '../widgets/edit_status_so_dialog.dart';

class StatusStockOpnameListScreen extends StatefulWidget {
  @override
  _StatusStockOpnameListScreenState createState() => _StatusStockOpnameListScreenState();
}

class _StatusStockOpnameListScreenState extends State<StatusStockOpnameListScreen> {
  List<String> selectedItems = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<StatusSOViewModel>(context, listen: false).fetchStatuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusVM = Provider.of<StatusSOViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: selectedItems.isNotEmpty
          ? AppBar(title: Text('${selectedItems.length} Dipilih'))
          : AppBar(
        title: const Text('Status Stock Opname'),
        backgroundColor: const Color(0xFF7a1b0c),
      ),
      floatingActionButton: selectedItems.isNotEmpty
          ? null
          : FloatingActionButton(
        onPressed: () {
          StatusSODialog.show(context);
        },
        backgroundColor: const Color(0xFF7a1b0c),
        child: const Icon(Icons.add),
      ),
      body: statusVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : statusVM.errorMessage.isNotEmpty
          ? Center(child: Text(statusVM.errorMessage))
          : ListView.separated(
        itemCount: statusVM.statuses.length,
        separatorBuilder: (context, index) => const Divider(
          height: 0,
          thickness: 0.5,
        ),
        itemBuilder: (context, index) {
          final status = statusVM.statuses[index];
          return Container(
            color: Colors.white,
            child: ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              title: Text(
                status.status,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final newStatus = await StatusEditDialog.show(context, status.status);
                      if (newStatus != null && newStatus.isNotEmpty && newStatus != status.status) {
                        await Provider.of<StatusSOViewModel>(context, listen: false)
                            .updateStatus(status.id, newStatus);
                      }
                    },
                  ),

                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Hapus Status'),
                          content: Text('Apakah Anda yakin ingin menghapus status ini?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Hapus')),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await Provider.of<StatusSOViewModel>(context, listen: false)
                            .deleteStatus(status.id);
                      }
                    },
                  ),
                ],
              ),

              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 16,
              ),
            ),
          );
        },
      ),
    );
  }
}
