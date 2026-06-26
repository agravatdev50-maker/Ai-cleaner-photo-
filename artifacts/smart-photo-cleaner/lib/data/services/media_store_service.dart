import 'package:photo_manager/photo_manager.dart';
import '../models/photo_model.dart';

/// Accesses the device's MediaStore via [photo_manager] plugin.
/// Reads photo metadata in batches — never uploads anything to any server.
class MediaStoreService {
  /// Request permission to access media.
  /// Returns true if at least read access is granted.
  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth || result == PermissionState.limited;
  }

  /// Check current permission state without showing a dialog.
  Future<PermissionState> checkPermission() async {
    return await PhotoManager.getPermissionState();
  }

  /// Open the app settings page so the user can grant permission manually.
  Future<void> openSettings() async {
    await PhotoManager.openSetting();
  }

  /// Load all image assets from the device in batches.
  ///
  /// [onBatch] is called with each batch so the caller can process
  /// photos progressively (stream-like) without holding all in memory.
  ///
  /// [onProgress] reports (loaded, total) for the progress bar.
  Future<List<PhotoModel>> loadAllPhotos({
    void Function(int loaded, int total)? onProgress,
  }) async {
    final allPhotos = <PhotoModel>[];

    // Fetch all image albums (including All Photos virtual album)
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(minWidth: 1, minHeight: 1),
        ),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (albums.isEmpty) return [];

    // Find the "Recent" or "All Photos" album — it contains every image.
    final recentAlbum = albums.firstWhere(
      (a) => a.isAll,
      orElse: () => albums.first,
    );

    final total = await recentAlbum.assetCountAsync;
    int loaded = 0;
    const batchSize = 80;

    while (loaded < total) {
      final assets = await recentAlbum.getAssetListRange(
        start: loaded,
        end: (loaded + batchSize).clamp(0, total),
      );

      for (final asset in assets) {
        final model = await _assetToModel(asset);
        if (model != null) allPhotos.add(model);
      }

      loaded += assets.length;
      onProgress?.call(loaded, total);
    }

    return allPhotos;
  }

  /// Convert an [AssetEntity] to our internal [PhotoModel].
  Future<PhotoModel?> _assetToModel(AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file == null) return null;

      return PhotoModel(
        id:           asset.id,
        path:         file.path,
        name:         asset.title ?? file.path.split('/').last,
        sizeBytes:    asset.size > 0 ? asset.size : await file.length(),
        width:        asset.width,
        height:       asset.height,
        dateCreated:  asset.createDateTime,
        dateModified: asset.modifiedDateTime ?? asset.createDateTime,
        mimeType:     asset.mimeType ?? 'image/jpeg',
        bucketName:   asset.relativePath ?? '',
        bucketId:     asset.id,
      );
    } catch (_) {
      return null;
    }
  }

  /// Permanently delete the given photos from the device MediaStore.
  /// Shows Android system dialog asking the user to confirm.
  ///
  /// Returns a list of IDs that were successfully deleted.
  Future<List<String>> deletePhotos(List<PhotoModel> photos) async {
    final ids = photos.map((p) => p.id).toList();
    final assets = await _idsToAssets(ids);
    final result = await PhotoManager.editor.deleteWithIds(
      assets.map((a) => a.id).toList(),
    );
    return result;
  }

  /// Retrieve [AssetEntity] objects for given IDs.
  Future<List<AssetEntity>> _idsToAssets(List<String> ids) async {
    final assets = <AssetEntity>[];
    for (final id in ids) {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) assets.add(asset);
    }
    return assets;
  }

  /// Get the file size in bytes for a path.
  Future<int> getFileSize(String path) async {
    try {
      final f = await AssetEntity.fromId(path);
      return f?.size ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
