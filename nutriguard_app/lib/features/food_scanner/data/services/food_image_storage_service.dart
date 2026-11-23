import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FoodImageStorageService {
  static const String _folderName = 'food_images';

  final Uuid _uuid;
  final Directory? testDirectory;

  FoodImageStorageService({Uuid? uuid, this.testDirectory})
    : _uuid = uuid ?? const Uuid();

  Future<Directory> _imageDirectory() async {
    final Directory directory;

    if (testDirectory != null) {
      directory = testDirectory!;
    } else {
      final appDirectory = await getApplicationDocumentsDirectory();

      directory = Directory(path.join(appDirectory.path, _folderName));
    }

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<String> saveImage(XFile image) async {
    final source = File(image.path);

    if (!await source.exists()) {
      throw FileSystemException(
        'Selected food image was not found.',
        image.path,
      );
    }

    final extension = path.extension(image.path).toLowerCase();

    const allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

    if (!allowedExtensions.contains(extension)) {
      throw const FormatException('Unsupported food image format.');
    }

    const maxImageSize = 10 * 1024 * 1024;

    final imageSize = await source.length();

    if (imageSize == 0 || imageSize > maxImageSize) {
      throw const FormatException(
        'Food image must be between 1 byte and 10 MB.',
      );
    }

    final directory = await _imageDirectory();

    final fileName = '${_uuid.v4()}$extension';

    final savedPath = path.join(directory.path, fileName);

    final savedImage = await source.copy(savedPath);

    return savedImage.path;
  }

  Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return false;
    }

    return File(imagePath).exists();
  }

  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return;
    }

    final directory = await _imageDirectory();
    final image = File(imagePath);

    if (!await image.exists()) {
      return;
    }

    final allowedDirectory = await directory.resolveSymbolicLinks();

    final resolvedImagePath = await image.resolveSymbolicLinks();

    final isInsideDirectory = path.isWithin(
      allowedDirectory,
      resolvedImagePath,
    );

    if (!isInsideDirectory) {
      throw const FileSystemException(
        'Cannot delete files outside the food images directory.',
      );
    }

    await image.delete();
  }
}
