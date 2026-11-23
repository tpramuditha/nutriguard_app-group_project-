import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import 'package:nutriguard_app/features/food_scanner/data/services/food_log_photo_service.dart';

void main() {
  late Directory temporaryDirectory;
  late Directory photoDirectory;
  late FoodLogPhotoService service;

  const userId = 'user_001';
  const documentId = 'food_log_001';

  Future<File> createTestPhoto(String name, {List<int>? bytes}) async {
    final file = File(path.join(temporaryDirectory.path, name));

    await file.writeAsBytes(bytes ?? [1, 2, 3, 4, 5]);

    return file;
  }

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'nutriguard_photo_test_',
    );

    photoDirectory = Directory(
      path.join(temporaryDirectory.path, 'saved_photos'),
    );

    service = FoodLogPhotoService(testDirectory: photoDirectory);
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  group('FoodLogPhotoService', () {
    test('saves a photo for a food log', () async {
      final source = await createTestPhoto('rice.jpg');

      final savedPath = await service.savePhoto(
        userId: userId,
        documentId: documentId,
        photo: XFile(source.path),
      );

      expect(await File(savedPath).exists(), isTrue);

      expect(await File(savedPath).readAsBytes(), await source.readAsBytes());

      expect(path.extension(savedPath), '.jpg');
    });

    test('retrieves the saved photo path', () async {
      final source = await createTestPhoto('meal.png');

      final savedPath = await service.savePhoto(
        userId: userId,
        documentId: documentId,
        photo: XFile(source.path),
      );

      final retrievedPath = await service.getPhotoPath(
        userId: userId,
        documentId: documentId,
      );

      expect(retrievedPath, savedPath);
    });

    test('returns null when no photo exists', () async {
      final result = await service.getPhotoPath(
        userId: userId,
        documentId: 'missing_food',
      );

      expect(result, isNull);
    });

    test('keeps different users photos separate', () async {
      final source = await createTestPhoto('meal.jpg');

      final firstPath = await service.savePhoto(
        userId: 'user_A',
        documentId: documentId,
        photo: XFile(source.path),
      );

      final secondPath = await service.savePhoto(
        userId: 'user_B',
        documentId: documentId,
        photo: XFile(source.path),
      );

      expect(firstPath, isNot(secondPath));

      expect(await File(firstPath).exists(), isTrue);

      expect(await File(secondPath).exists(), isTrue);
    });

    test('keeps different food logs separate', () async {
      final source = await createTestPhoto('meal.jpg');

      final firstPath = await service.savePhoto(
        userId: userId,
        documentId: 'food_001',
        photo: XFile(source.path),
      );

      final secondPath = await service.savePhoto(
        userId: userId,
        documentId: 'food_002',
        photo: XFile(source.path),
      );

      expect(firstPath, isNot(secondPath));
    });

    test('replaces an existing food photo', () async {
      final firstPhoto = await createTestPhoto('first.jpg', bytes: [1, 2, 3]);

      final secondPhoto = await createTestPhoto('second.png', bytes: [7, 8, 9]);

      final firstPath = await service.savePhoto(
        userId: userId,
        documentId: documentId,
        photo: XFile(firstPhoto.path),
      );

      final secondPath = await service.savePhoto(
        userId: userId,
        documentId: documentId,
        photo: XFile(secondPhoto.path),
      );

      expect(await File(firstPath).exists(), isFalse);

      expect(await File(secondPath).readAsBytes(), [7, 8, 9]);

      expect(
        await service.getPhotoPath(userId: userId, documentId: documentId),
        secondPath,
      );
    });

    test('deletes an associated food photo', () async {
      final source = await createTestPhoto('meal.webp');

      final savedPath = await service.savePhoto(
        userId: userId,
        documentId: documentId,
        photo: XFile(source.path),
      );

      await service.deletePhoto(userId: userId, documentId: documentId);

      expect(await File(savedPath).exists(), isFalse);

      expect(
        await service.getPhotoPath(userId: userId, documentId: documentId),
        isNull,
      );
    });

    test('rejects an unsupported extension', () async {
      final source = await createTestPhoto('meal.txt');

      await expectLater(
        service.savePhoto(
          userId: userId,
          documentId: documentId,
          photo: XFile(source.path),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a missing source photo', () async {
      final missingPath = path.join(temporaryDirectory.path, 'missing.jpg');

      await expectLater(
        service.savePhoto(
          userId: userId,
          documentId: documentId,
          photo: XFile(missingPath),
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('rejects an empty photo', () async {
      final source = await createTestPhoto('empty.jpg', bytes: []);

      await expectLater(
        service.savePhoto(
          userId: userId,
          documentId: documentId,
          photo: XFile(source.path),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an oversized photo', () async {
      final source = await createTestPhoto(
        'large.jpg',
        bytes: List<int>.filled(10 * 1024 * 1024 + 1, 0),
      );

      await expectLater(
        service.savePhoto(
          userId: userId,
          documentId: documentId,
          photo: XFile(source.path),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid association IDs', () async {
      final source = await createTestPhoto('meal.jpg');

      await expectLater(
        service.savePhoto(
          userId: userId,
          documentId: '',
          photo: XFile(source.path),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('encodes IDs to prevent path traversal', () async {
      final source = await createTestPhoto('meal.jpg');

      final savedPath = await service.savePhoto(
        userId: '../user',
        documentId: '../food',
        photo: XFile(source.path),
      );

      expect(await File(savedPath).exists(), isTrue);

      expect(path.isWithin(photoDirectory.path, savedPath), isTrue);
    });
  });
}
