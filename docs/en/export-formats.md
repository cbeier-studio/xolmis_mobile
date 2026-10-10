# Export File Formats

Xolmis Mobile allows you to export your data across modules—**Inventories**, **Nests**, **Specimens**, and **Field Journal**—as well as generate full **Database Backups**. This guide provides a comprehensive specification of every supported export format, how files are generated, and detailed column descriptions for tabular datasets.

## Overview & File Generation Rules

Depending on the chosen export format, an export operation may produce **a single file** or **multiple files**:

| Module / Action | Format | Number of Files Generated | Details                                                                                                                                                      |
| :--- | :--- |:--------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Inventories** | **CSV** | Up to **4 files**         | Generates separate files: `..._species.csv`, `..._pois.csv` (if data exists), `..._vegetation.csv` (if data exists), and `..._weather.csv` (if data exists). |
| | **Excel** | **1 file**                | Generates a single `.xlsx` workbook containing up to 5 worksheets: `Occurrences`, `Vegetation`, `Weather`, `POIs`, and `Events`.                             |
| | **JSON** | **1 file**                | Single `.json` file wrapped in a standardized envelope.                                                                                                      |
| | **KML** | **1 file**                | Single `.kml` spatial file with start/end coordinates and species POIs.                                                                                      |
| **Nests** | **CSV** | Up to **2 files**         | Generates separate files: `..._revisions.csv` and `..._eggs.csv` (if egg measurements exist).                                                                |
| | **Excel** | **1 file**                | Generates a single `.xlsx` workbook containing up to 3 worksheets: `Revisions`, `Nests` (summary), and `Eggs`.                                               |
| | **JSON** | **1 file**                | Single `.json` file wrapped in a standardized envelope.                                                                                                      |
| | **KML** | **1 file**                | Single `.kml` spatial file containing nest locations.                                                                                                        |
| **Specimens** | **CSV** | **1 file**                | Generates `..._specimens.csv`.                                                                                                                               |
| | **Excel** | **1 file**                | Generates a single `.xlsx` workbook with a `Specimens` worksheet.                                                                                            |
| | **JSON** | **1 file**                | Single `.json` file wrapped in a standardized envelope.                                                                                                      |
| | **KML** | **1 file**                | Single `.kml` spatial file containing specimen collection locations.                                                                                         |
| **Field Journal** | **Plain Text** | **1 file**                | Single `.txt` file formatted with text entries.                                                                                                              |
| | **Markdown** | **1 file**                | Single `.md` file formatted with headers and metadata.                                                                                                       |
| | **Word** | **1 file**                | Single `.docx` Word document with styled headings and paragraphs.                                                                                            |
| | **JSON** | **1 file**                | Single `.json` file containing rich-text Delta JSON strings wrapped in the envelope.                                                                         |
| **Backup** | **ZIP** | **1 file**                | Archive containing `xolmis_database.db` and all indexed photo media files.                                                                                   |

!!! note

    **CSV vs. Excel Column Parity**: CSV files and Excel workbooks share the exact same column structures. In CSV exports, each data category is generated as an independent CSV file (delimited by semicolons `;` or commas depending on settings). In Excel exports, those same data categories are combined as separate worksheet tabs within a single `.xlsx` workbook file.

## Tabular Datasets (CSV & Excel Columns)

All tabular exports in Xolmis Mobile align with **Darwin Core (DwC)** standards where applicable to facilitate integration with biodiversity data platforms (e.g., GBIF, Xolmis Desktop).

### 1. Inventories Module

#### Occurrences Table (`..._species.csv` / Excel tab: `Occurrences`)

