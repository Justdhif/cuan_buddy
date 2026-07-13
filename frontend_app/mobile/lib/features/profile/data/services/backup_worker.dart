import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../repositories/profile_repository.dart';
import '../../presentation/providers/profile_provider.dart';

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
        await runBackupProcess(isAuto: true);
      }
    } catch (e) {
      debugPrint('Auto backup error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> runBackupProcess(
      {List<String> tables = const [], bool isAuto = false}) async {
    final notificationService = NotificationService();
    try {
      await notificationService.showProgressNotification(
        id: 99,
        title: 'CuanBuddy Backup',
        body: 'Generating backup...',
        progress: 10,
        maxProgress: 100,
      );

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          String newPath = "";
          List<String> paths = directory.path.split("/");
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
          directory = await getTemporaryDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final dateStr = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'cuanbuddy_backup_$dateStr.sql';
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
        title: isAuto ? 'Auto Backup Successful ✅' : 'Backup Successful ✅',
        body: 'Saved to device storage.',
      );
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

      final savePath = tableName == 'all'
          ? '${directory.path}/cuanbuddy_templates.zip'
          : '${directory.path}/${tableName}_template.xlsx';

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

  Future<void> runRestoreProcess({String? filePath}) async {
    final notificationService = NotificationService();
    try {
      String? path = filePath;
      if (path == null) {
        final result = await fp.FilePicker.pickFiles(
          type: fp.FileType.custom,
          allowedExtensions: ['sql'],
        );

        if (result == null || result.files.single.path == null) {
          return; // User canceled
        }
        path = result.files.single.path!;
      }

      await notificationService.showProgressNotification(
        id: 98,
        title: 'CuanBuddy Restore',
        body: 'Uploading and restoring database...',
        progress: 50,
        maxProgress: 100,
      );

      await repository.uploadRestore(path);

      await notificationService.flutterLocalNotificationsPlugin.cancel(id: 98);
      await notificationService.showSuccessNotification(
        id: 102,
        title: 'Restore Successful ✅',
        body: 'Your database has been restored.',
      );
    } catch (e) {
      await notificationService.flutterLocalNotificationsPlugin.cancel(id: 98);
      await notificationService.showErrorNotification(
        id: 103,
        title: 'Restore Failed ❌',
        body: 'Error: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> runSyncProcess(String filename) async {
    final notificationService = NotificationService();
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          String newPath = "";
          List<String> paths = directory.path.split("/");
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
          directory = await getTemporaryDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final filePath = '${directory.path}/$filename';
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('Backup file not found locally on device.');
      }

      await notificationService.showProgressNotification(
        id: 98,
        title: 'CuanBuddy Sync',
        body: 'Synchronizing database with local backup...',
        progress: 50,
        maxProgress: 100,
      );

      await repository.uploadRestore(filePath);

      await notificationService.flutterLocalNotificationsPlugin.cancel(id: 98);
      await notificationService.showSuccessNotification(
        id: 102,
        title: 'Sync Successful ✅',
        body: 'Database has been synchronized.',
      );
    } catch (e) {
      await notificationService.flutterLocalNotificationsPlugin.cancel(id: 98);
      await notificationService.showErrorNotification(
        id: 103,
        title: 'Sync Failed ❌',
        body: 'Error: ${e.toString()}',
      );
      rethrow;
    }
  }
}

final backupWorkerProvider = Provider<BackupWorker>((ref) {
  return BackupWorker(ref, ref.watch(profileRepositoryProvider));
});
