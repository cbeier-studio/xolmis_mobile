
enum SortOrder {
  ascending,
  descending,
}

enum InventorySortField {
  id,
  startTime,
  endTime,
  locality,
  inventoryType,
}

enum NestSortField {
  fieldNumber,
  foundTime,
  lastTime,
  species,
  locality,
  nestFate,
}

enum SpecimenSortField {
  fieldNumber,
  sampleTime,
  species,
  locality,
  specimenType,
}

enum JournalSortField {
  title,
  creationDate,
  lastModifiedDate,
}

enum SpeciesSortField {
  name,
  time,
  // type,
}

// Enum for warning dialog actions
enum ConditionalAction { add, ignore, cancelDialog }