Contains individual species records and observation parameters collected during inventory sessions.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `eventID` | String | Unique identifier of the inventory session (e.g., `CRS-20260330-001`). |
| `samplingProtocol` | String | Inventory methodology (e.g., *Point Count*, *Transect*, *Mackinnon List*, *Casual*). |
| `samplingEffort` | Integer | Planned duration or effort in minutes. |
| `eventDate` | String | Start date (`YYYY-MM-DD`). |
| `eventTime` | String | Start time (`HH:MM:SS`). |
| `eventEndDate` | String | End date (`YYYY-MM-DD`). |
| `eventEndTime` | String | End time (`HH:MM:SS`). |
| `locality` | String | Locality or study site name. |
| `decimalLongitude` | Double | Inventory starting longitude (decimal degrees). |
| `decimalLatitude` | Double | Inventory starting latitude (decimal degrees). |
| `endLongitude` | Double | Inventory ending longitude (decimal degrees). |
| `endLatitude` | Double | Inventory ending latitude (decimal degrees). |
| `recordedBy` | String | Observer initials or name. |
| `totalObservers` | Integer | Total number of observers in the team. |
| `samplingIntervals` | Integer | Active sampling interval or total intervals configured. |
| `pausedTimeSeconds` | Integer | Total paused time accumulated during the inventory session (in seconds). |
| `eventRemarks` | String | General inventory session notes. |
| `isDiscarded` | String | Indicates if the inventory session was marked as discarded (`Yes`/`No`). |
| `scientificName` | String | Scientific name of the observed species. |
| `individualCount` | Integer | Number of individuals observed. |
| `occurrenceTime` | String | Timestamp when the species occurrence was recorded (`HH:MM:SS` or `YYYY-MM-DD HH:MM:SS`). |
| `isOutOfSample` | String | Flag indicating if observation occurred outside protocol duration (`Yes`/`No`). |
| `distance` | String | Distance category or measured distance to the individual. |
| `flightHeight` | String | Flight height category or height estimate. |
| `flightDirection` | String | Flight direction / movement direction. |
| `habitats` | String | List of habitat categories assigned to the species record (multi-select; values separated by `;`). |
| `detectionModes` | String | List of detection modes used for the record (for example visual, auditory, capture; values separated by `;`). |
| `reproductiveStatus` | String | Optional reproductive status compatible with eBird breeding evidence (*Possible Breeding*, *Probable Breeding*, *Confirmed Breeding*). |
| `sex` | String | Reported sex for the record (*Indeterminate*, *Male*, *Female*, *Both*). |
| `activities` | String | List of observed activities/behaviors at the moment of record (values separated by `;`). |
| `occurrenceRemarks` | String | Remarks or notes specific to this species record. |

#### Vegetation Table (`..._vegetation.csv` / Excel tab: `Vegetation`)

Contains habitat and vegetation structure measurements associated with inventory sessions.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `eventID` | String | Inventory session identifier. |
| `samplingProtocol` | String | Inventory methodology. |
| `samplingEffort` | Integer | Planned duration in minutes. |
| `eventDate` | String | Inventory start date (`YYYY-MM-DD`). |
| `eventTime` | String | Inventory start time (`HH:MM:SS`). |
| `locality` | String | Locality name. |
| `decimalLongitude` | Double | Inventory start longitude. |
| `decimalLatitude` | Double | Inventory start latitude. |
| `recordedBy` | String | Observer initials. |
| `eventRemarks` | String | General inventory remarks. |
| `measurementDate` | String | Measurement timestamp (`YYYY-MM-DD HH:MM:SS`). |
| `measurementLatitude` | Double | Latitude where vegetation sample was taken. |
| `measurementLongitude` | Double | Longitude where vegetation sample was taken. |
| `herbsProportion` | Double/Int | Herbaceous layer coverage percentage (0–100%). |
| `herbsDistribution` | String | Spatial distribution pattern of herbs (*Continuous*, *Clumped*, *Sparse*). |
| `herbsHeight` | Double | Average/maximum height of herbaceous layer. |
| `shrubsProportion` | Double/Int | Shrub layer coverage percentage (0–100%). |
| `shrubsDistribution` | String | Spatial distribution pattern of shrubs. |
| `shrubsHeight` | Double | Average/maximum height of shrub layer. |
| `treesProportion` | Double/Int | Tree/canopy layer coverage percentage (0–100%). |
| `treesDistribution` | String | Spatial distribution pattern of trees. |
| `treesHeight` | Double | Average/maximum height of tree layer. |
| `measurementRemarks` | String | Remarks specific to vegetation structure measurement. |

#### Weather Table (`..._weather.csv` / Excel tab: `Weather`)

Contains atmospheric and weather condition samples recorded during inventories.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `eventID` | String | Inventory session identifier. |
| `samplingProtocol` | String | Inventory methodology. |
| `samplingEffort` | Integer | Planned duration in minutes. |
| `eventDate` | String | Inventory start date (`YYYY-MM-DD`). |
| `eventTime` | String | Inventory start time (`HH:MM:SS`). |
| `locality` | String | Locality name. |
| `decimalLongitude` | Double | Inventory start longitude. |
| `decimalLatitude` | Double | Inventory start latitude. |
| `recordedBy` | String | Observer initials. |
| `eventRemarks` | String | General inventory remarks. |
| `measurementDate` | String | Weather measurement timestamp (`YYYY-MM-DD HH:MM:SS`). |
| `cloudCover` | String/Int | Cloud cover percentage or category. |
| `precipitation` | String | Precipitation status or category (*None*, *Light Rain*, *Heavy Rain*, etc.). |
| `temperature` | Double | Ambient temperature (°C). |
| `windSpeed` | String/Double | Wind speed value or Beaufort scale category. |
| `windDirection` | String | Wind direction (e.g., *N*, *NE*, *350°*). |
| `atmosphericPressure` | Double | Barometric pressure (hPa). |
| `relativeHumidity` | Double | Relative air humidity (%). |

