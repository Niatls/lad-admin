import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final bool mandatory;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.mandatory,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      downloadUrl: json['downloadUrl'] as String,
      releaseNotes: json['releaseNotes'] as String? ?? '',
      mandatory: json['mandatory'] as bool? ?? false,
    );
  }
}

class UpdateService {
  // Use GitHub API to automatically fetch the latest release of the admin app
  static const String updateApiUrl = 'https://api.github.com/repos/Niatls/lad-admin/releases/latest';
  final Dio _dio = Dio();

  // Checks if an update is available against the backend version flag.
  // Returns UpdateInfo if available and newer; otherwise null.
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      if (!Platform.isWindows) return null;

      _dio.options.headers['Accept'] = 'application/vnd.github.v3+json';
      _dio.options.headers['User-Agent'] = 'lad-admin-updater';
      final response = await _dio.get(updateApiUrl);
      
      if (response.statusCode == 200) {
        final data = response.data;
        // Map GitHub release format to UpdateInfo
        String tagName = data['tag_name'] as String? ?? '';
        if (tagName.startsWith('v')) tagName = tagName.substring(1);
        
        final assets = data['assets'] as List<dynamic>?;
        if (assets == null || assets.isEmpty) return null;
        
        // Find the ZIP asset specifically
        final zipAsset = assets.firstWhere(
          (a) => (a['name'] as String).endsWith('.zip'),
          orElse: () => null,
        );
        
        if (zipAsset == null) return null;
        
        final downloadUrl = zipAsset['browser_download_url'] as String? ?? '';
        final releaseNotes = data['body'] as String? ?? '';

        final updateInfo = UpdateInfo(
          version: tagName,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
          mandatory: false,
        );

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        bool isNewer = _isVersionMIsNewer(currentVersion, updateInfo.version);
        if (isNewer) {
          return updateInfo;
        }
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        // 404 just means no releases exist yet on GitHub!
        debugPrint('[UpdateService] No releases found on GitHub yet.');
      } else {
        debugPrint('[UpdateService] Update check failed: $e');
      }
    }
    return null;
  }

  // Returns true if v2 is newer than v1 (e.g. 1.0.0 vs 1.0.1)
  bool _isVersionMIsNewer(String current, String server) {

    List<int> clean(String v) => v.split('+')[0].split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final v1 = clean(current);
    final v2 = clean(server);
    
    for (int i = 0; i < 3; i++) {
      final p1 = i < v1.length ? v1[i] : 0;
      final p2 = i < v2.length ? v2[i] : 0;
      if (p2 > p1) return true;
      if (p1 > p2) return false;
    }
    return false;
  }

  // Applies the update by downloading the ZIP, extracting it, generating a batch replacing script, and restarting.
  Future<void> applyUpdate(UpdateInfo updateInfo, Function(double) onProgress) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final zipPath = p.join(tempDir.path, 'lad_admin_update.zip');
      final extractDir = p.join(tempDir.path, 'lad_admin_extracted');

      // 1. Download ZIP
      debugPrint('[UpdateService] Downloading update to $zipPath');
      await _dio.download(
        updateInfo.downloadUrl,
        zipPath,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            onProgress(count / total);
          }
        },
      );

      // 2. Clear old extraction if exists
      final extractDirFile = Directory(extractDir);
      if (await extractDirFile.exists()) {
        await extractDirFile.delete(recursive: true);
      }
      await extractDirFile.create();

      // 3. Extract the ZIP using archive
      debugPrint('[UpdateService] Extracting update...');
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final f = File(p.join(extractDir, filename));
          await f.create(recursive: true);
          await f.writeAsBytes(data);
        } else {
          Directory(p.join(extractDir, filename)).createSync(recursive: true);
        }
      }

      // If the extracted zip has a parent folder (e.g. lad_admin/...), detect it.
      // We want to copy the contents of the built folder, not the parent folder.
      String sourceDir = extractDir;
      final listDirs = extractDirFile.listSync();
      if (listDirs.length == 1 && listDirs.first is Directory) {
        // The zip originated from a compressed folder
        sourceDir = listDirs.first.path;
      }

      // 4. Create Batch Script
      // The script will forcefully close the current process, copy the extracted files over the current install directory, 
      // launch the new executable, and delete itself.
      final installDir = Directory.current.path;
      final exeName = 'lad_admin.exe';
      final batPath = p.join(tempDir.path, 'update.bat');
      
      final batContent = '''
@echo off
echo Updating Lad Admin...
timeout /t 2 /nobreak > NUL
taskkill /F /IM $exeName > NUL 2>&1
timeout /t 1 /nobreak > NUL
xcopy /s /y /e "$sourceDir\\*" "$installDir\\"
start "" "$installDir\\$exeName"
del "%~f0"
''';
      await File(batPath).writeAsString(batContent);

      // 5. Run the script and exit
      debugPrint('[UpdateService] Running batch script and exitting...');
      await Process.start(batPath, [], runInShell: true);
      exit(0);
      
    } catch (e) {
      debugPrint('[UpdateService] Failed to apply update: $e');
      rethrow;
    }
  }
}
