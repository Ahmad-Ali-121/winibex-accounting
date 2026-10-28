// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'csv_files.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(csvFiles)
final csvFilesProvider = CsvFilesProvider._();

final class CsvFilesProvider
    extends $FunctionalProvider<CsvFiles, CsvFiles, CsvFiles>
    with $Provider<CsvFiles> {
  CsvFilesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'csvFilesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$csvFilesHash();

  @$internal
  @override
  $ProviderElement<CsvFiles> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CsvFiles create(Ref ref) {
    return csvFiles(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CsvFiles value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CsvFiles>(value),
    );
  }
}

String _$csvFilesHash() => r'0e6c893879bd16d7bc97574d3d71fcfd5750bae4';