#### Points of Interest Table (`..._pois.csv` / Excel tab: `POIs`)

Included in Excel workbooks to record individual GPS waypoints logged during species observations.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `eventID` | String | Inventory session identifier. |
| `samplingProtocol` | String | Inventory methodology. |
| `eventDate` | String | Inventory start date (`YYYY-MM-DD`). |
| `locality` | String | Locality name. |
| `recordedBy` | String | Observer initials. |
| `scientificName` | String | Scientific name of the species associated with the POI. |
| `poiDate` | String | Timestamp when the POI coordinate was captured (`YYYY-MM-DD HH:MM:SS`). |
| `decimalLatitude` | Double | Latitude of the point of interest. |
| `decimalLongitude` | Double | Longitude of the point of interest. |
| `poiRemarks` | String | Remarks or notes logged with the POI. |

#### Events Summary Table (Excel tab: `Events`)

Included in Excel workbooks to summarize session-level metadata for each inventory.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `eventID` | String | Unique inventory session identifier. |
| `samplingProtocol` | String | Inventory methodology. |
| `samplingEffort` | Integer | Planned duration in minutes. |
| `maxSpecies` | Integer | Target species list capacity (for Mackinnon lists). |
| `eventDate` | String | Start date (`YYYY-MM-DD`). |
| `eventTime` | String | Start time (`HH:MM:SS`). |
| `eventEndDate` | String | End date (`YYYY-MM-DD`). |
| `eventEndTime` | String | End time (`HH:MM:SS`). |
| `locality` | String | Locality name. |
| `decimalLongitude` | Double | Start longitude. |
| `decimalLatitude` | Double | Start latitude. |
| `endLongitude` | Double | End longitude. |
| `endLatitude` | Double | End latitude. |
| `totalObservers` | Integer | Total number of observers. |
| `recordedBy` | String | Primary observer initials. |
| `samplingIntervals` | Integer | Total intervals configured or executed. |
| `pausedTimeSeconds` | Integer | Total pause time accumulated in seconds. |
| `eventRemarks` | String | Inventory session remarks. |
| `isDiscarded` | String | Discard flag (`Yes`/`No`). |

### 2. Nests Module

#### Nests Summary Table (Excel tab: `Nests`)

Summary records for nests.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `occurrenceID` | String | Nest field number / code (e.g., `N-001`). |
| `scientificName` | String | Host bird species scientific name. |
| `locality` | String | Locality or study site name. |
| `decimalLongitude` | Double | Nest location longitude. |
| `decimalLatitude` | Double | Nest location latitude. |
| `verbatimEventDate` | String | Date/time nest was discovered (`YYYY-MM-DD HH:MM:SS`). |
| `support` | String | Substrate, support plant species, or structure holding the nest. |
| `heightAboveGround` | Double | Height above ground level in meters. |
| `male` | String | Male parent status, ring code, or observations. |
| `female` | String | Female parent status, ring code, or observations. |
| `helpers` | String | Nest helper observations or details. |
| `lastEventDate` | String | Timestamp of latest revision visit (`YYYY-MM-DD HH:MM:SS`). |
| `recordedBy` | String | Primary observer initials. |
| `nestFate` | String | Final outcome / fate of the nest (*Active*, *Successful*, *Predated*, *Abandoned*, *Discarded*). |

#### Revisions Table (`..._revisions.csv` / Excel tab: `Revisions`)

Detailed monitoring inspections recorded during nest visits.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `occurrenceID` | String | Nest field number. |
| `scientificName` | String | Host species scientific name. |
| `locality` | String | Locality name. |
| `decimalLongitude` | Double | Longitude. |
| `decimalLatitude` | Double | Latitude. |
| `recordedBy` | String | Observer initials. |
| `eventTime` | String | Revision inspection timestamp (`YYYY-MM-DD HH:MM:SS`). |
| `nestStatus` | String | Physical condition of nest structure (*Construction*, *Intact*, *Damaged*, *Destroyed*). |
| `nestStage` | String | Nesting stage (*Building*, *Egg-laying*, *Incubation*, *Nestling*, *Empty*). |
| `eggsHost` | Integer | Count of host species eggs. |
| `nestlingsHost` | Integer | Count of host species nestlings. |
| `eggsParasite` | Integer | Count of brood parasite eggs (e.g., Shiny Cowbird). |
| `nestlingsParasite` | Integer | Count of brood parasite nestlings. |
| `hasPhilornisLarvae` | String | Presence of subcutaneous botfly larvae (*Philornis* spp.) (`Yes`/`No`). |
| `revisionRemarks` | String | Remarks or observations recorded during this revision. |

