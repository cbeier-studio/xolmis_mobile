// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Inventories`
  String get inventories {
    return Intl.message(
      'Inventories',
      name: 'inventories',
      desc: '',
      args: [],
    );
  }

  /// `Nests`
  String get nests {
    return Intl.message(
      'Nests',
      name: 'nests',
      desc: '',
      args: [],
    );
  }

  /// `{howMany, plural, one{Specimen} other{Specimens}}`
  String specimens(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Specimen',
      other: 'Specimens',
      name: 'specimens',
      desc: 'Specimens display label',
      args: [howMany],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Appearance`
  String get appearance {
    return Intl.message(
      'Appearance',
      name: 'appearance',
      desc: '',
      args: [],
    );
  }

  /// `Select the mode`
  String get selectMode {
    return Intl.message(
      'Select the mode',
      name: 'selectMode',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get lightMode {
    return Intl.message(
      'Light',
      name: 'lightMode',
      desc: '',
      args: [],
    );
  }

  /// `Dark`
  String get darkMode {
    return Intl.message(
      'Dark',
      name: 'darkMode',
      desc: '',
      args: [],
    );
  }

  /// `System theme`
  String get systemMode {
    return Intl.message(
      'System theme',
      name: 'systemMode',
      desc: '',
      args: [],
    );
  }

  /// `Observer (acronym)`
  String get observerSetting {
    return Intl.message(
      'Observer (acronym)',
      name: 'observerSetting',
      desc: '',
      args: [],
    );
  }

  /// `Observer`
  String get observer {
    return Intl.message(
      'Observer',
      name: 'observer',
      desc: '',
      args: [],
    );
  }

  /// `Observador acronym`
  String get observerAcronym {
    return Intl.message(
      'Observador acronym',
      name: 'observerAcronym',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Simultaneous inventories`
  String get simultaneousInventories {
    return Intl.message(
      'Simultaneous inventories',
      name: 'simultaneousInventories',
      desc: '',
      args: [],
    );
  }

  /// `{howMany, plural, one{inventory} other{inventories}}`
  String inventory(int howMany) {
    return Intl.plural(
      howMany,
      one: 'inventory',
      other: 'inventories',
      name: 'inventory',
      desc: 'Number of inventories',
      args: [howMany],
    );
  }

  /// `Mackinnon lists`
  String get mackinnonLists {
    return Intl.message(
      'Mackinnon lists',
      name: 'mackinnonLists',
      desc: '',
      args: [],
    );
  }

  /// `{howMany, plural, one{1 species} other{{howMany} species}} per list`
  String speciesPerList(int howMany) {
    return Intl.message(
      '${Intl.plural(howMany, one: '1 species', other: '$howMany species')} per list',
      name: 'speciesPerList',
      desc: 'Number of species per list',
      args: [howMany],
    );
  }

  /// `Species per list`
  String get speciesPerListTitle {
    return Intl.message(
      'Species per list',
      name: 'speciesPerListTitle',
      desc: '',
      args: [],
    );
  }

  /// `Count points`
  String get pointCounts {
    return Intl.message(
      'Count points',
      name: 'pointCounts',
      desc: '',
      args: [],
    );
  }

  /// `Duration (min)`
  String get durationMin {
    return Intl.message(
      'Duration (min)',
      name: 'durationMin',
      desc: '',
      args: [],
    );
  }

  /// `{howMany, plural, one{1 minute} other{{howMany} minutes}} of duration`
  String inventoryDuration(int howMany) {
    return Intl.message(
      '${Intl.plural(howMany, one: '1 minute', other: '$howMany minutes')} of duration',
      name: 'inventoryDuration',
      desc: 'Time duration in minutes',
      args: [howMany],
    );
  }

  /// `Timed qualitative lists`
  String get timedQualitativeLists {
    return Intl.message(
      'Timed qualitative lists',
      name: 'timedQualitativeLists',
      desc: '',
      args: [],
    );
  }

  /// `About the app`
  String get about {
    return Intl.message(
      'About the app',
      name: 'about',
      desc: '',
      args: [],
    );
  }

  /// `Danger zone`
  String get dangerZone {
    return Intl.message(
      'Danger zone',
      name: 'dangerZone',
      desc: '',
      args: [],
    );
  }

  /// `Delete the app data`
  String get deleteAppData {
    return Intl.message(
      'Delete the app data',
      name: 'deleteAppData',
      desc: '',
      args: [],
    );
  }

  /// `Delete data`
  String get deleteData {
    return Intl.message(
      'Delete data',
      name: 'deleteData',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete all app data? This action cannot be undone.`
  String get deleteDataMessage {
    return Intl.message(
      'Are you sure you want to delete all app data? This action cannot be undone.',
      name: 'deleteDataMessage',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `App data deleted successfully!`
  String get dataDeleted {
    return Intl.message(
      'App data deleted successfully!',
      name: 'dataDeleted',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get ok {
    return Intl.message(
      'OK',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  /// `Limit of simultaneous inventories reached.`
  String get simultaneousLimitReached {
    return Intl.message(
      'Limit of simultaneous inventories reached.',
      name: 'simultaneousLimitReached',
      desc: '',
      args: [],
    );
  }

  /// `Find inventories...`
  String get findInventories {
    return Intl.message(
      'Find inventories...',
      name: 'findInventories',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get active {
    return Intl.message(
      'Active',
      name: 'active',
      desc: '',
      args: [],
    );
  }

  /// `Finished`
  String get finished {
    return Intl.message(
      'Finished',
      name: 'finished',
      desc: '',
      args: [],
    );
  }

  /// `No inventories found.`
  String get noInventoriesFound {
    return Intl.message(
      'No inventories found.',
      name: 'noInventoriesFound',
      desc: '',
      args: [],
    );
  }

  /// `Delete inventory`
  String get deleteInventory {
    return Intl.message(
      'Delete inventory',
      name: 'deleteInventory',
      desc: '',
      args: [],
    );
  }

  /// `Confirm delete`
  String get confirmDelete {
    return Intl.message(
      'Confirm delete',
      name: 'confirmDelete',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete {howMany, plural, one{{gender, select, male{this} female{this} other{this}}} other{{gender, select, male{these} female{these} other{these}}}} {what}?`
  String confirmDeleteMessage(int howMany, String gender, String what) {
    return Intl.message(
      'Are you sure you want to delete ${Intl.plural(howMany, one: '{gender, select, male{this} female{this} other{this}}', other: '{gender, select, male{these} female{these} other{these}}')} $what?',
      name: 'confirmDeleteMessage',
      desc: 'What will be deleted',
      args: [howMany, gender, what],
    );
  }

  /// `Confirm finish`
  String get confirmFinish {
    return Intl.message(
      'Confirm finish',
      name: 'confirmFinish',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to finish this inventory?`
  String get confirmFinishMessage {
    return Intl.message(
      'Are you sure you want to finish this inventory?',
      name: 'confirmFinishMessage',
      desc: '',
      args: [],
    );
  }

  /// `Finish`
  String get finish {
    return Intl.message(
      'Finish',
      name: 'finish',
      desc: '',
      args: [],
    );
  }

  /// `New inventory`
  String get newInventory {
    return Intl.message(
      'New inventory',
      name: 'newInventory',
      desc: '',
      args: [],
    );
  }

  /// `{howMany, plural, one{1 species} other{{howMany} species}}`
  String speciesCount(int howMany) {
    return Intl.plural(
      howMany,
      one: '1 species',
      other: '$howMany species',
      name: 'speciesCount',
      desc: 'How many species',
      args: [howMany],
    );
  }

  /// `Pause`
  String get pause {
    return Intl.message(
      'Pause',
      name: 'pause',
      desc: '',
      args: [],
    );
  }

  /// `Resume`
  String get resume {
    return Intl.message(
      'Resume',
      name: 'resume',
      desc: '',
      args: [],
    );
  }

  /// `Export {what}`
  String export(String what) {
    return Intl.message(
      'Export $what',
      name: 'export',
      desc: 'What will be exported',
      args: [what],
    );
  }

  /// `Export all {what}`
  String exportAll(String what) {
    return Intl.message(
      'Export all $what',
      name: 'exportAll',
      desc: 'What will be exported',
      args: [what],
    );
  }

  /// `Finish inventory`
  String get finishInventory {
    return Intl.message(
      'Finish inventory',
      name: 'finishInventory',
      desc: '',
      args: [],
    );
  }

  /// `* required`
  String get requiredField {
    return Intl.message(
      '* required',
      name: 'requiredField',
      desc: '',
      args: [],
    );
  }

  /// `Inventory type *`
  String get inventoryType {
    return Intl.message(
      'Inventory type *',
      name: 'inventoryType',
      desc: '',
      args: [],
    );
  }

  /// `Please, select an inventory type`
  String get selectInventoryType {
    return Intl.message(
      'Please, select an inventory type',
      name: 'selectInventoryType',
      desc: '',
      args: [],
    );
  }

  /// `Inventory ID *`
  String get inventoryId {
    return Intl.message(
      'Inventory ID *',
      name: 'inventoryId',
      desc: '',
      args: [],
    );
  }

  /// `Generate ID`
  String get generateId {
    return Intl.message(
      'Generate ID',
      name: 'generateId',
      desc: '',
      args: [],
    );
  }

  /// `Site name or acronym`
  String get siteAcronym {
    return Intl.message(
      'Site name or acronym',
      name: 'siteAcronym',
      desc: '',
      args: [],
    );
  }

  /// `* optional`
  String get optional {
    return Intl.message(
      '* optional',
      name: 'optional',
      desc: '',
      args: [],
    );
  }

  /// `Please, insert an ID for the inventory`
  String get insertInventoryId {
    return Intl.message(
      'Please, insert an ID for the inventory',
      name: 'insertInventoryId',
      desc: '',
      args: [],
    );
  }

  /// `Duration`
  String get duration {
    return Intl.message(
      'Duration',
      name: 'duration',
      desc: '',
      args: [],
    );
  }

  /// `{howMany, plural, one{minute} other{minutes}}`
  String minutes(int howMany) {
    return Intl.plural(
      howMany,
      one: 'minute',
      other: 'minutes',
      name: 'minutes',
      desc: 'Time in minutes',
      args: [howMany],
    );
  }

  /// `Insert a duration`
  String get insertDuration {
    return Intl.message(
      'Insert a duration',
      name: 'insertDuration',
      desc: '',
      args: [],
    );
  }

  /// `Max species`
  String get maxSpecies {
    return Intl.message(
      'Max species',
      name: 'maxSpecies',
      desc: '',
      args: [],
    );
  }

  /// `Insert the max of species`
  String get insertMaxSpecies {
    return Intl.message(
      'Insert the max of species',
      name: 'insertMaxSpecies',
      desc: '',
      args: [],
    );
  }

  /// `Must be equal or higher than 5`
  String get mustBeBiggerThanFive {
    return Intl.message(
      'Must be equal or higher than 5',
      name: 'mustBeBiggerThanFive',
      desc: '',
      args: [],
    );
  }

  /// `Start inventory`
  String get startInventory {
    return Intl.message(
      'Start inventory',
      name: 'startInventory',
      desc: '',
      args: [],
    );
  }

  /// `This inventory ID already exists.`
  String get inventoryIdAlreadyExists {
    return Intl.message(
      'This inventory ID already exists.',
      name: 'inventoryIdAlreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Error inserting inventory`
  String get errorInsertingInventory {
    return Intl.message(
      'Error inserting inventory',
      name: 'errorInsertingInventory',
      desc: '',
      args: [],
    );
  }

  /// `Vegetation data`
  String get vegetationData {
    return Intl.message(
      'Vegetation data',
      name: 'vegetationData',
      desc: '',
      args: [],
    );
  }

  /// `Herbs`
  String get herbs {
    return Intl.message(
      'Herbs',
      name: 'herbs',
      desc: '',
      args: [],
    );
  }

  /// `Distribution`
  String get distribution {
    return Intl.message(
      'Distribution',
      name: 'distribution',
      desc: '',
      args: [],
    );
  }

  /// `Proportion`
  String get proportion {
    return Intl.message(
      'Proportion',
      name: 'proportion',
      desc: '',
      args: [],
    );
  }

  /// `Height`
  String get height {
    return Intl.message(
      'Height',
      name: 'height',
      desc: '',
      args: [],
    );
  }

  /// `Shrubs`
  String get shrubs {
    return Intl.message(
      'Shrubs',
      name: 'shrubs',
      desc: '',
      args: [],
    );
  }

  /// `Trees`
  String get trees {
    return Intl.message(
      'Trees',
      name: 'trees',
      desc: '',
      args: [],
    );
  }

  /// `Notes`
  String get notes {
    return Intl.message(
      'Notes',
      name: 'notes',
      desc: '',
      args: [],
    );
  }

  /// `Insert proportion`
  String get insertProportion {
    return Intl.message(
      'Insert proportion',
      name: 'insertProportion',
      desc: '',
      args: [],
    );
  }

  /// `Insert height`
  String get insertHeight {
    return Intl.message(
      'Insert height',
      name: 'insertHeight',
      desc: '',
      args: [],
    );
  }

  /// `Error inserting vegetation data`
  String get errorInsertingVegetation {
    return Intl.message(
      'Error inserting vegetation data',
      name: 'errorInsertingVegetation',
      desc: '',
      args: [],
    );
  }

  /// `Weather data`
  String get weatherData {
    return Intl.message(
      'Weather data',
      name: 'weatherData',
      desc: '',
      args: [],
    );
  }

  /// `Cloud cover`
  String get cloudCover {
    return Intl.message(
      'Cloud cover',
      name: 'cloudCover',
      desc: '',
      args: [],
    );
  }

  /// `Precipitation *`
  String get precipitation {
    return Intl.message(
      'Precipitation *',
      name: 'precipitation',
      desc: '',
      args: [],
    );
  }

  /// `Select precipitation`
  String get selectPrecipitation {
    return Intl.message(
      'Select precipitation',
      name: 'selectPrecipitation',
      desc: '',
      args: [],
    );
  }

  /// `Temperature`
  String get temperature {
    return Intl.message(
      'Temperature',
      name: 'temperature',
      desc: '',
      args: [],
    );
  }

  /// `Wind speed`
  String get windSpeed {
    return Intl.message(
      'Wind speed',
      name: 'windSpeed',
      desc: '',
      args: [],
    );
  }

  /// `Error inserting weather data`
  String get errorInsertingWeather {
    return Intl.message(
      'Error inserting weather data',
      name: 'errorInsertingWeather',
      desc: '',
      args: [],
    );
  }

  /// `{howMany, plural, one{Species} other{Species}}`
  String species(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Species',
      other: 'Species',
      name: 'species',
      desc: 'Species display label',
      args: [howMany],
    );
  }

  /// `{howMany, plural, one{sp.} other{spp.}}`
  String speciesAcronym(int howMany) {
    return Intl.plural(
      howMany,
      one: 'sp.',
      other: 'spp.',
      name: 'speciesAcronym',
      desc: 'How many species',
      args: [howMany],
    );
  }

  /// `Vegetation`
  String get vegetation {
    return Intl.message(
      'Vegetation',
      name: 'vegetation',
      desc: '',
      args: [],
    );
  }

  /// `Weather`
  String get weather {
    return Intl.message(
      'Weather',
      name: 'weather',
      desc: '',
      args: [],
    );
  }

  /// `Error getting location.`
  String get errorGettingLocation {
    return Intl.message(
      'Error getting location.',
      name: 'errorGettingLocation',
      desc: '',
      args: [],
    );
  }

  /// `POI`
  String get poi {
    return Intl.message(
      'POI',
      name: 'poi',
      desc: '',
      args: [],
    );
  }

  /// `Species information`
  String get speciesInfo {
    return Intl.message(
      'Species information',
      name: 'speciesInfo',
      desc: '',
      args: [],
    );
  }

  /// `Count`
  String get count {
    return Intl.message(
      'Count',
      name: 'count',
      desc: '',
      args: [],
    );
  }

  /// `{howMany, plural, one{individual} other{individuals}}`
  String individual(int howMany) {
    return Intl.plural(
      howMany,
      one: 'individual',
      other: 'individuals',
      name: 'individual',
      desc: 'How many individuals',
      args: [howMany],
    );
  }

  /// `Out of the sample`
  String get outOfSample {
    return Intl.message(
      'Out of the sample',
      name: 'outOfSample',
      desc: '',
      args: [],
    );
  }

  /// `Within the sample`
  String get withinSample {
    return Intl.message(
      'Within the sample',
      name: 'withinSample',
      desc: '',
      args: [],
    );
  }

  /// `No POI found.`
  String get noPoiFound {
    return Intl.message(
      'No POI found.',
      name: 'noPoiFound',
      desc: '',
      args: [],
    );
  }

  /// `New POI`
  String get newPoi {
    return Intl.message(
      'New POI',
      name: 'newPoi',
      desc: '',
      args: [],
    );
  }

  /// `Delete POI`
  String get deletePoi {
    return Intl.message(
      'Delete POI',
      name: 'deletePoi',
      desc: '',
      args: [],
    );
  }

  /// `Decrease individuals count`
  String get decreaseIndividuals {
    return Intl.message(
      'Decrease individuals count',
      name: 'decreaseIndividuals',
      desc: '',
      args: [],
    );
  }

  /// `Increase individuals count`
  String get increaseIndividuals {
    return Intl.message(
      'Increase individuals count',
      name: 'increaseIndividuals',
      desc: '',
      args: [],
    );
  }

  /// `Add POI`
  String get addPoi {
    return Intl.message(
      'Add POI',
      name: 'addPoi',
      desc: '',
      args: [],
    );
  }

  /// `Edit count`
  String get editCount {
    return Intl.message(
      'Edit count',
      name: 'editCount',
      desc: '',
      args: [],
    );
  }

  /// `Individuals count`
  String get individualsCount {
    return Intl.message(
      'Individuals count',
      name: 'individualsCount',
      desc: '',
      args: [],
    );
  }

  /// `Delete vegetation record`
  String get deleteVegetation {
    return Intl.message(
      'Delete vegetation record',
      name: 'deleteVegetation',
      desc: '',
      args: [],
    );
  }

  /// `No vegetation records.`
  String get noVegetationFound {
    return Intl.message(
      'No vegetation records.',
      name: 'noVegetationFound',
      desc: '',
      args: [],
    );
  }

  /// `weather record`
  String get weatherRecord {
    return Intl.message(
      'weather record',
      name: 'weatherRecord',
      desc: '',
      args: [],
    );
  }

  /// `No weather records.`
  String get noWeatherFound {
    return Intl.message(
      'No weather records.',
      name: 'noWeatherFound',
      desc: '',
      args: [],
    );
  }

  /// `Delete weather record`
  String get deleteWeather {
    return Intl.message(
      'Delete weather record',
      name: 'deleteWeather',
      desc: '',
      args: [],
    );
  }

  /// `Find nests...`
  String get findNests {
    return Intl.message(
      'Find nests...',
      name: 'findNests',
      desc: '',
      args: [],
    );
  }

  /// `Inactive`
  String get inactive {
    return Intl.message(
      'Inactive',
      name: 'inactive',
      desc: '',
      args: [],
    );
  }

  /// `No nests found.`
  String get noNestsFound {
    return Intl.message(
      'No nests found.',
      name: 'noNestsFound',
      desc: '',
      args: [],
    );
  }

  /// `{howMany, plural, one{nest} other{nests}}`
  String nest(int howMany) {
    return Intl.plural(
      howMany,
      one: 'nest',
      other: 'nests',
      name: 'nest',
      desc: 'How many nests',
      args: [howMany],
    );
  }

  /// `New nest`
  String get newNest {
    return Intl.message(
      'New nest',
      name: 'newNest',
      desc: '',
      args: [],
    );
  }

  /// `Delete nest`
  String get deleteNest {
    return Intl.message(
      'Delete nest',
      name: 'deleteNest',
      desc: '',
      args: [],
    );
  }

  /// `Confirm fate`
  String get confirmFate {
    return Intl.message(
      'Confirm fate',
      name: 'confirmFate',
      desc: '',
      args: [],
    );
  }

  /// `Nest fate *`
  String get nestFate {
    return Intl.message(
      'Nest fate *',
      name: 'nestFate',
      desc: '',
      args: [],
    );
  }

  /// `Error inactivating nest: {errorMessage}`
  String errorInactivatingNest(String errorMessage) {
    return Intl.message(
      'Error inactivating nest: $errorMessage',
      name: 'errorInactivatingNest',
      desc: 'Error message returned',
      args: [errorMessage],
    );
  }

  /// `{howMany, plural, one{Revision} other{Revisions}}`
  String revision(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Revision',
      other: 'Revisions',
      name: 'revision',
      desc: 'How many nests',
      args: [howMany],
    );
  }

  /// `{howMany, plural, one{Egg} other{Eggs}}`
  String egg(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Egg',
      other: 'Eggs',
      name: 'egg',
      desc: 'How many nests',
      args: [howMany],
    );
  }

  /// `Nest information`
  String get nestInfo {
    return Intl.message(
      'Nest information',
      name: 'nestInfo',
      desc: '',
      args: [],
    );
  }

  /// `Date and time found`
  String get timeFound {
    return Intl.message(
      'Date and time found',
      name: 'timeFound',
      desc: '',
      args: [],
    );
  }

  /// `Locality`
  String get locality {
    return Intl.message(
      'Locality',
      name: 'locality',
      desc: '',
      args: [],
    );
  }

  /// `Nest support`
  String get nestSupport {
    return Intl.message(
      'Nest support',
      name: 'nestSupport',
      desc: '',
      args: [],
    );
  }

  /// `Height above ground`
  String get heightAboveGround {
    return Intl.message(
      'Height above ground',
      name: 'heightAboveGround',
      desc: '',
      args: [],
    );
  }

  /// `Male`
  String get male {
    return Intl.message(
      'Male',
      name: 'male',
      desc: '',
      args: [],
    );
  }

  /// `Female`
  String get female {
    return Intl.message(
      'Female',
      name: 'female',
      desc: '',
      args: [],
    );
  }

  /// `Nest helpers`
  String get helpers {
    return Intl.message(
      'Nest helpers',
      name: 'helpers',
      desc: '',
      args: [],
    );
  }

  /// `No eggs recorded.`
  String get noEggsFound {
    return Intl.message(
      'No eggs recorded.',
      name: 'noEggsFound',
      desc: '',
      args: [],
    );
  }

  /// `Delete egg`
  String get deleteEgg {
    return Intl.message(
      'Delete egg',
      name: 'deleteEgg',
      desc: '',
      args: [],
    );
  }

  /// `No revisions recorded.`
  String get noRevisionsFound {
    return Intl.message(
      'No revisions recorded.',
      name: 'noRevisionsFound',
      desc: '',
      args: [],
    );
  }

  /// `Delete nest revision`
  String get deleteRevision {
    return Intl.message(
      'Delete nest revision',
      name: 'deleteRevision',
      desc: '',
      args: [],
    );
  }

  /// `Host`
  String get host {
    return Intl.message(
      'Host',
      name: 'host',
      desc: '',
      args: [],
    );
  }

  /// `Nidoparasite`
  String get nidoparasite {
    return Intl.message(
      'Nidoparasite',
      name: 'nidoparasite',
      desc: '',
      args: [],
    );
  }

  /// `{howMany, plural, one{Nestling} other{Nestlings}}`
  String nestling(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Nestling',
      other: 'Nestlings',
      name: 'nestling',
      desc: 'How many nestlings',
      args: [howMany],
    );
  }

  /// `Add egg`
  String get addEgg {
    return Intl.message(
      'Add egg',
      name: 'addEgg',
      desc: '',
      args: [],
    );
  }

  /// `Field number`
  String get fieldNumber {
    return Intl.message(
      'Field number',
      name: 'fieldNumber',
      desc: '',
      args: [],
    );
  }

  /// `Please, insert the field number`
  String get insertFieldNumber {
    return Intl.message(
      'Please, insert the field number',
      name: 'insertFieldNumber',
      desc: '',
      args: [],
    );
  }

  /// `Please, select a species`
  String get selectSpecies {
    return Intl.message(
      'Please, select a species',
      name: 'selectSpecies',
      desc: '',
      args: [],
    );
  }

  /// `Egg shape`
  String get eggShape {
    return Intl.message(
      'Egg shape',
      name: 'eggShape',
      desc: '',
      args: [],
    );
  }

  /// `Width`
  String get width {
    return Intl.message(
      'Width',
      name: 'width',
      desc: '',
      args: [],
    );
  }

  /// `Length`
  String get length {
    return Intl.message(
      'Length',
      name: 'length',
      desc: '',
      args: [],
    );
  }

  /// `Weight`
  String get weight {
    return Intl.message(
      'Weight',
      name: 'weight',
      desc: '',
      args: [],
    );
  }

  /// `An egg with this field number already exists.`
  String get errorEggAlreadyExists {
    return Intl.message(
      'An egg with this field number already exists.',
      name: 'errorEggAlreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Error saving egg.`
  String get errorSavingEgg {
    return Intl.message(
      'Error saving egg.',
      name: 'errorSavingEgg',
      desc: '',
      args: [],
    );
  }

  /// `Please, insert locality name`
  String get insertLocality {
    return Intl.message(
      'Please, insert locality name',
      name: 'insertLocality',
      desc: '',
      args: [],
    );
  }

  /// `Please, insert nest support`
  String get insertNestSupport {
    return Intl.message(
      'Please, insert nest support',
      name: 'insertNestSupport',
      desc: '',
      args: [],
    );
  }

  /// `A nest with this field number already exists.`
  String get errorNestAlreadyExists {
    return Intl.message(
      'A nest with this field number already exists.',
      name: 'errorNestAlreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Error saving nest.`
  String get errorSavingNest {
    return Intl.message(
      'Error saving nest.',
      name: 'errorSavingNest',
      desc: '',
      args: [],
    );
  }

  /// `Nest revision`
  String get nestRevision {
    return Intl.message(
      'Nest revision',
      name: 'nestRevision',
      desc: '',
      args: [],
    );
  }

  /// `Nest status`
  String get nestStatus {
    return Intl.message(
      'Nest status',
      name: 'nestStatus',
      desc: '',
      args: [],
    );
  }

  /// `Nest phase`
  String get nestPhase {
    return Intl.message(
      'Nest phase',
      name: 'nestPhase',
      desc: '',
      args: [],
    );
  }

  /// `Philornis larvae present`
  String get philornisLarvaePresent {
    return Intl.message(
      'Philornis larvae present',
      name: 'philornisLarvaePresent',
      desc: '',
      args: [],
    );
  }

  /// `Error saving nest revision.`
  String get errorSavingRevision {
    return Intl.message(
      'Error saving nest revision.',
      name: 'errorSavingRevision',
      desc: '',
      args: [],
    );
  }

  /// `Find specimens...`
  String get findSpecimens {
    return Intl.message(
      'Find specimens...',
      name: 'findSpecimens',
      desc: '',
      args: [],
    );
  }

  /// `No specimen collected.`
  String get noSpecimenCollected {
    return Intl.message(
      'No specimen collected.',
      name: 'noSpecimenCollected',
      desc: '',
      args: [],
    );
  }

  /// `New specimen`
  String get newSpecimen {
    return Intl.message(
      'New specimen',
      name: 'newSpecimen',
      desc: '',
      args: [],
    );
  }

  /// `Delete specimen`
  String get deleteSpecimen {
    return Intl.message(
      'Delete specimen',
      name: 'deleteSpecimen',
      desc: '',
      args: [],
    );
  }

  /// `Specimen type`
  String get specimenType {
    return Intl.message(
      'Specimen type',
      name: 'specimenType',
      desc: '',
      args: [],
    );
  }

  /// `A specimen with this field number already exists.`
  String get errorSpecimenAlreadyExists {
    return Intl.message(
      'A specimen with this field number already exists.',
      name: 'errorSpecimenAlreadyExists',
      desc: '',
      args: [],
    );
  }

  /// `Error saving specimen.`
  String get errorSavingSpecimen {
    return Intl.message(
      'Error saving specimen.',
      name: 'errorSavingSpecimen',
      desc: '',
      args: [],
    );
  }

  /// `{howMany, plural, one{Image} other{Images}}`
  String images(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Image',
      other: 'Images',
      name: 'images',
      desc: 'How many images',
      args: [howMany],
    );
  }

  /// `No images found.`
  String get noImagesFound {
    return Intl.message(
      'No images found.',
      name: 'noImagesFound',
      desc: '',
      args: [],
    );
  }

  /// `Add image`
  String get addImage {
    return Intl.message(
      'Add image',
      name: 'addImage',
      desc: '',
      args: [],
    );
  }

  /// `Gallery`
  String get gallery {
    return Intl.message(
      'Gallery',
      name: 'gallery',
      desc: '',
      args: [],
    );
  }

  /// `Camera`
  String get camera {
    return Intl.message(
      'Camera',
      name: 'camera',
      desc: '',
      args: [],
    );
  }

  /// `Permission denied.`
  String get permissionDenied {
    return Intl.message(
      'Permission denied.',
      name: 'permissionDenied',
      desc: '',
      args: [],
    );
  }

  /// `Permission denied permanently.`
  String get permissionDeniedPermanently {
    return Intl.message(
      'Permission denied permanently.',
      name: 'permissionDeniedPermanently',
      desc: '',
      args: [],
    );
  }

  /// `Share image`
  String get shareImage {
    return Intl.message(
      'Share image',
      name: 'shareImage',
      desc: '',
      args: [],
    );
  }

  /// `Edit image notes`
  String get editImageNotes {
    return Intl.message(
      'Edit image notes',
      name: 'editImageNotes',
      desc: '',
      args: [],
    );
  }

  /// `Delete image`
  String get deleteImage {
    return Intl.message(
      'Delete image',
      name: 'deleteImage',
      desc: '',
      args: [],
    );
  }

  /// `Edit notes`
  String get editNotes {
    return Intl.message(
      'Edit notes',
      name: 'editNotes',
      desc: '',
      args: [],
    );
  }

  /// `Image details`
  String get imageDetails {
    return Intl.message(
      'Image details',
      name: 'imageDetails',
      desc: '',
      args: [],
    );
  }

  /// `{howMany, plural, one{Inventory exported!} other{Inventories exported!}}`
  String inventoryExported(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Inventory exported!',
      other: 'Inventories exported!',
      name: 'inventoryExported',
      desc: 'How many inventories',
      args: [howMany],
    );
  }

  /// `{howMany, plural, one{Inventory data} other{Inventories data}}`
  String inventoryData(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Inventory data',
      other: 'Inventories data',
      name: 'inventoryData',
      desc: 'How many inventories',
      args: [howMany],
    );
  }

  /// `Error exporting {howMany, plural, one{inventory} other{inventories}}: {errorMessage}`
  String errorExportingInventory(int howMany, String errorMessage) {
    return Intl.message(
      'Error exporting ${Intl.plural(howMany, one: 'inventory', other: 'inventories')}: $errorMessage',
      name: 'errorExportingInventory',
      desc: 'Error message when exporting inventories',
      args: [howMany, errorMessage],
    );
  }

  /// `{howMany, plural, one{Nest exported!} other{Nests exported!}}`
  String nestExported(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Nest exported!',
      other: 'Nests exported!',
      name: 'nestExported',
      desc: 'How many nests',
      args: [howMany],
    );
  }

  /// `{howMany, plural, one{Nest data} other{Nests data}}`
  String nestData(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Nest data',
      other: 'Nests data',
      name: 'nestData',
      desc: 'How many nests',
      args: [howMany],
    );
  }

  /// `Error exporting {howMany, plural, one{nest} other{nests}}: {errorMessage}`
  String errorExportingNest(int howMany, String errorMessage) {
    return Intl.message(
      'Error exporting ${Intl.plural(howMany, one: 'nest', other: 'nests')}: $errorMessage',
      name: 'errorExportingNest',
      desc: 'Error message when exporting nests',
      args: [howMany, errorMessage],
    );
  }

  /// `{howMany, plural, one{Specimen exported!} other{Specimens exported!}}`
  String specimenExported(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Specimen exported!',
      other: 'Specimens exported!',
      name: 'specimenExported',
      desc: 'How many specimens',
      args: [howMany],
    );
  }

  /// `{howMany, plural, one{Specimen data} other{Specimens data}}`
  String specimenData(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Specimen data',
      other: 'Specimens data',
      name: 'specimenData',
      desc: 'How many specimens',
      args: [howMany],
    );
  }

  /// `Error exporting {howMany, plural, one{specimen} other{specimens}}: {errorMessage}`
  String errorExportingSpecimen(int howMany, String errorMessage) {
    return Intl.message(
      'Error exporting ${Intl.plural(howMany, one: 'specimen', other: 'specimens')}: $errorMessage',
      name: 'errorExportingSpecimen',
      desc: 'Error message when exporting specimens',
      args: [howMany, errorMessage],
    );
  }

  /// `Find species`
  String get findSpecies {
    return Intl.message(
      'Find species',
      name: 'findSpecies',
      desc: '',
      args: [],
    );
  }

  /// `List finished`
  String get listFinished {
    return Intl.message(
      'List finished',
      name: 'listFinished',
      desc: '',
      args: [],
    );
  }

  /// `The list reached the maximum of species. Do you want to start the next list or finish now?`
  String get listFinishedMessage {
    return Intl.message(
      'The list reached the maximum of species. Do you want to start the next list or finish now?',
      name: 'listFinishedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Start next list`
  String get startNextList {
    return Intl.message(
      'Start next list',
      name: 'startNextList',
      desc: '',
      args: [],
    );
  }

  /// `None`
  String get precipitationNone {
    return Intl.message(
      'None',
      name: 'precipitationNone',
      desc: '',
      args: [],
    );
  }

  /// `Fog`
  String get precipitationFog {
    return Intl.message(
      'Fog',
      name: 'precipitationFog',
      desc: '',
      args: [],
    );
  }

  /// `Mist`
  String get precipitationMist {
    return Intl.message(
      'Mist',
      name: 'precipitationMist',
      desc: '',
      args: [],
    );
  }

  /// `Drizzle`
  String get precipitationDrizzle {
    return Intl.message(
      'Drizzle',
      name: 'precipitationDrizzle',
      desc: '',
      args: [],
    );
  }

  /// `Rain`
  String get precipitationRain {
    return Intl.message(
      'Rain',
      name: 'precipitationRain',
      desc: '',
      args: [],
    );
  }

  /// `None`
  String get distributionNone {
    return Intl.message(
      'None',
      name: 'distributionNone',
      desc: '',
      args: [],
    );
  }

  /// `Rare`
  String get distributionRare {
    return Intl.message(
      'Rare',
      name: 'distributionRare',
      desc: '',
      args: [],
    );
  }

  /// `Few sparse individuals`
  String get distributionFewSparseIndividuals {
    return Intl.message(
      'Few sparse individuals',
      name: 'distributionFewSparseIndividuals',
      desc: '',
      args: [],
    );
  }

  /// `One patch`
  String get distributionOnePatch {
    return Intl.message(
      'One patch',
      name: 'distributionOnePatch',
      desc: '',
      args: [],
    );
  }

  /// `One patch and isolated individuals`
  String get distributionOnePatchFewSparseIndividuals {
    return Intl.message(
      'One patch and isolated individuals',
      name: 'distributionOnePatchFewSparseIndividuals',
      desc: '',
      args: [],
    );
  }

  /// `Many sparse individuals`
  String get distributionManySparseIndividuals {
    return Intl.message(
      'Many sparse individuals',
      name: 'distributionManySparseIndividuals',
      desc: '',
      args: [],
    );
  }

  /// `Patch and many isolated individuals`
  String get distributionOnePatchManySparseIndividuals {
    return Intl.message(
      'Patch and many isolated individuals',
      name: 'distributionOnePatchManySparseIndividuals',
      desc: '',
      args: [],
    );
  }

  /// `Few patches`
  String get distributionFewPatches {
    return Intl.message(
      'Few patches',
      name: 'distributionFewPatches',
      desc: '',
      args: [],
    );
  }

  /// `Few patches and isolated individuals`
  String get distributionFewPatchesSparseIndividuals {
    return Intl.message(
      'Few patches and isolated individuals',
      name: 'distributionFewPatchesSparseIndividuals',
      desc: '',
      args: [],
    );
  }

  /// `Many equidistant patches`
  String get distributionManyPatches {
    return Intl.message(
      'Many equidistant patches',
      name: 'distributionManyPatches',
      desc: '',
      args: [],
    );
  }

  /// `Many patches and scattered individuals`
  String get distributionManyPatchesSparseIndividuals {
    return Intl.message(
      'Many patches and scattered individuals',
      name: 'distributionManyPatchesSparseIndividuals',
      desc: '',
      args: [],
    );
  }

  /// `Isolated individuals in high density`
  String get distributionHighDensityIndividuals {
    return Intl.message(
      'Isolated individuals in high density',
      name: 'distributionHighDensityIndividuals',
      desc: '',
      args: [],
    );
  }

  /// `Continuous with gaps`
  String get distributionContinuousCoverWithGaps {
    return Intl.message(
      'Continuous with gaps',
      name: 'distributionContinuousCoverWithGaps',
      desc: '',
      args: [],
    );
  }

  /// `Continuous and dense`
  String get distributionContinuousDenseCover {
    return Intl.message(
      'Continuous and dense',
      name: 'distributionContinuousDenseCover',
      desc: '',
      args: [],
    );
  }

  /// `Continuous with edge between strata`
  String get distributionContinuousDenseCoverWithEdge {
    return Intl.message(
      'Continuous with edge between strata',
      name: 'distributionContinuousDenseCoverWithEdge',
      desc: '',
      args: [],
    );
  }

  /// `Free Qualitative List`
  String get inventoryFreeQualitative {
    return Intl.message(
      'Free Qualitative List',
      name: 'inventoryFreeQualitative',
      desc: '',
      args: [],
    );
  }

  /// `Timed Qualitative List`
  String get inventoryTimedQualitative {
    return Intl.message(
      'Timed Qualitative List',
      name: 'inventoryTimedQualitative',
      desc: '',
      args: [],
    );
  }

  /// `Mackinnon List`
  String get inventoryMackinnonList {
    return Intl.message(
      'Mackinnon List',
      name: 'inventoryMackinnonList',
      desc: '',
      args: [],
    );
  }

  /// `Transection Count`
  String get inventoryTransectionCount {
    return Intl.message(
      'Transection Count',
      name: 'inventoryTransectionCount',
      desc: '',
      args: [],
    );
  }

  /// `Point Count`
  String get inventoryPointCount {
    return Intl.message(
      'Point Count',
      name: 'inventoryPointCount',
      desc: '',
      args: [],
    );
  }

  /// `Banding`
  String get inventoryBanding {
    return Intl.message(
      'Banding',
      name: 'inventoryBanding',
      desc: '',
      args: [],
    );
  }

  /// `Casual Observation`
  String get inventoryCasual {
    return Intl.message(
      'Casual Observation',
      name: 'inventoryCasual',
      desc: '',
      args: [],
    );
  }

  /// `Spherical`
  String get eggShapeSpherical {
    return Intl.message(
      'Spherical',
      name: 'eggShapeSpherical',
      desc: '',
      args: [],
    );
  }

  /// `Elliptical`
  String get eggShapeElliptical {
    return Intl.message(
      'Elliptical',
      name: 'eggShapeElliptical',
      desc: '',
      args: [],
    );
  }

  /// `Oval`
  String get eggShapeOval {
    return Intl.message(
      'Oval',
      name: 'eggShapeOval',
      desc: '',
      args: [],
    );
  }

  /// `Pyriform`
  String get eggShapePyriform {
    return Intl.message(
      'Pyriform',
      name: 'eggShapePyriform',
      desc: '',
      args: [],
    );
  }

  /// `Conical`
  String get eggShapeConical {
    return Intl.message(
      'Conical',
      name: 'eggShapeConical',
      desc: '',
      args: [],
    );
  }

  /// `Biconical`
  String get eggShapeBiconical {
    return Intl.message(
      'Biconical',
      name: 'eggShapeBiconical',
      desc: '',
      args: [],
    );
  }

  /// `Cylindrical`
  String get eggShapeCylindrical {
    return Intl.message(
      'Cylindrical',
      name: 'eggShapeCylindrical',
      desc: '',
      args: [],
    );
  }

  /// `Longitudinal`
  String get eggShapeLongitudinal {
    return Intl.message(
      'Longitudinal',
      name: 'eggShapeLongitudinal',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get nestStageUnknown {
    return Intl.message(
      'Unknown',
      name: 'nestStageUnknown',
      desc: '',
      args: [],
    );
  }

  /// `Building`
  String get nestStageBuilding {
    return Intl.message(
      'Building',
      name: 'nestStageBuilding',
      desc: '',
      args: [],
    );
  }

  /// `Laying`
  String get nestStageLaying {
    return Intl.message(
      'Laying',
      name: 'nestStageLaying',
      desc: '',
      args: [],
    );
  }

  /// `Incubating`
  String get nestStageIncubating {
    return Intl.message(
      'Incubating',
      name: 'nestStageIncubating',
      desc: '',
      args: [],
    );
  }

  /// `Hatching`
  String get nestStageHatching {
    return Intl.message(
      'Hatching',
      name: 'nestStageHatching',
      desc: '',
      args: [],
    );
  }

  /// `Nestling`
  String get nestStageNestling {
    return Intl.message(
      'Nestling',
      name: 'nestStageNestling',
      desc: '',
      args: [],
    );
  }

  /// `Inactive`
  String get nestStageInactive {
    return Intl.message(
      'Inactive',
      name: 'nestStageInactive',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get nestStatusUnknown {
    return Intl.message(
      'Unknown',
      name: 'nestStatusUnknown',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get nestStatusActive {
    return Intl.message(
      'Active',
      name: 'nestStatusActive',
      desc: '',
      args: [],
    );
  }

  /// `Inactive`
  String get nestStatusInactive {
    return Intl.message(
      'Inactive',
      name: 'nestStatusInactive',
      desc: '',
      args: [],
    );
  }

  /// `Whole carcass`
  String get specimenWholeCarcass {
    return Intl.message(
      'Whole carcass',
      name: 'specimenWholeCarcass',
      desc: '',
      args: [],
    );
  }

  /// `Partial carcass`
  String get specimenPartialCarcass {
    return Intl.message(
      'Partial carcass',
      name: 'specimenPartialCarcass',
      desc: '',
      args: [],
    );
  }

  /// `Nest`
  String get specimenNest {
    return Intl.message(
      'Nest',
      name: 'specimenNest',
      desc: '',
      args: [],
    );
  }

  /// `Bones`
  String get specimenBones {
    return Intl.message(
      'Bones',
      name: 'specimenBones',
      desc: '',
      args: [],
    );
  }

  /// `Egg`
  String get specimenEgg {
    return Intl.message(
      'Egg',
      name: 'specimenEgg',
      desc: '',
      args: [],
    );
  }

  /// `Parasites`
  String get specimenParasites {
    return Intl.message(
      'Parasites',
      name: 'specimenParasites',
      desc: '',
      args: [],
    );
  }

  /// `Feathers`
  String get specimenFeathers {
    return Intl.message(
      'Feathers',
      name: 'specimenFeathers',
      desc: '',
      args: [],
    );
  }

  /// `Blood`
  String get specimenBlood {
    return Intl.message(
      'Blood',
      name: 'specimenBlood',
      desc: '',
      args: [],
    );
  }

  /// `Claw`
  String get specimenClaw {
    return Intl.message(
      'Claw',
      name: 'specimenClaw',
      desc: '',
      args: [],
    );
  }

  /// `Swab`
  String get specimenSwab {
    return Intl.message(
      'Swab',
      name: 'specimenSwab',
      desc: '',
      args: [],
    );
  }

  /// `Tissues`
  String get specimenTissues {
    return Intl.message(
      'Tissues',
      name: 'specimenTissues',
      desc: '',
      args: [],
    );
  }

  /// `Feces`
  String get specimenFeces {
    return Intl.message(
      'Feces',
      name: 'specimenFeces',
      desc: '',
      args: [],
    );
  }

  /// `Regurgite`
  String get specimenRegurgite {
    return Intl.message(
      'Regurgite',
      name: 'specimenRegurgite',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
