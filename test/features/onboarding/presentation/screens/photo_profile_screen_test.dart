import 'dart:typed_data';

import 'package:eantrack/features/onboarding/data/profile_photo_service.dart';
import 'package:eantrack/features/onboarding/presentation/providers/photo_profile_provider.dart';
import 'package:eantrack/features/onboarding/presentation/screens/photo_profile_screen.dart';
import 'package:eantrack/shared/providers/theme_provider.dart';
import 'package:eantrack/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transparent_image/transparent_image.dart';

class _FakeProfilePhotoService implements ProfilePhotoService {
  _FakeProfilePhotoService({
    this.pickedPhoto,
  });

  final String? initialUrl = null;
  final PickedProfilePhoto? pickedPhoto;
  final String? uploadedUrl = 'https://example.com/avatar.jpg';

  int uploadCalls = 0;
  int removeCalls = 0;

  @override
  Future<String?> loadImageUrl() async => initialUrl;

  @override
  Future<PickedProfilePhoto?> pickImage(ImageSource source) async => pickedPhoto;

  @override
  Future<void> removeProfilePhoto() async {
    removeCalls++;
  }

  @override
  Future<String?> uploadProfilePhoto(PickedProfilePhoto photo) async {
    uploadCalls++;
    return uploadedUrl;
  }
}

PickedProfilePhoto _validPickedPhoto() {
  final bytes = Uint8List.fromList(kTransparentImage);
  return PickedProfilePhoto(
    file: XFile.fromData(
      bytes,
      name: 'avatar.png',
      mimeType: 'image/png',
    ),
    bytes: bytes,
    contentType: 'image/png',
  );
}

void main() {
  Finder _cameraActionFinder() => find.textContaining('mera');

  Future<void> _pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  ProviderContainer _createContainer(_FakeProfilePhotoService service) {
    return ProviderContainer(
      overrides: [
        profilePhotoServiceProvider.overrideWithValue(service),
      ],
    );
  }

  Future<void> _openPhotoActionsFromAvatar(WidgetTester tester) async {
    final avatar = find.byKey(const Key('photo-profile-avatar'));
    await tester.ensureVisible(avatar);
    await tester.pump();
    await tester.tap(avatar, warnIfMissed: false);
    await _pumpUi(tester);
  }

  Future<void> _openPhotoActionsFromButton(WidgetTester tester) async {
    final actionButton = find.byKey(const Key('photo-profile-action-button'));
    await tester.ensureVisible(actionButton);
    await tester.pump();
    await tester.tap(actionButton, warnIfMissed: false);
    await _pumpUi(tester);
  }

  Future<void> _savePhoto(
    ProviderContainer container,
    WidgetTester tester,
  ) async {
    await container
        .read(photoProfileNotifierProvider.notifier)
        .saveCroppedPhoto(_validPickedPhoto());
    for (var i = 0; i < 4; i++) {
      await _pumpUi(tester);
    }
  }

  Widget _buildScreen(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          final themeMode = ref.watch(themeModeProvider);
          return MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            home: const PagPhotoProfile(),
          );
        },
      ),
    );
  }

  testWidgets('estado vazio mostra copy principal e cancelar no modal',
      (tester) async {
    final service = _FakeProfilePhotoService();
    final container = _createContainer(service);
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildScreen(container));
    await tester.pump();

    expect(find.textContaining('Personalize seu perfil agora'),
        findsOneWidget);
    expect(find.text('Toque para adicionar uma imagem'), findsOneWidget);

    await _openPhotoActionsFromAvatar(tester);

    expect(_cameraActionFinder(), findsOneWidget);
    expect(find.text('Escolher nas Fotos'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('selecionar camera adiciona foto e habilita remover',
      (tester) async {
    final service = _FakeProfilePhotoService();
    final container = _createContainer(service);
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildScreen(container));
    await tester.pump();

    await _savePhoto(container, tester);

    expect(service.uploadCalls, 1);
    expect(find.text('Toque para editar'), findsOneWidget);

    await _openPhotoActionsFromButton(tester);
    expect(find.text('Remover foto'), findsOneWidget);
  });

  testWidgets('remover foto limpa estado local e remoto', (tester) async {
    final service = _FakeProfilePhotoService(
      pickedPhoto: _validPickedPhoto(),
    );
    final container = _createContainer(service);
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildScreen(container));
    await tester.pump();

    await _savePhoto(container, tester);
    expect(find.text('Toque para editar'), findsOneWidget);

    await _openPhotoActionsFromButton(tester);
    expect(find.text('Remover foto'), findsOneWidget);
    await tester.tap(find.text('Remover foto'), warnIfMissed: false);
    await _pumpUi(tester);

    expect(service.removeCalls, 1);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text('Toque para adicionar uma imagem'), findsOneWidget);

    await _openPhotoActionsFromAvatar(tester);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}