#### Eggs Table (`..._eggs.csv` / Excel tab: `Eggs`)

Biometric measurements of individual eggs in a nest.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `occurrenceID` | String | Nest field number. |
| `scientificName` | String | Host species scientific name. |
| `locality` | String | Locality name. |
| `eventTime` | String | Timestamp when egg measurement was taken (`YYYY-MM-DD HH:MM:SS`). |
| `eggFieldNumber` | String | Egg code / identification within the clutch. |
| `eggSpeciesName` | String | Species name associated with the egg (host or parasite species). |
| `eggShape` | String | Egg shape classification (*Oval*, *Elliptical*, *Subelliptical*, *Pyriform*). |
| `width` | Double | Egg width in millimeters. |
| `length` | Double | Egg length in millimeters. |
| `mass` | Double | Egg mass in grams. |

### 3. Specimens Module

#### Specimens Table (`..._specimens.csv` / Excel tab: `Specimens`)

Contains records of collected biological samples, vouchers, blood samples, or physical evidence.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `verbatimEventDate` | String | Date/time specimen was recorded (`YYYY-MM-DD HH:MM:SS`). |
| `occurrenceID` | String | Specimen field number / catalog number (e.g., `SPEC-001`). |
| `recordedBy` | String | Collector or observer initials. |
| `scientificName` | String | Species scientific name. |
| `basisOfRecord` | String | Record type (*Physical Specimen*, *Blood Sample*, *Feather*, *Photo*, *Audio Recording*). |
| `locality` | String | Locality or collecting site. |
| `decimalLongitude` | Double | Longitude where specimen was obtained. |
| `decimalLatitude` | Double | Latitude where specimen was obtained. |
| `occurrenceRemarks` | String | Specimen notes, tissue preserved, storage location, or comments. |

## JSON Format & Schema Envelope

JSON exports serve as the primary format for transferring data between devices running Xolmis Mobile or integrating with **Xolmis Desktop**.

Every JSON export file contains a standardized metadata envelope:

```json
{
  "source": "Xolmis Mobile",
  "schema": "inventories",
  "schemaVersion": "1",
  "records": [
    { ... }
  ]
}
```

### JSON Envelope Fields

- `source`: Always set to `"Xolmis Mobile"`.
- `schema`: Identifies the dataset type (`"inventories"`, `"nests"`, `"specimens"`, `"journals"`).
- `schemaVersion`: Schema version number (currently `"1"`).
- `records`: JSON array containing complete object graphs (including nested children such as species lists, POIs, vegetation samples, weather samples, nest revisions, and egg measurements).

## Spatial KML Format

Exports to **KML (Keyhole Markup Language)** allow you to visualize geospatial records in Google Earth, GIS software, or web mapping tools.

### What is Included in KML Files?

- **Inventories**:
  - Start point waypoint (`<Placemark>`)
  - End point waypoint (`<Placemark>`)
  - Individual species Point of Interest (POI) waypoints with timestamps and coordinates
- **Nests**:
  - Nest location waypoint containing nest field number, species, support, height, and fate.
- **Specimens**:
  - Specimen collection location waypoint containing specimen field number, basis of record, and remarks.

!!! note
    
    KML coordinates strictly use `longitude,latitude,altitude` order in accordance with standard OGC specifications.

## Field Journal Formats

The **Field Journal** module offers flexible export options suitable for reporting, publications, or note archiving:

- **Plain Text (`.txt`)**: Clean text output containing entry title, observer, creation/modification dates, tags, and unformatted note text.
- **Markdown (`.md`)**: Formatted Markdown document with heading levels (`# Title`), bold metadata lines, and styled body paragraphs.
- **Word (`.docx`)**: Fully styled Microsoft Word document with document headings, metadata sections, and formatted body text.
- **JSON (`.json`)**: Raw rich-text Delta JSON format enclosed in the standard `journals` JSON envelope.

## Full Database Backup (ZIP)

Database backup files are created via **Settings → Backup**.

### Structure of Backup Files (`.zip`)

- `xolmis_database.db`: Complete local SQLite database file containing all application records, settings, and tables.
- `[image_filename].jpg / .png`: All photo files referenced in the `images` table (attached to inventories, vegetation, nests, specimens, or field journal entries).

Restoring a backup automatically replaces the local SQLite database and restores all media files into the app's local documents folder.
