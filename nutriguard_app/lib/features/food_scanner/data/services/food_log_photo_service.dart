import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FoodLogPhotoService {
  static const String _folderName = 'food_log_photos';

  static const List<String> _extensions = ['.jpg', '.jpeg', '.png', '.webp'];

  static const int _maxImageSize = 10 * 1024 * 1024;

  final Directory? testDirectory;

  const FoodLogPhotoService({this.testDirectory});

  String _safeId(String value) {
    if (value.isEmpty || value.length > 200) {
      throw ArgumentError('Invalid photo association ID.');
    }

    // Encode IDs so they cannot become filesystem paths.
    return base64Url.encode(utf8.encode(value)).replaceAll('=', '');
  }

  Future<Directory> _userDirectory(String userId) async {
    final encodedUserId = _safeId(userId);

    final Directory root;

    if (testDirectory != null) {
      root = testDirectory!;
    } else {
      final appDirectory = await getApplicationDocumentsDirectory();

      root = Directory(path.join(appDirectory.path, _folderName));
    }

    final directory = Directory(path.join(root.path, encodedUserId));

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<String?> getPhotoPath({
    required String userId,
    required String documentId,
  }) async {
    final encodedDocumentId = _safeId(documentId);
    final directory = await _userDirectory(userId);

    for (final extension in _extensions) {
      final image = File(
        path.join(directory.path, '$encodedDocumentId$extension'),
      );

      if (await image.exists()) {
        return image.path;
      }
    }

    return null;
  }

  Future<String> savePhoto({
    required String userId,
    required String documentId,
    required XFile photo,
  }) async {
    final encodedDocumentId = _safeId(documentId);
    _safeId(userId);

    final source = File(photo.path);

    if (!await source.exists()) {
      throw FileSystemException(
        'Selected food photo does not exist.',
        photo.path,
      );
    }

    final extension = path.extension(photo.path).toLowerCase();

    if (!_extensions.contains(extension)) {
      throw const FormatException('Unsupported food photo format.');
    }

    final imageSize = await source.length();

    if (imageSize <= 0 || imageSize > _maxImageSize) {
      throw const FormatException(
        'Food photo must be between 1 byte and 10 MB.',
      );
    }

    final directory = await _userDirectory(userId);

    final destination = File(
      path.join(directory.path, '$encodedDocumentId$extension'),
    );

    // Write to a temporary file first so a failed copy
    // does not overwrite an existing saved photo.
    final temporaryFile = File('${destination.path}.tmp');

    try {
      await source.copy(temporaryFile.path);

      // Remove the previous association, if present.
      // This method derives its own paths instead of
      // accepting arbitrary paths for deletion.
      for (final existingExtension in _extensions) {
        final existingFile = File(
          path.join(directory.path, '$encodedDocumentId$existingExtension'),
        );

        if (await existingFile.exists()) {
          await existingFile.delete();
        }
      }

      await temporaryFile.rename(destination.path);

      return destination.path;
    } finally {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
    }
  }

  Future<void> deletePhoto({
    required String userId,
    required String documentId,
  }) async {
    final encodedDocumentId = _safeId(documentId);
    final directory = await _userDirectory(userId);

    for (final extension in _extensions) {
      final image = File(
        path.join(directory.path, '$encodedDocumentId$extension'),
      );

      if (await image.exists()) {
        await image.delete();
      }
    }
  }
}
