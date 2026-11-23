import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:nutriguard_app/features/food_scanner/data/services/food_image_storage_service.dart';

void main() {
  late Directory temporaryDirectory;
  late Directory imageDirectory;
  late FoodImageStorageService service;

  Future<File> createTestFile(String name, {List<int>? bytes}) async {
    final file = File(path.join(temporaryDirectory.path, name));

    await file.writeAsBytes(bytes ?? [1, 2, 3, 4, 5]);

    return file;
  }

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'nutriguard_image_test_',
    );

    imageDirectory = Directory(
      path.join(temporaryDirectory.path, 'food_images'),
    );

    service = FoodImageStorageService(testDirectory: imageDirectory);
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  group('FoodImageStorageService', () {
    test('saves an image into the configured directory', () async {
      final source = await createTestFile('meal.jpg');

      final savedPath = await service.saveImage(XFile(source.path));

      expect(await File(savedPath).exists(), isTrue);

      expect(path.dirname(savedPath), imageDirectory.path);

      expect(path.extension(savedPath), '.jpg');

      expect(await File(savedPath).readAsBytes(), await source.readAsBytes());
    });

    test('generates a unique filename for every save', () async {
      final source = await createTestFile('meal.png');

      final firstPath = await service.saveImage(XFile(source.path));

      final secondPath = await service.saveImage(XFile(source.path));

      expect(firstPath, isNot(secondPath));

      expect(await File(firstPath).exists(), isTrue);
      expect(await File(secondPath).exists(), isTrue);
    });

    test('rejects an unsupported file extension', () async {
      final source = await createTestFile('meal.txt');

      await expectLater(
        service.saveImage(XFile(source.path)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a missing source image', () async {
      final missingPath = path.join(temporaryDirectory.path, 'missing.jpg');

      await expectLater(
        service.saveImage(XFile(missingPath)),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('rejects an empty image file', () async {
      final source = await createTestFile('empty.jpg', bytes: []);

      await expectLater(
        service.saveImage(XFile(source.path)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an image larger than 10 MB', () async {
      final source = await createTestFile(
        'large.jpg',
        bytes: List<int>.filled(10 * 1024 * 1024 + 1, 0),
      );

      await expectLater(
        service.saveImage(XFile(source.path)),
        throwsA(isA<FormatException>()),
      );
    });

    test('imageExists returns true for saved images', () async {
      final source = await createTestFile('food.webp');

      final savedPath = await service.saveImage(XFile(source.path));

      expect(await service.imageExists(savedPath), isTrue);
    });

    test('imageExists returns false for missing paths', () async {
      expect(await service.imageExists(null), isFalse);
      expect(await service.imageExists(''), isFalse);

      expect(
        await service.imageExists(
          path.join(temporaryDirectory.path, 'missing.jpg'),
        ),
        isFalse,
      );
    });

    test('deletes an image inside the food directory', () async {
      final source = await createTestFile('meal.jpg');

      final savedPath = await service.saveImage(XFile(source.path));

      await service.deleteImage(savedPath);

      expect(await File(savedPath).exists(), isFalse);
    });

    test('refuses to delete a file outside the directory', () async {
      final outsideFile = await createTestFile('important.jpg');

      await expectLater(
        service.deleteImage(outsideFile.path),
        throwsA(isA<FileSystemException>()),
      );

      expect(await outsideFile.exists(), isTrue);
    });

    test('handles missing paths during deletion', () async {
      await service.deleteImage(null);
      await service.deleteImage('');

      await service.deleteImage(
        path.join(temporaryDirectory.path, 'nonexistent.jpg'),
      );
    });
  });
}
