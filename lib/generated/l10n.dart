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
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
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
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Inventories`
  String get inventories {
    return Intl.message('Inventories', name: 'inventories', desc: '', args: []);
  }

  /// `Nests`
  String get nests {
    return Intl.message('Nests', name: 'nests', desc: '', args: []);
  }

  /// `{howMany, plural, one{Specimen} other{Specimens}}`
  String specimens(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Specimen',
      other: 'Specimens',
      name: 'specimens',
      desc: 'Titles and messages about specimens',
      args: [howMany],
    );
  }

  /// `Field journal`
  String get fieldJournal {
    return Intl.message(
      'Field journal',
      name: 'fieldJournal',
      desc: 'Field journal option in navigation drawer',
      args: [],
    );
  }

  /// `{howMany, plural, one{Journal entry} other{Journal entries}}`
  String journalEntries(int howMany) {
    return Intl.plural(
      howMany,
      one: 'Journal entry',
      other: 'Journal entries',
      name: 'journalEntries',
      desc: 'Titles and messages about field journal entries',
      args: [howMany],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: 'Settings title and button label',
      args: [],
    );
  }

  /// `General`
  String get general {
    return Intl.message(
      'General',
      name: 'general',
      desc: 'General section in settings',
      args: [],
    );
  }

  /// `Appearance`
  String get appearance {
    return Intl.message(
      'Appearance',
      name: 'appearance',
      desc: 'Appearance option in settings',
      args: [],
    );
  }

  /// `Select the mode`
  String get selectMode {
    return Intl.message(
      'Select the mode',
      name: 'selectMode',
      desc: 'Title of dialog to select the app mode',
      args: [],
    );
  }

  /// `Light`
  String get lightMode {
    return Intl.message(
      'Light',
      name: 'lightMode',
      desc: 'Light mode name',
      args: [],
    );
  }

  /// `Dark`
  String get darkMode {
    return Intl.message(
      'Dark',
      name: 'darkMode',
      desc: 'Dark mode name',
      args: [],
    );
  }

  /// `System theme`
  String get systemMode {
    return Intl.message(
      'System theme',
      name: 'systemMode',
      desc: 'System theme name',
      args: [],
    );
  }

  /// `Observer (abbreviation)`
  String get observerSetting {
    return Intl.message(
      'Observer (abbreviation)',
      name: 'observerSetting',
      desc: 'Observer option in settings',
      args: [],
    );
  }

  /// `Observer`
  String get observer {
    return Intl.message(
      'Observer',
      name: 'observer',
      desc: 'Title of dialog to inform observer abbreviation',
      args: [],
    );
  }

  /// `Observer abbreviation`
  String get observerAbbreviation {
    return Intl.message(
      'Observer abbreviation',
      name: 'observerAbbreviation',
      desc: 'Label of text field to inform observer abbreviation',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: 'Cancel button label',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: 'Save button label',
      args: [],
    );
  }

  /// `Simultaneous inventories`
  String get simultaneousInventories {
    return Intl.message(
      'Simultaneous inventories',
      name: 'simultaneousInventories',
      desc: 'Simultaneous inventories option in settings',
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
      desc: 'Titles and messages about inventories',
      args: [howMany],
    );
  }

  /// `{howMany, plural, one{inventory found} other{inventories found}}`
  String inventoryFound(int howMany) {
    return Intl.plural(
      howMany,
      one: 'inventory found',
      other: 'inventories found',
      name: 'inventoryFound',
      desc: 'Message showing how many inventories were found',
      args: [howMany],
    );
  }

  /// `Mackinnon lists`
  String get mackinnonLists {
    return Intl.message(
      'Mackinnon lists',
      name: 'mackinnonLists',
      desc: 'Mackinnon lists option in settings',
      args: [],
    );
  }

  /// `{howMany, plural, one{1 species} other{{howMany} species}} per list`
  String speciesPerList(int howMany) {
    return Intl.message(
      '${Intl.plural(howMany, one: '1 species', other: '$howMany species')} per list',
      name: 'speciesPerList',
      desc: 'How many species per list in settings screen',
      args: [howMany],
    );
  }

  /// `Species per list`
  String get speciesPerListTitle {
    return Intl.message(
      'Species per list',
      name: 'speciesPerListTitle',
      desc:
          'Title of dialog to inform the number of species per Mackinnon list',
      args: [],
    );
  }

  /// `Point counts`
  String get pointCounts {
    return Intl.message(
      'Point counts',
      name: 'pointCounts',
      desc: 'Point counts option in settings',
      args: [],
    );
  }

  /// `Duration (min)`
  String get durationMin {
    return Intl.message(
      'Duration (min)',
      name: 'durationMin',
      desc: 'Title of dialog to inform inventory duration in minutes',
      args: [],
    );
  }

  /// `{howMany, plural, one{1 minute} other{{howMany} minutes}} of duration`
  String inventoryDuration(int howMany) {
    return Intl.message(
      '${Intl.plural(howMany, one: '1 minute', other: '$howMany minutes')} of duration',
      name: 'inventoryDuration',
      desc: 'Time duration in minutes in settings screen',
      args: [howMany],
    );
  }

  /// `Timed qualitative lists`
  String get timedQualitativeLists {
    return Intl.message(
      'Timed qualitative lists',
      name: 'timedQualitativeLists',
      desc: 'Timed qualitative lists option in settings',
      args: [],
    );
  }

  /// `Interval qualitative lists`
  String get intervaledQualitativeLists {
    return Intl.message(
      'Interval qualitative lists',
      name: 'intervaledQualitativeLists',
      desc: 'Interval qualitative lists option in settings',
      args: [],
    );
  }

  /// `Format numbers`
  String get formatNumbers {
    return Intl.message(
      'Format numbers',
      name: 'formatNumbers',
      desc: 'Format numbers option in settings',
      args: [],
    );
  }

  /// `About the app`
  String get about {
    return Intl.message(
      'About the app',
      name: 'about',
      desc: 'About the app option in settings',
      args: [],
    );
  }

  /// `Danger zone`
  String get dangerZone {
    return Intl.message(
      'Danger zone',
      name: 'dangerZone',
      desc: 'Danger zone in settings',
      args: [],
    );
  }

  /// `Delete the app data`
  String get deleteAppData {
    return Intl.message(
      'Delete the app data',
      name: 'deleteAppData',
      desc: 'Delete app data option in settings',
      args: [],
    );
  }

  /// `All data will be erased. Use with caution! This action cannot be undone.`
  String get deleteAppDataDescription {
    return Intl.message(
      'All data will be erased. Use with caution! This action cannot be undone.',
      name: 'deleteAppDataDescription',
      desc: 'Description of the action to delete all app data',
      args: [],
    );
  }

  /// `Delete data`
  String get deleteData {
    return Intl.message(
      'Delete data',
      name: 'deleteData',
      desc: 'Title of dialog to confirm app data deletion',
      args: [],
    );
  }

  /// `Are you sure you want to delete all app data? This action cannot be undone.`
  String get deleteDataMessage {
    return Intl.message(
      'Are you sure you want to delete all app data? This action cannot be undone.',
      name: 'deleteDataMessage',
      desc: 'Message asking user for confirmation before delete all app data',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: 'Delete button label',
      args: [],
    );
  }

  /// `App data deleted successfully!`
  String get dataDeleted {
    return Intl.message(
      'App data deleted successfully!',
      name: 'dataDeleted',
      desc: 'Message informing user that the data was successfully deleted',
      args: [],
    );
  }

  /// `OK`
  String get ok {
    return Intl.message('OK', name: 'ok', desc: 'OK button label', args: []);
  }

  /// `Limit of simultaneous inventories reached.`
  String get simultaneousLimitReached {
    return Intl.message(
      'Limit of simultaneous inventories reached.',
      name: 'simultaneousLimitReached',
      desc:
          'Message shown when the limit of simultaneous inventories defined in settings is reached',
      args: [],
    );
  }

  /// `Sort by Time`
  String get sortByTime {
    return Intl.message(
      'Sort by Time',
      name: 'sortByTime',
      desc: 'Sort by time option in inventories list',
      args: [],
    );
  }

  /// `Sort by Name`
  String get sortByName {
    return Intl.message(
      'Sort by Name',
      name: 'sortByName',
      desc: 'Sort by name option in inventories list',
      args: [],
    );
  }

  /// `Sort ascending`
  String get sortAscending {
    return Intl.message(
      'Sort ascending',
      name: 'sortAscending',
      desc: 'Sort ascending option in inventories list',
      args: [],
    );
  }

  /// `Sort descending`
  String get sortDescending {
    return Intl.message(
      'Sort descending',
      name: 'sortDescending',
      desc: 'Sort descending option in inventories list',
      args: [],
    );
  }

  /// `Find inventories...`
  String get findInventories {
    return Intl.message(
      'Find inventories...',
      name: 'findInventories',
      desc: 'Hint text in inventories search field',
      args: [],
    );
  }

  /// `Active`
  String get active {
    return Intl.message(
      'Active',
      name: 'active',
      desc: 'Segmented button label to filter for active inventories or nests',
      args: [],
    );
  }

  /// `Finished`
  String get finished {
    return Intl.message(
      'Finished',
      name: 'finished',
      desc: 'Segmented button label to filter for finished inventories',
      args: [],
    );
  }

  /// `No inventories found.`
  String get noInventoriesFound {
    return Intl.message(
      'No inventories found.',
      name: 'noInventoriesFound',
      desc: 'Text shown when no inventories found',
      args: [],
    );
  }

  /// `Delete inventory`
  String get deleteInventory {
    return Intl.message(
      'Delete inventory',
      name: 'deleteInventory',
      desc: 'Delete inventory option in bottom sheet',
      args: [],
    );
  }

  /// `Confirm delete`
  String get confirmDelete {
    return Intl.message(
      'Confirm delete',
      name: 'confirmDelete',
      desc: 'Title of dialog for confirm record deletion',
      args: [],
    );
  }

  /// `Are you sure you want to delete {howMany, plural, one{{gender, select, male{this} female{this} other{this}}} other{{gender, select, male{these} female{these} other{these}}}} {what}?`
  String confirmDeleteMessage(int howMany, String gender, String what) {
    return Intl.message(
      'Are you sure you want to delete ${Intl.plural(howMany, one: '{gender, select, male{this} female{this} other{this}}', other: '{gender, select, male{these} female{these} other{these}}')} $what?',
      name: 'confirmDeleteMessage',
      desc: 'Message asking user confirmation to delete record',
      args: [howMany, gender, what],
    );
  }

  /// `Confirm finish`
  String get confirmFinish {
    return Intl.message(
      'Confirm finish',
      name: 'confirmFinish',
      desc: 'Title of dialog to confirm finishing an inventory',
      args: [],
    );
  }

  /// `Are you sure you want to finish this inventory?`
  String get confirmFinishMessage {
    return Intl.message(
      'Are you sure you want to finish this inventory?',
      name: 'confirmFinishMessage',
      desc: 'Message asking confirmation to finish an inventory',
      args: [],
    );
  }

  /// `Inventory automatically finished. Do you want to keep active or finish this inventory?`
  String get confirmAutoFinishMessage {
    return Intl.message(
      'Inventory automatically finished. Do you want to keep active or finish this inventory?',
      name: 'confirmAutoFinishMessage',
      desc: 'Message asking confirmation to finish an inventory automatically',
      args: [],
    );
  }

  /// `Finish`
  String get finish {
    return Intl.message(
      'Finish',
      name: 'finish',
      desc: 'Finish button label',
      args: [],
    );
  }

  /// `Keep active`
  String get keepRunning {
    return Intl.message(
      'Keep active',
      name: 'keepRunning',
      desc: 'Keep running button label',
      args: [],
    );
  }

  /// `New inventory`
  String get newInventory {
    return Intl.message(
      'New inventory',
      name: 'newInventory',
      desc: 'Title of dialog when adding new inventory',
      args: [],
    );
  }

  /// `{howMany, plural, zero{species} one{species} other{species}}`
  String speciesCount(int howMany) {
    return Intl.plural(
      howMany,
      zero: 'species',
      one: 'species',
      other: 'species',
      name: 'speciesCount',
      desc: 'How many species the inventory have',
      args: [howMany],
    );
  }

  /// `Pause`
  String get pause {
    return Intl.message(
      'Pause',
      name: 'pause',
      desc: 'Pause button hint',
      args: [],
    );
  }

  /// `Resume`
  String get resume {
    return Intl.message(
      'Resume',
      name: 'resume',
      desc: 'Resume button hint',
      args: [],
    );
  }

  /// `Export`
  String get export {
    return Intl.message(
      'Export',
      name: 'export',
      desc: 'Export button hint',
      args: [],
    );
  }

  /// `Export {what}`
  String exportWhat(String what) {
    return Intl.message(
      'Export $what',
      name: 'exportWhat',
      desc: 'Menu option to export one record',
      args: [what],
    );
  }

  /// `Export all`
  String get exportAll {
    return Intl.message(
      'Export all',
      name: 'exportAll',
      desc: 'Export all button hint',
      args: [],
    );
  }

  /// `Export all {what}`
  String exportAllWhat(String what) {
    return Intl.message(
      'Export all $what',
      name: 'exportAllWhat',
      desc: 'Menu option to export all records',
      args: [what],
    );
  }

  /// `Finish inventory`
  String get finishInventory {
    return Intl.message(
      'Finish inventory',
      name: 'finishInventory',
      desc: 'Menu option to finish the inventory',
      args: [],
    );
  }

  /// `* required`
  String get requiredField {
    return Intl.message(
      '* required',
      name: 'requiredField',
      desc: 'Auxiliary label informing that the field is required',
      args: [],
    );
  }

  /// `Inventory type`
  String get inventoryType {
    return Intl.message(
      'Inventory type',
      name: 'inventoryType',
      desc: 'Inventory type field label',
      args: [],
    );
  }

  /// `Please, select an inventory type`
  String get selectInventoryType {
    return Intl.message(
      'Please, select an inventory type',
      name: 'selectInventoryType',
      desc: 'Validation message shown when the inventory type field is empty',
      args: [],
    );
  }

  /// `Inventory ID`
  String get inventoryId {
    return Intl.message(
      'Inventory ID',
      name: 'inventoryId',
      desc: 'Inventory ID field label',
      args: [],
    );
  }

  /// `Generate ID`
  String get generateId {
    return Intl.message(
      'Generate ID',
      name: 'generateId',
      desc: 'Title of dialog to generate an inventory ID',
      args: [],
    );
  }

  /// `Site name or abbreviation`
  String get siteAbbreviation {
    return Intl.message(
      'Site name or abbreviation',
      name: 'siteAbbreviation',
      desc:
          'Field label asking the inventory site name or abbreviation to generate the ID',
      args: [],
    );
  }

  /// `* optional`
  String get optional {
    return Intl.message(
      '* optional',
      name: 'optional',
      desc: 'Auxiliary label informing that the field is optional',
      args: [],
    );
  }

  /// `Please, insert an ID for the inventory`
  String get insertInventoryId {
    return Intl.message(
      'Please, insert an ID for the inventory',
      name: 'insertInventoryId',
      desc: 'Validation message shown when the inventory ID is empty',
      args: [],
    );
  }

  /// `Duration`
  String get duration {
    return Intl.message(
      'Duration',
      name: 'duration',
      desc: 'Time duration field label',
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
      desc: 'Field suffix and messages containing duration of time',
      args: [howMany],
    );
  }

  /// `Insert a duration`
  String get insertDuration {
    return Intl.message(
      'Insert a duration',
      name: 'insertDuration',
      desc: 'Validation message shown when duration is empty',
      args: [],
    );
  }

  /// `Max species`
  String get maxSpecies {
    return Intl.message(
      'Max species',
      name: 'maxSpecies',
      desc: 'Max number of species field label',
      args: [],
    );
  }

  /// `Insert the max of species`
  String get insertMaxSpecies {
    return Intl.message(
      'Insert the max of species',
      name: 'insertMaxSpecies',
      desc: 'Validation message shown when the max of species field is empty',
      args: [],
    );
  }

  /// `Must be equal or higher than 5`
  String get mustBeBiggerThanFive {
    return Intl.message(
      'Must be equal or higher than 5',
      name: 'mustBeBiggerThanFive',
      desc:
          'Validation message shown when the max of species is lower than five',
      args: [],
    );
  }

  /// `Start inventory`
  String get startInventory {
    return Intl.message(
      'Start inventory',
      name: 'startInventory',
      desc: 'Start inventory button label',
      args: [],
    );
  }

  /// `This inventory ID already exists.`
  String get inventoryIdAlreadyExists {
    return Intl.message(
      'This inventory ID already exists.',
      name: 'inventoryIdAlreadyExists',
      desc: 'Message shown when the informed inventory ID already exists',
      args: [],
    );
  }

  /// `Error inserting inventory`
  String get errorInsertingInventory {
    return Intl.message(
      'Error inserting inventory',
      name: 'errorInsertingInventory',
      desc: 'Message shown if an error occurred while inserting an inventory',
      args: [],
    );
  }

  /// `Species by inventory`
  String get reportSpeciesByInventory {
    return Intl.message(
      'Species by inventory',
      name: 'reportSpeciesByInventory',
      desc: 'Title of report option to show species by inventory',
      args: [],
    );
  }

  /// `Total Species`
  String get totalSpecies {
    return Intl.message(
      'Total Species',
      name: 'totalSpecies',
      desc: 'Total species field label',
      args: [],
    );
  }

  /// `Total Individuals`
  String get totalIndividuals {
    return Intl.message(
      'Total Individuals',
      name: 'totalIndividuals',
      desc: 'Total individuals field label',
      args: [],
    );
  }

  /// `Species accumulation curve`
  String get speciesAccumulationCurve {
    return Intl.message(
      'Species accumulation curve',
      name: 'speciesAccumulationCurve',
      desc: 'Title of report option to show species accumulation curve',
      args: [],
    );
  }

  /// `Species accumulated`
  String get speciesAccumulated {
    return Intl.message(
      'Species accumulated',
      name: 'speciesAccumulated',
      desc: 'Species accumulated field label',
      args: [],
    );
  }

  /// `Time (10 minutes intervals)`
  String get timeMinutes {
    return Intl.message(
      'Time (10 minutes intervals)',
      name: 'timeMinutes',
      desc: 'Time in minutes field label',
      args: [],
    );
  }

  /// `Species counted`
  String get speciesCounted {
    return Intl.message(
      'Species counted',
      name: 'speciesCounted',
      desc: 'Species counted field label',
      args: [],
    );
  }

  /// `Individuals counted`
  String get individualsCounted {
    return Intl.message(
      'Individuals counted',
      name: 'individualsCounted',
      desc: 'Individuals counted field label',
      args: [],
    );
  }

  /// `Close`
  String get close {
    return Intl.message(
      'Close',
      name: 'close',
      desc: 'Close button label',
      args: [],
    );
  }

  /// `Refresh`
  String get refreshList {
    return Intl.message(
      'Refresh',
      name: 'refreshList',
      desc: 'Refresh button hint',
      args: [],
    );
  }

  /// `No data available.`
  String get noDataAvailable {
    return Intl.message(
      'No data available.',
      name: 'noDataAvailable',
      desc: 'Message shown when there is no data to show',
      args: [],
    );
  }

  /// `Clear selection`
  String get clearSelection {
    return Intl.message(
      'Clear selection',
      name: 'clearSelection',
      desc: 'Button label to clear the selection',
      args: [],
    );
  }

  /// `Importing inventory...`
  String get importingInventory {
    return Intl.message(
      'Importing inventory...',
      name: 'importingInventory',
      desc: 'Message shown when importing an inventory',
      args: [],
    );
  }

  /// `Inventory imported successfully!`
  String get inventoryImportedSuccessfully {
    return Intl.message(
      'Inventory imported successfully!',
      name: 'inventoryImportedSuccessfully',
      desc: 'Message shown when an inventory is imported successfully',
      args: [],
    );
  }

  /// `Inventory import failed.`
  String get inventoryImportFailed {
    return Intl.message(
      'Inventory import failed.',
      name: 'inventoryImportFailed',
      desc: 'Message shown when an inventory import failed',
      args: [],
    );
  }

  /// `No file selected.`
  String get noFileSelected {
    return Intl.message(
      'No file selected.',
      name: 'noFileSelected',
      desc: 'Message shown when no file is selected to import',
      args: [],
    );
  }

  /// `Import`
  String get import {
    return Intl.message(
      'Import',
      name: 'import',
      desc: 'Import button label',
      args: [],
    );
  }

  /// `Error importing inventory.`
  String get errorImportingInventory {
    return Intl.message(
      'Error importing inventory.',
      name: 'errorImportingInventory',
      desc: 'Message shown when an error occurred while importing an inventory',
      args: [],
    );
  }

  /// `Vegetation data`
  String get vegetationData {
    return Intl.message(
      'Vegetation data',
      name: 'vegetationData',
      desc: 'Vegetation data title or label',
      args: [],
    );
  }

  /// `Herbs`
  String get herbs {
    return Intl.message(
      'Herbs',
      name: 'herbs',
      desc: 'Herbs section label in vegetation data',
      args: [],
    );
  }

  /// `Distribution`
  String get distribution {
    return Intl.message(
      'Distribution',
      name: 'distribution',
      desc: 'Distribution field label',
      args: [],
    );
  }

  /// `Proportion`
  String get proportion {
    return Intl.message(
      'Proportion',
      name: 'proportion',
      desc: 'Proportion field label',
      args: [],
    );
  }

  /// `Height`
  String get height {
    return Intl.message(
      'Height',
      name: 'height',
      desc: 'Average height field label',
      args: [],
    );
  }

  /// `Shrubs`
  String get shrubs {
    return Intl.message(
      'Shrubs',
      name: 'shrubs',
      desc: 'Shrubs section label in vegetation data',
      args: [],
    );
  }

  /// `Trees`
  String get trees {
    return Intl.message(
      'Trees',
      name: 'trees',
      desc: 'Trees section label in vegetation data',
      args: [],
    );
  }

  /// `Notes`
  String get notes {
    return Intl.message(
      'Notes',
      name: 'notes',
      desc: 'Notes field label',
      args: [],
    );
  }

  /// `Insert proportion`
  String get insertProportion {
    return Intl.message(
      'Insert proportion',
      name: 'insertProportion',
      desc: 'Validation message shown when proportion field is empty',
      args: [],
    );
  }

  /// `Insert height`
  String get insertHeight {
    return Intl.message(
      'Insert height',
      name: 'insertHeight',
      desc: 'Validation message shown when height field is empty',
      args: [],
    );
  }

  /// `Error saving vegetation data`
  String get errorSavingVegetation {
    return Intl.message(
      'Error saving vegetation data',
      name: 'errorSavingVegetation',
      desc:
          'Message shown when an error occurred while saving a vegetation record',
      args: [],
    );
  }

  /// `Weather data`
  String get weatherData {
    return Intl.message(
      'Weather data',
      name: 'weatherData',
      desc: 'Weather data title or label',
      args: [],
    );
  }

  /// `Cloud cover`
  String get cloudCover {
    return Intl.message(
      'Cloud cover',
      name: 'cloudCover',
      desc: 'Cloud cover field label',
      args: [],
    );
  }

  /// `Precipitation`
  String get precipitation {
    return Intl.message(
      'Precipitation',
      name: 'precipitation',
      desc: 'Precipitation field label',
      args: [],
    );
  }

  /// `Select precipitation`
  String get selectPrecipitation {
    return Intl.message(
      'Select precipitation',
      name: 'selectPrecipitation',
      desc: 'Validation message shown when the precipitation field is empty',
      args: [],
    );
  }

  /// `Temperature`
  String get temperature {
    return Intl.message(
      'Temperature',
      name: 'temperature',
      desc: 'Temperature field label',
      args: [],
    );
  }

  /// `Wind speed`
  String get windSpeed {
    return Intl.message(
      'Wind speed',
      name: 'windSpeed',
      desc: 'Wind speed field label',
      args: [],
    );
  }

  /// `Must be between 0 and 12 bft`
  String get windSpeedRangeError {
    return Intl.message(
      'Must be between 0 and 12 bft',
      name: 'windSpeedRangeError',
      desc: 'Validation message shown when the wind speed is out of range',
      args: [],
    );
  }

  /// `Error saving weather data`
  String get errorSavingWeather {
    return Intl.message(
      'Error saving weather data',
      name: 'errorSavingWeather',
      desc:
          'Message shown when an error occurred while saving a weather record',
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
      desc: 'Tabs and messages about species',
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
      desc: 'Abbreviation of species in labels and edits',
      args: [howMany],
    );
  }

  /// `Vegetation`
  String get vegetation {
    return Intl.message(
      'Vegetation',
      name: 'vegetation',
      desc: 'Vegetation tab',
      args: [],
    );
  }

  /// `Weather`
  String get weather {
    return Intl.message(
      'Weather',
      name: 'weather',
      desc: 'Weather tab',
      args: [],
    );
  }

  /// `Error getting location.`
  String get errorGettingLocation {
    return Intl.message(
      'Error getting location.',
      name: 'errorGettingLocation',
      desc:
          'Message shown when an error occurred while getting the GPS location',
      args: [],
    );
  }

  /// `POI`
  String get poi {
    return Intl.message(
      'POI',
      name: 'poi',
      desc: 'Point of interest abbreviation in labels',
      args: [],
    );
  }

  /// `Species information`
  String get speciesInfo {
    return Intl.message(
      'Species information',
      name: 'speciesInfo',
      desc: 'Species information expandable list title',
      args: [],
    );
  }

  /// `Count`
  String get count {
    return Intl.message(
      'Count',
      name: 'count',
      desc:
          'Species info showing individuals count for the species in the actual list',
      args: [],
    );
  }

  /// `Record time`
  String get recordTime {
    return Intl.message(
      'Record time',
      name: 'recordTime',
      desc:
          'Species info showing the record time for the species in the actual list',
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
      desc: 'Messages and labels about individuals',
      args: [howMany],
    );
  }

  /// `Out of the sample`
  String get outOfSample {
    return Intl.message(
      'Out of the sample',
      name: 'outOfSample',
      desc:
          'Species info for when the species was added after the inventory was finished',
      args: [],
    );
  }

  /// `Within the sample`
  String get withinSample {
    return Intl.message(
      'Within the sample',
      name: 'withinSample',
      desc:
          'Species info for when the species was added while the inventory was active',
      args: [],
    );
  }

  /// `No POI found.`
  String get noPoiFound {
    return Intl.message(
      'No POI found.',
      name: 'noPoiFound',
      desc: 'Message shown when no POI was found',
      args: [],
    );
  }

  /// `New POI`
  String get newPoi {
    return Intl.message(
      'New POI',
      name: 'newPoi',
      desc: 'New POI button hint',
      args: [],
    );
  }

  /// `Delete POI`
  String get deletePoi {
    return Intl.message(
      'Delete POI',
      name: 'deletePoi',
      desc: 'Menu option to delete POI',
      args: [],
    );
  }

  /// `Decrease individuals count`
  String get decreaseIndividuals {
    return Intl.message(
      'Decrease individuals count',
      name: 'decreaseIndividuals',
      desc: 'Decrease individuals count button hint',
      args: [],
    );
  }

  /// `Increase individuals count`
  String get increaseIndividuals {
    return Intl.message(
      'Increase individuals count',
      name: 'increaseIndividuals',
      desc: 'Increase individuals count button hint',
      args: [],
    );
  }

  /// `Add POI`
  String get addPoi {
    return Intl.message(
      'Add POI',
      name: 'addPoi',
      desc: 'Add POI button hint',
      args: [],
    );
  }

  /// `Edit count`
  String get editCount {
    return Intl.message(
      'Edit count',
      name: 'editCount',
      desc: 'Title of dialog to edit the number of individuals of a species',
      args: [],
    );
  }

  /// `Individuals count`
  String get individualsCount {
    return Intl.message(
      'Individuals count',
      name: 'individualsCount',
      desc: 'Individuals count field label',
      args: [],
    );
  }

  /// `Delete vegetation record`
  String get deleteVegetation {
    return Intl.message(
      'Delete vegetation record',
      name: 'deleteVegetation',
      desc: 'Menu option to delete a vegetation record',
      args: [],
    );
  }

  /// `No vegetation records.`
  String get noVegetationFound {
    return Intl.message(
      'No vegetation records.',
      name: 'noVegetationFound',
      desc: 'Message shown when the vegetation list is empty',
      args: [],
    );
  }

  /// `weather record`
  String get weatherRecord {
    return Intl.message(
      'weather record',
      name: 'weatherRecord',
      desc: 'Weather record label used in messages',
      args: [],
    );
  }

  /// `No weather records.`
  String get noWeatherFound {
    return Intl.message(
      'No weather records.',
      name: 'noWeatherFound',
      desc: 'Message shown when the weather list is empty',
      args: [],
    );
  }

  /// `Delete weather record`
  String get deleteWeather {
    return Intl.message(
      'Delete weather record',
      name: 'deleteWeather',
      desc: 'Menu option to delete a weather record',
      args: [],
    );
  }

  /// `Find nests...`
  String get findNests {
    return Intl.message(
      'Find nests...',
      name: 'findNests',
      desc: 'Text hint in the nest search field',
      args: [],
    );
  }

  /// `Inactive`
  String get inactive {
    return Intl.message(
      'Inactive',
      name: 'inactive',
      desc: 'Segmented button label for filter of inactive nests',
      args: [],
    );
  }

  /// `No nests found.`
  String get noNestsFound {
    return Intl.message(
      'No nests found.',
      name: 'noNestsFound',
      desc: 'Message shown when the nests list is empty',
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
      desc: 'Messages and labels about nests',
      args: [howMany],
    );
  }

  /// `New nest`
  String get newNest {
    return Intl.message(
      'New nest',
      name: 'newNest',
      desc: 'New nest dialog title',
      args: [],
    );
  }

  /// `Delete nest`
  String get deleteNest {
    return Intl.message(
      'Delete nest',
      name: 'deleteNest',
      desc: 'Menu option to delete a nest',
      args: [],
    );
  }

  /// `Confirm fate`
  String get confirmFate {
    return Intl.message(
      'Confirm fate',
      name: 'confirmFate',
      desc: 'Title of dialog to confirm nest fate',
      args: [],
    );
  }

  /// `Nest fate *`
  String get nestFate {
    return Intl.message(
      'Nest fate *',
      name: 'nestFate',
      desc: 'Nest fate field label',
      args: [],
    );
  }

  /// `Error inactivating nest: {errorMessage}`
  String errorInactivatingNest(String errorMessage) {
    return Intl.message(
      'Error inactivating nest: $errorMessage',
      name: 'errorInactivatingNest',
      desc: 'Error message when inactivating nest',
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
      desc: 'Nest revision messages, tabs and labels',
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
      desc: 'Egg messages, tabs and labels',
      args: [howMany],
    );
  }

  /// `Nest information`
  String get nestInfo {
    return Intl.message(
      'Nest information',
      name: 'nestInfo',
      desc: 'Nest information expandable list title',
      args: [],
    );
  }

  /// `Date and time found`
  String get timeFound {
    return Intl.message(
      'Date and time found',
      name: 'timeFound',
      desc: 'Time found field label',
      args: [],
    );
  }

  /// `Locality`
  String get locality {
    return Intl.message(
      'Locality',
      name: 'locality',
      desc: 'Locality field label',
      args: [],
    );
  }

  /// `Nest support`
  String get nestSupport {
    return Intl.message(
      'Nest support',
      name: 'nestSupport',
      desc: 'Nest support field label',
      args: [],
    );
  }

  /// `Height above ground`
  String get heightAboveGround {
    return Intl.message(
      'Height above ground',
      name: 'heightAboveGround',
      desc: 'Height above ground field label',
      args: [],
    );
  }

  /// `Male`
  String get male {
    return Intl.message(
      'Male',
      name: 'male',
      desc: 'Male field label',
      args: [],
    );
  }

  /// `Female`
  String get female {
    return Intl.message(
      'Female',
      name: 'female',
      desc: 'Female field label',
      args: [],
    );
  }

  /// `Nest helpers`
  String get helpers {
    return Intl.message(
      'Nest helpers',
      name: 'helpers',
      desc: 'Nest helpers field label',
      args: [],
    );
  }

  /// `No eggs recorded.`
  String get noEggsFound {
    return Intl.message(
      'No eggs recorded.',
      name: 'noEggsFound',
      desc: 'Message shown when the eggs list is empty',
      args: [],
    );
  }

  /// `Delete egg`
  String get deleteEgg {
    return Intl.message(
      'Delete egg',
      name: 'deleteEgg',
      desc: 'Menu option to delete an egg',
      args: [],
    );
  }

  /// `No revisions recorded.`
  String get noRevisionsFound {
    return Intl.message(
      'No revisions recorded.',
      name: 'noRevisionsFound',
      desc: 'Message shown when the nest revision list is empty',
      args: [],
    );
  }

  /// `Delete nest revision`
  String get deleteRevision {
    return Intl.message(
      'Delete nest revision',
      name: 'deleteRevision',
      desc: 'Menu option to delete a nest revision',
      args: [],
    );
  }

  /// `Host`
  String get host {
    return Intl.message(
      'Host',
      name: 'host',
      desc: 'Nest owner section label',
      args: [],
    );
  }

  /// `Nidoparasite`
  String get nidoparasite {
    return Intl.message(
      'Nidoparasite',
      name: 'nidoparasite',
      desc: 'Nidoparasite section label',
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
      desc: 'Nestling messages and labels',
      args: [howMany],
    );
  }

  /// `Add egg`
  String get addEgg {
    return Intl.message(
      'Add egg',
      name: 'addEgg',
      desc: 'Add egg dialog title',
      args: [],
    );
  }

  /// `Field number`
  String get fieldNumber {
    return Intl.message(
      'Field number',
      name: 'fieldNumber',
      desc: 'Field number field label',
      args: [],
    );
  }

  /// `Insert the field number`
  String get insertFieldNumber {
    return Intl.message(
      'Insert the field number',
      name: 'insertFieldNumber',
      desc: 'Validation message shown when the field number is empty',
      args: [],
    );
  }

  /// `Select a species`
  String get selectSpecies {
    return Intl.message(
      'Select a species',
      name: 'selectSpecies',
      desc: 'Validation message shown when the species is empty',
      args: [],
    );
  }

  /// `Egg shape`
  String get eggShape {
    return Intl.message(
      'Egg shape',
      name: 'eggShape',
      desc: 'Egg shape field label',
      args: [],
    );
  }

  /// `Width`
  String get width {
    return Intl.message(
      'Width',
      name: 'width',
      desc: 'Width field label',
      args: [],
    );
  }

  /// `Length`
  String get length {
    return Intl.message(
      'Length',
      name: 'length',
      desc: 'Length field label',
      args: [],
    );
  }

  /// `Weight`
  String get weight {
    return Intl.message(
      'Weight',
      name: 'weight',
      desc: 'Weight field label',
      args: [],
    );
  }

  /// `An egg with this field number already exists.`
  String get errorEggAlreadyExists {
    return Intl.message(
      'An egg with this field number already exists.',
      name: 'errorEggAlreadyExists',
      desc:
          'Message shown when an egg already exists with the same field number',
      args: [],
    );
  }

  /// `Error saving egg.`
  String get errorSavingEgg {
    return Intl.message(
      'Error saving egg.',
      name: 'errorSavingEgg',
      desc: 'Message shown when an error occurred while saving an egg',
      args: [],
    );
  }

  /// `Please, insert locality name`
  String get insertLocality {
    return Intl.message(
      'Please, insert locality name',
      name: 'insertLocality',
      desc: 'Validation message shown when locality name is empty',
      args: [],
    );
  }

  /// `Please, insert nest support`
  String get insertNestSupport {
    return Intl.message(
      'Please, insert nest support',
      name: 'insertNestSupport',
      desc: 'Validation message shown when nest support is empty',
      args: [],
    );
  }

  /// `A nest with this field number already exists.`
  String get errorNestAlreadyExists {
    return Intl.message(
      'A nest with this field number already exists.',
      name: 'errorNestAlreadyExists',
      desc:
          'Message shown when a nest already exists with the same field number',
      args: [],
    );
  }

  /// `Error saving nest.`
  String get errorSavingNest {
    return Intl.message(
      'Error saving nest.',
      name: 'errorSavingNest',
      desc: 'Message shown when an error occurred while saving a nest',
      args: [],
    );
  }

  /// `Nest revision`
  String get nestRevision {
    return Intl.message(
      'Nest revision',
      name: 'nestRevision',
      desc: 'New nest revision dialog title',
      args: [],
    );
  }

  /// `Nest status`
  String get nestStatus {
    return Intl.message(
      'Nest status',
      name: 'nestStatus',
      desc: 'Nest status field label',
      args: [],
    );
  }

  /// `Nest phase`
  String get nestPhase {
    return Intl.message(
      'Nest phase',
      name: 'nestPhase',
      desc: 'Nest phase field label',
      args: [],
    );
  }

  /// `Philornis larvae present`
  String get philornisLarvaePresent {
    return Intl.message(
      'Philornis larvae present',
      name: 'philornisLarvaePresent',
      desc: 'Philornis larvae present field label',
      args: [],
    );
  }

  /// `Error saving nest revision.`
  String get errorSavingRevision {
    return Intl.message(
      'Error saving nest revision.',
      name: 'errorSavingRevision',
      desc: 'Message shown when an error occurred while saving a nest revision',
      args: [],
    );
  }

  /// `Find specimens...`
  String get findSpecimens {
    return Intl.message(
      'Find specimens...',
      name: 'findSpecimens',
      desc: 'Text hint in the specimen search field',
      args: [],
    );
  }

  /// `No specimen collected.`
  String get noSpecimenCollected {
    return Intl.message(
      'No specimen collected.',
      name: 'noSpecimenCollected',
      desc: 'Message shown when the specimens list is empty',
      args: [],
    );
  }

  /// `New specimen`
  String get newSpecimen {
    return Intl.message(
      'New specimen',
      name: 'newSpecimen',
      desc: 'New specimen dialog title',
      args: [],
    );
  }

  /// `Delete specimen`
  String get deleteSpecimen {
    return Intl.message(
      'Delete specimen',
      name: 'deleteSpecimen',
      desc: 'Menu option to delete a specimen',
      args: [],
    );
  }

  /// `Specimen type`
  String get specimenType {
    return Intl.message(
      'Specimen type',
      name: 'specimenType',
      desc: 'Specimen type field label',
      args: [],
    );
  }

  /// `A specimen with this field number already exists.`
  String get errorSpecimenAlreadyExists {
    return Intl.message(
      'A specimen with this field number already exists.',
      name: 'errorSpecimenAlreadyExists',
      desc:
          'Message shown when a specimen already exists with the same field number',
      args: [],
    );
  }

  /// `Error saving specimen.`
  String get errorSavingSpecimen {
    return Intl.message(
      'Error saving specimen.',
      name: 'errorSavingSpecimen',
      desc: 'Message shown when an error occurred while saving a specimen',
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
      desc: 'Images titles, messages and labels',
      args: [howMany],
    );
  }

  /// `No images found.`
  String get noImagesFound {
    return Intl.message(
      'No images found.',
      name: 'noImagesFound',
      desc: 'Message shown when the images list is empty',
      args: [],
    );
  }

  /// `Add image`
  String get addImage {
    return Intl.message(
      'Add image',
      name: 'addImage',
      desc: 'Add image dialog title',
      args: [],
    );
  }

  /// `Gallery`
  String get gallery {
    return Intl.message(
      'Gallery',
      name: 'gallery',
      desc: 'Gallery button label',
      args: [],
    );
  }

  /// `Camera`
  String get camera {
    return Intl.message(
      'Camera',
      name: 'camera',
      desc: 'Camera button label',
      args: [],
    );
  }

  /// `Permission denied.`
  String get permissionDenied {
    return Intl.message(
      'Permission denied.',
      name: 'permissionDenied',
      desc: 'Message shown when the permission was denied',
      args: [],
    );
  }

  /// `Permission denied permanently.`
  String get permissionDeniedPermanently {
    return Intl.message(
      'Permission denied permanently.',
      name: 'permissionDeniedPermanently',
      desc: 'Message shown when the permission was denied permanently',
      args: [],
    );
  }

  /// `Share image`
  String get shareImage {
    return Intl.message(
      'Share image',
      name: 'shareImage',
      desc: 'Menu option to share an image',
      args: [],
    );
  }

  /// `Edit image notes`
  String get editImageNotes {
    return Intl.message(
      'Edit image notes',
      name: 'editImageNotes',
      desc: 'Menu option to edit the image notes',
      args: [],
    );
  }

  /// `Delete image`
  String get deleteImage {
    return Intl.message(
      'Delete image',
      name: 'deleteImage',
      desc: 'Menu option to delete an image',
      args: [],
    );
  }

  /// `Edit notes`
  String get editNotes {
    return Intl.message(
      'Edit notes',
      name: 'editNotes',
      desc: 'Edit notes dialog title',
      args: [],
    );
  }

  /// `Image details`
  String get imageDetails {
    return Intl.message(
      'Image details',
      name: 'imageDetails',
      desc: 'Image details dialog title',
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
      desc: 'Message when inventory was exported',
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
      desc: 'Subject when exporting inventories',
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
      desc: 'Message when nest was exported',
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
      desc: 'Subject when exporting nest',
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
      desc: 'Message when specimen was exported',
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
      desc: 'Subject when exporting specimen',
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
      desc: 'Hint in the species\' search field',
      args: [],
    );
  }

  /// `Add species`
  String get addSpecies {
    return Intl.message(
      'Add species',
      name: 'addSpecies',
      desc: 'Add species dialog title and text hint in find species field',
      args: [],
    );
  }

  /// `Delete species`
  String get deleteSpecies {
    return Intl.message(
      'Delete species',
      name: 'deleteSpecies',
      desc: 'Menu option to delete a species',
      args: [],
    );
  }

  /// `Species notes`
  String get speciesNotes {
    return Intl.message(
      'Species notes',
      name: 'speciesNotes',
      desc: 'Menu option to add notes to a species',
      args: [],
    );
  }

  /// `No species recorded`
  String get noSpeciesFound {
    return Intl.message(
      'No species recorded',
      name: 'noSpeciesFound',
      desc: 'Message shown when the species list is empty',
      args: [],
    );
  }

  /// `Species name`
  String get speciesName {
    return Intl.message(
      'Species name',
      name: 'speciesName',
      desc: 'Species name field label',
      args: [],
    );
  }

  /// `Species already added to the list`
  String get errorSpeciesAlreadyExists {
    return Intl.message(
      'Species already added to the list',
      name: 'errorSpeciesAlreadyExists',
      desc: 'Message shown when a species is already in the list',
      args: [],
    );
  }

  /// `Add to the sample`
  String get addSpeciesToSample {
    return Intl.message(
      'Add to the sample',
      name: 'addSpeciesToSample',
      desc: 'Menu option to add species to the sample',
      args: [],
    );
  }

  /// `Remove from the sample`
  String get removeSpeciesFromSample {
    return Intl.message(
      'Remove from the sample',
      name: 'removeSpeciesFromSample',
      desc: 'Menu option to remove species from the sample',
      args: [],
    );
  }

  /// `Reactivate inventory`
  String get reactivateInventory {
    return Intl.message(
      'Reactivate inventory',
      name: 'reactivateInventory',
      desc: 'Menu option to reactivate a finished inventory',
      args: [],
    );
  }

  /// `List finished`
  String get listFinished {
    return Intl.message(
      'List finished',
      name: 'listFinished',
      desc: 'Dialog title when a Mackinnon list was finished',
      args: [],
    );
  }

  /// `The list reached the maximum of species. Do you want to start the next list or finish now?`
  String get listFinishedMessage {
    return Intl.message(
      'The list reached the maximum of species. Do you want to start the next list or finish now?',
      name: 'listFinishedMessage',
      desc:
          'Message asking user to take action when a Mackinnon list was finished',
      args: [],
    );
  }

  /// `Start next list`
  String get startNextList {
    return Intl.message(
      'Start next list',
      name: 'startNextList',
      desc: 'Button caption to start the next Mackinnon list',
      args: [],
    );
  }

  /// `Edit specimen`
  String get editSpecimen {
    return Intl.message(
      'Edit specimen',
      name: 'editSpecimen',
      desc: 'Menu option to edit a specimen',
      args: [],
    );
  }

  /// `Edit nest`
  String get editNest {
    return Intl.message(
      'Edit nest',
      name: 'editNest',
      desc: 'Menu option to edit a nest',
      args: [],
    );
  }

  /// `Edit nest revision`
  String get editNestRevision {
    return Intl.message(
      'Edit nest revision',
      name: 'editNestRevision',
      desc: 'Menu option to edit a nest revision',
      args: [],
    );
  }

  /// `Edit egg`
  String get editEgg {
    return Intl.message(
      'Edit egg',
      name: 'editEgg',
      desc: 'Menu option to edit an egg',
      args: [],
    );
  }

  /// `Edit weather`
  String get editWeather {
    return Intl.message(
      'Edit weather',
      name: 'editWeather',
      desc: 'Menu option to edit a weather record',
      args: [],
    );
  }

  /// `Edit vegetation`
  String get editVegetation {
    return Intl.message(
      'Edit vegetation',
      name: 'editVegetation',
      desc: 'Menu option to edit a vegetation record',
      args: [],
    );
  }

  /// `Edit ID`
  String get editInventoryId {
    return Intl.message(
      'Edit ID',
      name: 'editInventoryId',
      desc: 'Menu option to edit an inventory ID',
      args: [],
    );
  }

  /// `Delete species`
  String get confirmDeleteSpecies {
    return Intl.message(
      'Delete species',
      name: 'confirmDeleteSpecies',
      desc:
          'Title of dialog to confirm deletion of species in other inventories',
      args: [],
    );
  }

  /// `Do you want to delete {speciesName} from other active inventories?`
  String confirmDeleteSpeciesMessage(String speciesName) {
    return Intl.message(
      'Do you want to delete $speciesName from other active inventories?',
      name: 'confirmDeleteSpeciesMessage',
      desc:
          'Message of dialog to confirm deletion of species in other inventories',
      args: [speciesName],
    );
  }

  /// `Yes`
  String get yes {
    return Intl.message(
      'Yes',
      name: 'yes',
      desc: 'Affirmative button label',
      args: [],
    );
  }

  /// `No`
  String get no {
    return Intl.message(
      'No',
      name: 'no',
      desc: 'Negative button label',
      args: [],
    );
  }

  /// `New journal entry`
  String get newJournalEntry {
    return Intl.message(
      'New journal entry',
      name: 'newJournalEntry',
      desc: 'New journal entry screen title and button hint',
      args: [],
    );
  }

  /// `Sort by Last Modified Time`
  String get sortByLastModified {
    return Intl.message(
      'Sort by Last Modified Time',
      name: 'sortByLastModified',
      desc: 'Menu option to sort by last modified date',
      args: [],
    );
  }

  /// `Sort by Title`
  String get sortByTitle {
    return Intl.message(
      'Sort by Title',
      name: 'sortByTitle',
      desc: 'Menu option to sort by title text',
      args: [],
    );
  }

  /// `Find journal entries`
  String get findJournalEntries {
    return Intl.message(
      'Find journal entries',
      name: 'findJournalEntries',
      desc: 'Field journal search bar hint',
      args: [],
    );
  }

  /// `No journal entries found`
  String get noJournalEntriesFound {
    return Intl.message(
      'No journal entries found',
      name: 'noJournalEntriesFound',
      desc: 'Text displayed when the field journal list is empty',
      args: [],
    );
  }

  /// `Title`
  String get title {
    return Intl.message(
      'Title',
      name: 'title',
      desc: 'Title field label',
      args: [],
    );
  }

  /// `Insert a title for the journal entry`
  String get insertTitle {
    return Intl.message(
      'Insert a title for the journal entry',
      name: 'insertTitle',
      desc: 'Validation message for title field',
      args: [],
    );
  }

  /// `Error saving the field journal entry`
  String get errorSavingJournalEntry {
    return Intl.message(
      'Error saving the field journal entry',
      name: 'errorSavingJournalEntry',
      desc: 'Message shown when an error occurred while saving a journal entry',
      args: [],
    );
  }

  /// `Delete journal entry`
  String get deleteJournalEntry {
    return Intl.message(
      'Delete journal entry',
      name: 'deleteJournalEntry',
      desc: 'Menu option to delete a field journal entry',
      args: [],
    );
  }

  /// `Edit journal entry`
  String get editJournalEntry {
    return Intl.message(
      'Edit journal entry',
      name: 'editJournalEntry',
      desc: 'Menu option to edit a field journal entry',
      args: [],
    );
  }

  /// `Statistics`
  String get statistics {
    return Intl.message(
      'Statistics',
      name: 'statistics',
      desc: 'Title for statistics screen and labels',
      args: [],
    );
  }

  /// `Select a species to show the statistics`
  String get selectSpeciesToShowStats {
    return Intl.message(
      'Select a species to show the statistics',
      name: 'selectSpeciesToShowStats',
      desc: 'Message shown when no species is selected in statistics',
      args: [],
    );
  }

  /// `Per species`
  String get perSpecies {
    return Intl.message(
      'Per species',
      name: 'perSpecies',
      desc: 'Per species section title in statistics',
      args: [],
    );
  }

  /// `Total of records`
  String get totalRecords {
    return Intl.message(
      'Total of records',
      name: 'totalRecords',
      desc: 'Total of records card title in statistics',
      args: [],
    );
  }

  /// `Records per month`
  String get recordsPerMonth {
    return Intl.message(
      'Records per month',
      name: 'recordsPerMonth',
      desc: 'Records per month card title in statistics',
      args: [],
    );
  }

  /// `Records per year`
  String get recordsPerYear {
    return Intl.message(
      'Records per year',
      name: 'recordsPerYear',
      desc: 'Records per year card title in statistics',
      args: [],
    );
  }

  /// `Add coordinates`
  String get addCoordinates {
    return Intl.message(
      'Add coordinates',
      name: 'addCoordinates',
      desc: 'Add coordinates button hint',
      args: [],
    );
  }

  /// `recorded species`
  String get recordedSpecies {
    return Intl.message(
      'recorded species',
      name: 'recordedSpecies',
      desc: 'Recorded species card title in statistics',
      args: [],
    );
  }

  /// `Top 10 most recorded species`
  String get topTenSpecies {
    return Intl.message(
      'Top 10 most recorded species',
      name: 'topTenSpecies',
      desc: 'Top 10 most recorded species card title in statistics',
      args: [],
    );
  }

  /// `survey hours`
  String get surveyHours {
    return Intl.message(
      'survey hours',
      name: 'surveyHours',
      desc: 'Survey hours card title in statistics',
      args: [],
    );
  }

  /// `survey hours per inventory`
  String get averageSurveyHours {
    return Intl.message(
      'survey hours per inventory',
      name: 'averageSurveyHours',
      desc: 'Average survey hours card title in statistics',
      args: [],
    );
  }

  /// `Pending`
  String get pending {
    return Intl.message(
      'Pending',
      name: 'pending',
      desc: 'Pending segmented button label in specimens',
      args: [],
    );
  }

  /// `Archived`
  String get archived {
    return Intl.message(
      'Archived',
      name: 'archived',
      desc: 'Archived segmented button label in specimens',
      args: [],
    );
  }

  /// `Archive specimen`
  String get archiveSpecimen {
    return Intl.message(
      'Archive specimen',
      name: 'archiveSpecimen',
      desc: 'Menu option to archive a specimen',
      args: [],
    );
  }

  /// `Male name or ID`
  String get maleNameOrId {
    return Intl.message(
      'Male name or ID',
      name: 'maleNameOrId',
      desc: 'Male name or ID field hint',
      args: [],
    );
  }

  /// `Female name or ID`
  String get femaleNameOrId {
    return Intl.message(
      'Female name or ID',
      name: 'femaleNameOrId',
      desc: 'Female name or ID field hint',
      args: [],
    );
  }

  /// `Helpers names or IDs`
  String get helpersNamesOrIds {
    return Intl.message(
      'Helpers names or IDs',
      name: 'helpersNamesOrIds',
      desc: 'Helpers names or IDs field hint',
      args: [],
    );
  }

  /// `Plant species or support type`
  String get plantSpeciesOrSupportType {
    return Intl.message(
      'Plant species or support type',
      name: 'plantSpeciesOrSupportType',
      desc: 'Plant species or support type field hint',
      args: [],
    );
  }

  /// `Uncheck this to format numbers with point as decimal separator`
  String get formatNumbersDescription {
    return Intl.message(
      'Uncheck this to format numbers with point as decimal separator',
      name: 'formatNumbersDescription',
      desc: 'Description of the format numbers option in settings',
      args: [],
    );
  }

  /// `Select all`
  String get selectAll {
    return Intl.message(
      'Select all',
      name: 'selectAll',
      desc: 'Select all menu and button label',
      args: [],
    );
  }

  /// `Exporting...`
  String get exporting {
    return Intl.message(
      'Exporting...',
      name: 'exporting',
      desc: 'Message shown when exporting data',
      args: [],
    );
  }

  /// `No data to export.`
  String get noDataToExport {
    return Intl.message(
      'No data to export.',
      name: 'noDataToExport',
      desc: 'Message shown when there is no data to export',
      args: [],
    );
  }

  /// `Exporting, please wait...`
  String get exportingPleaseWait {
    return Intl.message(
      'Exporting, please wait...',
      name: 'exportingPleaseWait',
      desc: 'Message shown when exporting data',
      args: [],
    );
  }

  /// `Error`
  String get errorTitle {
    return Intl.message(
      'Error',
      name: 'errorTitle',
      desc: 'Error title',
      args: [],
    );
  }

  /// `Warning`
  String get warningTitle {
    return Intl.message(
      'Warning',
      name: 'warningTitle',
      desc: 'Warning title',
      args: [],
    );
  }

  /// `Remind missing vegetation data`
  String get remindMissingVegetationData {
    return Intl.message(
      'Remind missing vegetation data',
      name: 'remindMissingVegetationData',
      desc: 'Settings option to remind missing vegetation data',
      args: [],
    );
  }

  /// `Remind missing weather data`
  String get remindMissingWeatherData {
    return Intl.message(
      'Remind missing weather data',
      name: 'remindMissingWeatherData',
      desc: 'Settings option to remind missing weather data',
      args: [],
    );
  }

  /// `There is no vegetation data.`
  String get missingVegetationData {
    return Intl.message(
      'There is no vegetation data.',
      name: 'missingVegetationData',
      desc: 'Message shown when there is no vegetation data',
      args: [],
    );
  }

  /// `There is no weather data.`
  String get missingWeatherData {
    return Intl.message(
      'There is no weather data.',
      name: 'missingWeatherData',
      desc: 'Message shown when there is no weather data',
      args: [],
    );
  }

  /// `Add`
  String get addButton {
    return Intl.message(
      'Add',
      name: 'addButton',
      desc: 'Add button label',
      args: [],
    );
  }

  /// `Ignore`
  String get ignoreButton {
    return Intl.message(
      'Ignore',
      name: 'ignoreButton',
      desc: 'Ignore button label',
      args: [],
    );
  }

  /// `Observer abbreviation is missing. Please add it in the settings.`
  String get observerAbbreviationMissing {
    return Intl.message(
      'Observer abbreviation is missing. Please add it in the settings.',
      name: 'observerAbbreviationMissing',
      desc: 'Message shown when the observer abbreviation is missing',
      args: [],
    );
  }

  /// `Invalid numeric value`
  String get invalidNumericValue {
    return Intl.message(
      'Invalid numeric value',
      name: 'invalidNumericValue',
      desc: 'Message shown when the value is not a number',
      args: [],
    );
  }

  /// `There are no revisions for this nest. Add at least one revision.`
  String get nestRevisionsMissing {
    return Intl.message(
      'There are no revisions for this nest. Add at least one revision.',
      name: 'nestRevisionsMissing',
      desc: 'Message shown when there are no revisions for a nest',
      args: [],
    );
  }

  /// `Edit locality`
  String get editLocality {
    return Intl.message(
      'Edit locality',
      name: 'editLocality',
      desc: 'Dialog title to edit a locality',
      args: [],
    );
  }

  /// `Add/edit notes`
  String get addEditNotes {
    return Intl.message(
      'Add/edit notes',
      name: 'addEditNotes',
      desc: 'Dialog title and menu option to add/edit notes',
      args: [],
    );
  }

  /// `Export KML`
  String get exportKml {
    return Intl.message(
      'Export KML',
      name: 'exportKml',
      desc: 'Menu option to export to KML',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
      desc: 'Edit button label',
      args: [],
    );
  }

  /// `No POIs to export.`
  String get noPoisToExport {
    return Intl.message(
      'No POIs to export.',
      name: 'noPoisToExport',
      desc: 'Message shown when there are no POIs to export',
      args: [],
    );
  }

  /// `Species within sample`
  String get totalSpeciesWithinSample {
    return Intl.message(
      'Species within sample',
      name: 'totalSpeciesWithinSample',
      desc: 'Total species within sample card title in statistics',
      args: [],
    );
  }

  /// `Details`
  String get details {
    return Intl.message(
      'Details',
      name: 'details',
      desc: 'Details button label',
      args: [],
    );
  }

  /// `Inventory details`
  String get editInventoryDetails {
    return Intl.message(
      'Inventory details',
      name: 'editInventoryDetails',
      desc: 'Menu option to edit inventory details',
      args: [],
    );
  }

  /// `Discarded inventory`
  String get discardedInventory {
    return Intl.message(
      'Discarded inventory',
      name: 'discardedInventory',
      desc: 'Menu option to discard an inventory',
      args: [],
    );
  }

  /// `Format error importing inventory: {errorMessage}`
  String errorImportingInventoryWithFormatError(String errorMessage) {
    return Intl.message(
      'Format error importing inventory: $errorMessage',
      name: 'errorImportingInventoryWithFormatError',
      desc: 'Error message when importing inventories with a format error',
      args: [errorMessage],
    );
  }

  /// `Inventories imported successfully: {howMany}`
  String inventoriesImportedSuccessfully(int howMany) {
    return Intl.message(
      'Inventories imported successfully: $howMany',
      name: 'inventoriesImportedSuccessfully',
      desc: 'Message when inventories are imported successfully',
      args: [howMany],
    );
  }

  /// `Import completed with errors: {successfullyImportedCount} successful, {importErrorsCount} errors`
  String importCompletedWithErrors(
    int successfullyImportedCount,
    int importErrorsCount,
  ) {
    return Intl.message(
      'Import completed with errors: $successfullyImportedCount successful, $importErrorsCount errors',
      name: 'importCompletedWithErrors',
      desc: 'Message when import is completed with errors',
      args: [successfullyImportedCount, importErrorsCount],
    );
  }

  /// `Failed to import inventory with ID: {id}`
  String failedToImportInventoryWithId(String id) {
    return Intl.message(
      'Failed to import inventory with ID: $id',
      name: 'failedToImportInventoryWithId',
      desc: 'Message when failed to import an inventory',
      args: [id],
    );
  }

  /// `Invalid JSON format. Expected an object or an array.`
  String get invalidJsonFormatExpectedObjectOrArray {
    return Intl.message(
      'Invalid JSON format. Expected an object or an array.',
      name: 'invalidJsonFormatExpectedObjectOrArray',
      desc: 'Message when the JSON format is invalid',
      args: [],
    );
  }

  /// `Importing nests`
  String get importingNests {
    return Intl.message(
      'Importing nests',
      name: 'importingNests',
      desc: 'Message when importing nests',
      args: [],
    );
  }

  /// `Error importing nests`
  String get errorImportingNests {
    return Intl.message(
      'Error importing nests',
      name: 'errorImportingNests',
      desc: 'Error message when importing nests',
      args: [],
    );
  }

  /// `Format error importing nest: {errorMessage}`
  String errorImportingNestsWithFormatError(String errorMessage) {
    return Intl.message(
      'Format error importing nest: $errorMessage',
      name: 'errorImportingNestsWithFormatError',
      desc: 'Error message when importing nests with a format error',
      args: [errorMessage],
    );
  }

  /// `Nests imported successfully: {howMany}`
  String nestsImportedSuccessfully(int howMany) {
    return Intl.message(
      'Nests imported successfully: $howMany',
      name: 'nestsImportedSuccessfully',
      desc: 'Message when nests are imported successfully',
      args: [howMany],
    );
  }

  /// `Failed to import nest with ID: {id}`
  String failedToImportNestWithId(int id) {
    return Intl.message(
      'Failed to import nest with ID: $id',
      name: 'failedToImportNestWithId',
      desc: 'Message when failed to import a nest',
      args: [id],
    );
  }

  /// `Backup`
  String get backup {
    return Intl.message(
      'Backup',
      name: 'backup',
      desc: 'Settings backup section title',
      args: [],
    );
  }

  /// `Create backup`
  String get createBackup {
    return Intl.message(
      'Create backup',
      name: 'createBackup',
      desc: 'Create backup settings tile title',
      args: [],
    );
  }

  /// `Send backup to...`
  String get sendBackupTo {
    return Intl.message(
      'Send backup to...',
      name: 'sendBackupTo',
      desc: 'Share backup title',
      args: [],
    );
  }

  /// `Backup created and shared successfully`
  String get backupCreatedAndSharedSuccessfully {
    return Intl.message(
      'Backup created and shared successfully',
      name: 'backupCreatedAndSharedSuccessfully',
      desc: 'Message when backup is created and shared successfully',
      args: [],
    );
  }

  /// `Error creating backup`
  String get errorCreatingBackup {
    return Intl.message(
      'Error creating backup',
      name: 'errorCreatingBackup',
      desc: 'Error message when creating backup',
      args: [],
    );
  }

  /// `Backup not found`
  String get errorBackupNotFound {
    return Intl.message(
      'Backup not found',
      name: 'errorBackupNotFound',
      desc: 'Error message when backup is not found',
      args: [],
    );
  }

  /// `Restore backup`
  String get restoreBackup {
    return Intl.message(
      'Restore backup',
      name: 'restoreBackup',
      desc: 'Restore backup settings tile title',
      args: [],
    );
  }

  /// `Backup restored successfully! Restart the app to apply the changes.`
  String get backupRestoredSuccessfully {
    return Intl.message(
      'Backup restored successfully! Restart the app to apply the changes.',
      name: 'backupRestoredSuccessfully',
      desc: 'Message when backup is restored successfully',
      args: [],
    );
  }

  /// `Error restoring backup`
  String get errorRestoringBackup {
    return Intl.message(
      'Error restoring backup',
      name: 'errorRestoringBackup',
      desc: 'Error message when restoring backup',
      args: [],
    );
  }

  /// `Backing up data`
  String get backingUpData {
    return Intl.message(
      'Backing up data',
      name: 'backingUpData',
      desc: 'Message when backing up data',
      args: [],
    );
  }

  /// `Restoring data`
  String get restoringData {
    return Intl.message(
      'Restoring data',
      name: 'restoringData',
      desc: 'Message when restoring data',
      args: [],
    );
  }

  /// `Importing specimens`
  String get importingSpecimens {
    return Intl.message(
      'Importing specimens',
      name: 'importingSpecimens',
      desc: 'Message when importing specimens',
      args: [],
    );
  }

  /// `Error importing specimens`
  String get errorImportingSpecimens {
    return Intl.message(
      'Error importing specimens',
      name: 'errorImportingSpecimens',
      desc: 'Error message when importing specimens',
      args: [],
    );
  }

  /// `Format error importing specimen: {errorMessage}`
  String errorImportingSpecimensWithFormatError(String errorMessage) {
    return Intl.message(
      'Format error importing specimen: $errorMessage',
      name: 'errorImportingSpecimensWithFormatError',
      desc: 'Error message when importing specimens with a format error',
      args: [errorMessage],
    );
  }

  /// `Specimens imported successfully: {howMany}`
  String specimensImportedSuccessfully(int howMany) {
    return Intl.message(
      'Specimens imported successfully: $howMany',
      name: 'specimensImportedSuccessfully',
      desc: 'Message when specimens are imported successfully',
      args: [howMany],
    );
  }

  /// `Failed to import specimen with ID: {id}`
  String failedToImportSpecimenWithId(int id) {
    return Intl.message(
      'Failed to import specimen with ID: $id',
      name: 'failedToImportSpecimenWithId',
      desc: 'Message when failed to import a specimen',
      args: [id],
    );
  }

  /// `Cloud cover must be between 0 and 100`
  String get cloudCoverRangeError {
    return Intl.message(
      'Cloud cover must be between 0 and 100',
      name: 'cloudCoverRangeError',
      desc: 'Error message when cloud cover is out of range',
      args: [],
    );
  }

  /// `Relative humidity must be between 0 and 100`
  String get relativeHumidityRangeError {
    return Intl.message(
      'Relative humidity must be between 0 and 100',
      name: 'relativeHumidityRangeError',
      desc: 'Error message when relative humidity is out of range',
      args: [],
    );
  }

  /// `Atmospheric pressure`
  String get atmosphericPressure {
    return Intl.message(
      'Atmospheric pressure',
      name: 'atmosphericPressure',
      desc: 'Atmospheric pressure field label',
      args: [],
    );
  }

  /// `Relative humidity`
  String get relativeHumidity {
    return Intl.message(
      'Relative humidity',
      name: 'relativeHumidity',
      desc: 'Relative humidity field label',
      args: [],
    );
  }

  /// `Total of observers`
  String get totalOfObservers {
    return Intl.message(
      'Total of observers',
      name: 'totalOfObservers',
      desc: 'Total of observers field label',
      args: [],
    );
  }

  /// `Enter coordinates`
  String get enterCoordinates {
    return Intl.message(
      'Enter coordinates',
      name: 'enterCoordinates',
      desc: 'Enter coordinates dialog title',
      args: [],
    );
  }

  /// `Latitude`
  String get latitude {
    return Intl.message(
      'Latitude',
      name: 'latitude',
      desc: 'Latitude field label',
      args: [],
    );
  }

  /// `Longitude`
  String get longitude {
    return Intl.message(
      'Longitude',
      name: 'longitude',
      desc: 'Longitude field label',
      args: [],
    );
  }

  /// `Invalid latitude`
  String get invalidLatitude {
    return Intl.message(
      'Invalid latitude',
      name: 'invalidLatitude',
      desc: 'Error message when the latitude is invalid',
      args: [],
    );
  }

  /// `Invalid longitude`
  String get invalidLongitude {
    return Intl.message(
      'Invalid longitude',
      name: 'invalidLongitude',
      desc: 'Error message when the longitude is invalid',
      args: [],
    );
  }

  /// `Field cannot be empty`
  String get fieldCannotBeEmpty {
    return Intl.message(
      'Field cannot be empty',
      name: 'fieldCannotBeEmpty',
      desc: 'Error message when a field is empty',
      args: [],
    );
  }

  /// `Location error`
  String get locationError {
    return Intl.message(
      'Location error',
      name: 'locationError',
      desc: 'Location error dialog title',
      args: [],
    );
  }

  /// `Could not get GPS location`
  String get couldNotGetGpsLocation {
    return Intl.message(
      'Could not get GPS location',
      name: 'couldNotGetGpsLocation',
      desc: 'Location error dialog message',
      args: [],
    );
  }

  /// `Continue without`
  String get continueWithout {
    return Intl.message(
      'Continue without',
      name: 'continueWithout',
      desc: 'Continue without button label',
      args: [],
    );
  }

  /// `Enter manually`
  String get enterManually {
    return Intl.message(
      'Enter manually',
      name: 'enterManually',
      desc: 'Enter manually button label',
      args: [],
    );
  }

  /// `Distance`
  String get distance {
    return Intl.message(
      'Distance',
      name: 'distance',
      desc: 'Distance field label',
      args: [],
    );
  }

  /// `Flight height`
  String get flightHeight {
    return Intl.message(
      'Flight height',
      name: 'flightHeight',
      desc: 'Flight height field label',
      args: [],
    );
  }

  /// `Flight direction`
  String get flightDirection {
    return Intl.message(
      'Flight direction',
      name: 'flightDirection',
      desc: 'Flight direction field label',
      args: [],
    );
  }

  /// `Insert count`
  String get insertCount {
    return Intl.message(
      'Insert count',
      name: 'insertCount',
      desc: 'Insert count field label',
      args: [],
    );
  }

  /// `Insert a valid number`
  String get insertValidNumber {
    return Intl.message(
      'Insert a valid number',
      name: 'insertValidNumber',
      desc: 'Validation message for insert count field',
      args: [],
    );
  }

  /// `Wind direction`
  String get windDirection {
    return Intl.message(
      'Wind direction',
      name: 'windDirection',
      desc: 'Wind direction field label',
      args: [],
    );
  }

  /// `None`
  String get precipitationNone {
    return Intl.message('None', name: 'precipitationNone', desc: '', args: []);
  }

  /// `Fog`
  String get precipitationFog {
    return Intl.message('Fog', name: 'precipitationFog', desc: '', args: []);
  }

  /// `Mist`
  String get precipitationMist {
    return Intl.message('Mist', name: 'precipitationMist', desc: '', args: []);
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
    return Intl.message('Rain', name: 'precipitationRain', desc: '', args: []);
  }

  /// `Showers`
  String get precipitationShowers {
    return Intl.message(
      'Showers',
      name: 'precipitationShowers',
      desc: '',
      args: [],
    );
  }

  /// `Snow`
  String get precipitationSnow {
    return Intl.message('Snow', name: 'precipitationSnow', desc: '', args: []);
  }

  /// `Hail`
  String get precipitationHail {
    return Intl.message('Hail', name: 'precipitationHail', desc: '', args: []);
  }

  /// `Frost`
  String get precipitationFrost {
    return Intl.message(
      'Frost',
      name: 'precipitationFrost',
      desc: '',
      args: [],
    );
  }

  /// `None`
  String get distributionNone {
    return Intl.message('None', name: 'distributionNone', desc: '', args: []);
  }

  /// `Rare`
  String get distributionRare {
    return Intl.message('Rare', name: 'distributionRare', desc: '', args: []);
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

  /// `Interval Qualitative List`
  String get inventoryIntervalQualitative {
    return Intl.message(
      'Interval Qualitative List',
      name: 'inventoryIntervalQualitative',
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

  /// `Transect Count`
  String get inventoryTransectCount {
    return Intl.message(
      'Transect Count',
      name: 'inventoryTransectCount',
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

  /// `Detection Transect Count`
  String get inventoryTransectDetection {
    return Intl.message(
      'Detection Transect Count',
      name: 'inventoryTransectDetection',
      desc: '',
      args: [],
    );
  }

  /// `Detection Point Count`
  String get inventoryPointDetection {
    return Intl.message(
      'Detection Point Count',
      name: 'inventoryPointDetection',
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
    return Intl.message('Oval', name: 'eggShapeOval', desc: '', args: []);
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
    return Intl.message('Conical', name: 'eggShapeConical', desc: '', args: []);
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
    return Intl.message('Laying', name: 'nestStageLaying', desc: '', args: []);
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
    return Intl.message('Active', name: 'nestStatusActive', desc: '', args: []);
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

  /// `Unknown`
  String get nestFateUnknown {
    return Intl.message('Unknown', name: 'nestFateUnknown', desc: '', args: []);
  }

  /// `Lost`
  String get nestFateLost {
    return Intl.message('Lost', name: 'nestFateLost', desc: '', args: []);
  }

  /// `Success`
  String get nestFateSuccess {
    return Intl.message('Success', name: 'nestFateSuccess', desc: '', args: []);
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
    return Intl.message('Nest', name: 'specimenNest', desc: '', args: []);
  }

  /// `Bones`
  String get specimenBones {
    return Intl.message('Bones', name: 'specimenBones', desc: '', args: []);
  }

  /// `Egg`
  String get specimenEgg {
    return Intl.message('Egg', name: 'specimenEgg', desc: '', args: []);
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
    return Intl.message('Blood', name: 'specimenBlood', desc: '', args: []);
  }

  /// `Claw`
  String get specimenClaw {
    return Intl.message('Claw', name: 'specimenClaw', desc: '', args: []);
  }

  /// `Swab`
  String get specimenSwab {
    return Intl.message('Swab', name: 'specimenSwab', desc: '', args: []);
  }

  /// `Tissues`
  String get specimenTissues {
    return Intl.message('Tissues', name: 'specimenTissues', desc: '', args: []);
  }

  /// `Feces`
  String get specimenFeces {
    return Intl.message('Feces', name: 'specimenFeces', desc: '', args: []);
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
      Locale.fromSubtags(languageCode: 'pt'),
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
