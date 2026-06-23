import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Shared filesystem helpers for storing menu item images portably.
///
/// Previously `getWritableDirectory()` was duplicated in `add_items.dart`
/// and `edit_menu_dialog.dart`. It now lives here. Images are stored under a
/// `dbImage` subfolder (desktop) or the app documents directory (mobile).
class ImageStorage {
  ImageStorage._();

  /// Returns the directory where menu item images should be copied.
  static Future<Directory> getWritableDirectory() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final home = Directory.current;
      return Directory('${home.path}/dbImage')..createSync(recursive: true);
    } else {
      return getApplicationDocumentsDirectory();
    }
  }

  /// Copies a picked image into the app's image directory and returns the
  /// absolute path of the stored file. Returns `null` when no file is picked.
  static Future<String?> copyPickedImage(String sourcePath, String fileName) async {
    final originalFile = File(sourcePath);
    if (!await originalFile.exists()) {
      throw FileSystemException('Source file does not exist', sourcePath);
    }
    final directory = await getWritableDirectory();
    final targetPath = '${directory.path}/$fileName';
    await originalFile.copy(targetPath);
    return targetPath;
  }

  /// Converts an absolute image path to a relative path stored in the model.
  /// On restore, [resolveImagePath] turns it back into an absolute path.
  static String toRelativePath(String absolutePath) {
    final dir = Directory.current.path;
    if (absolutePath.startsWith('$dir/dbImage/')) {
      return 'dbImage/${absolutePath.substring('$dir/dbImage/'.length)}';
    }
    // Mobile paths under the documents dir are left as-is (resolved at runtime).
    return absolutePath;
  }

  /// Resolves a stored (possibly relative) image path back to an absolute one.
  static String resolveImagePath(String stored) {
    if (stored.isEmpty) return stored;
    if (stored.startsWith('dbImage/')) {
      return '${Directory.current.path}/$stored';
    }
    return stored;
  }
}
