import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/core_consts.dart';
import '../data/daos/tag_dao.dart';
import '../data/models/predefined_tag.dart';

/// Manages predefined/custom journal tags and their visual metadata.
class TagProvider with ChangeNotifier {
  final TagDao _tagDao;
  final Random _random;

  TagProvider(this._tagDao, {Random? random}) : _random = random ?? Random();

  List<PredefinedTag> _tagDefinitions = [];

  /// All known tag definitions used across journal entries.
  List<PredefinedTag> get tagDefinitions => _tagDefinitions;

  /// Loads tag definitions from local storage.
  Future<void> fetchTagDefinitions() async {
    _tagDefinitions = await _tagDao.getAllTagDefinitions();
    notifyListeners();
  }

  /// Creates a custom tag with a stable random color.
  Future<void> addCustomTag(String name) async {
    final colorIndex = _random.nextInt(kJournalTagColors.length);
    await _tagDao.insertCustomTagDefinition(name: name, colorIndex: colorIndex);
    await fetchTagDefinitions();
  }

  /// Updates the color associated with a tag definition.
  Future<void> updateTagColor({required int tagId, required int colorIndex}) async {
    await _tagDao.updateTagColor(tagId: tagId, colorIndex: colorIndex);
    await fetchTagDefinitions();
  }

  /// Removes a custom tag from definitions and related journal links.
  Future<void> deleteCustomTag(int tagId) async {
    await _tagDao.deleteCustomTagDefinition(tagId);
    await fetchTagDefinitions();
  }
}
