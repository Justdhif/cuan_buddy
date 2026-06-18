import '../../presentation/providers/profile_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../repositories/profile_repository.dart';

class BackupWorker {
  BackupWorker(this.ref, this.repository);

  final Ref ref;
  final ProfileRepository repository;
  bool _isProcessing = false;

  Future<void> checkAndRunAutoBackup() async {
    if (_isProcessing) return;
    try {
      _isProcessing = true;
      final settings = await repository.getBackupSettings();
      if (settings['isEnabled'] != true) return;

      final nextBackupAtRaw = settings['nextBackupAt'];
      if (nextBackupAtRaw == null) return;

      final nextBackupAt = DateTime.parse(nextBackupAtRaw.toString());
      final now = DateTime.now();

      if (now.isAfter(nextBackupAt)) {
        await runBackupProcess();
      }
    } catch (e) {
      print('Auto backup error: $e');
    } finally {
      _isProcessing = false;
    }
  }

    Future<void> runBackupProcess({List<String> tables = const []}) async {
    final notificationService = NotificationService();
    try {
      await notificationService.showProgressNotification(
        id: 99,
        title: 'CuanBuddy Backup',
        body: 'Generating backup...',
        progress: 10,
        maxProgress: 100,
      );

      Directory directory = await getTemporaryDirectory();

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final isSingle = tables.length == 1;
      final ext = isSingle ? 'xlsx' : 'zip';
      final fileName = isSingle ? '${tables[0]}_backup_$dateStr.$ext' : 'cuanbuddy_backup_$dateStr.$ext';
      final savePath = '${directory.path}/$fileName';

      await notificationService.showProgressNotification(
        id: 99,
        title: 'CuanBuddy Backup',
        body: 'Downloading backup...',
        progress: 50,
        maxProgress: 100,
      );

      await repository.downloadBackup(
        savePath,
        tables: tables,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 40).toInt() + 50; // 50 to 90%
            notificationService.showProgressNotification(
              id: 99,
              title: 'CuanBuddy Backup',
              body: 'Downloading backup...',
              progress: progress,
              maxProgress: 100,
            );
          }
        },
      );

      await repository.markBackupCompleted();

      await notificationService.flutterLocalNotificationsPlugin.cancel(id: 99);
      await notificationService.showSuccessNotification(
        id: 100,
        title: 'Backup Successful ✅',
        body: 'Ready to share or save.',
      );

      // Share the file so user can save it to Downloads or send via WhatsApp
      await Share.shareXFiles([XFile(savePath)], text: 'CuanBuddy Backup');
    } catch (e) {
      await notificationService.flutterLocalNotificationsPlugin.cancel(id: 99);
      await notificationService.showErrorNotification(
        id: 101,
        title: 'Backup Failed ❌',
        body: 'Error: ${e.toString()}',
      );
    }
  }
  
  Future<void> downloadTemplate(String tableName) async {
    final notificationService = NotificationService();
    try {
      await notificationService.showProgressNotification(
        id: 97,
        title: 'Template Download',
        body: 'Downloading template...',
        progress: 10,
        maxProgress: 100,
      );

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        String newPath = "";
        List<String> paths = directory!.path.split("/");
        for (int x = 1; x < paths.length; x++) {
          String folder = paths[x];
          if (folder != "Android") {
            newPath += "/$folder";
          } else {
            break;
          }
        }
        newPath = "$newPath/Download";
        directory = Directory(newPath);
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final savePath = '${directory.path}/${tableName}_template.xlsx';

      await repository.downloadTemplate(
        tableName,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 90).toInt() + 10;
            notificationService.showProgressNotification(
              id: 97,
              title: 'Template Download',
              body: 'Downloading template...',
              progress: progress,
              maxProgress: 100,
            );
          }
        },
      );

      await notificationService.flutterLocalNotificationsPlugin.cancel(id: 97);
      await notificationService.showSuccessNotification(
        id: 104,
        title: 'Download Successful ✅',
        body: 'Template saved to $savePath',
      );
    } catch (e) {
      await notificationService.flutterLocalNotificationsPlugin.cancel(id: 97);
      await notificationService.showErrorNotification(
        id: 105,
        title: 'Download Failed ❌',
        body: 'Error: ${e.toString()}',
      );
    }
  }

  Future<void> runRestoreProcess() async {
    final notificationService = NotificationService();
    try {
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['zip', 'xlsx'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled
      }

      await notificationService.showProgressNotification(
        id: 98,
        title: 'CuanBuddy Restore',
        body: 'Uploading and restoring data...',
        progress: 50,
        maxProgress: 100,
      );

      final filePath = result.files.single.path!;
      await repository.uploadRestore(filePath);

      await notificationService.flutterLocalNotificationsPlugin.cancel(id: 98);
      await notificationService.showSuccessNotification(
        id: 102,
        title: 'Restore Successful ✅',
        body: 'Your data has been restored.',
      );
    } catch (e) {
      await notificationService.flutterLocalNotificationsPlugin.cancel(id: 98);
      await notificationService.showErrorNotification(
        id: 103,
        title: 'Restore Failed ❌',
        body: 'Error: ${e.toString()}',
      );
    }
  }
}


final backupWorkerProvider = Provider<BackupWorker>((ref) {
  return BackupWorker(ref, ref.watch(profileRepositoryProvider));
});
