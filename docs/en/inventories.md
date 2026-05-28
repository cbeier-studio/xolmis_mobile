# Manage Inventories

The **Inventories** module is the core of Xolmis Mobile, allowing you to record species lists using different sampling methods. This section explains how to create, edit, finish, reactivate, delete, import, export, search, sort, and select inventories.

## Create an Inventory

1. Open **Inventories** from the main menu.  
2. Tap the **+** button in the lower-right corner.  
3. Choose the **inventory type** (qualitative, timed, interval, Mackinnon, transect, point count, etc.).  
4. Fill in the required fields:
   - **ID** (or generate automatically)
   - **Locality**
   - **Duration** (if applicable)
   - **Maximum species** (if applicable)
   - **Total observers**
5. Tap **Start Inventory**.

The inventory begins immediately and appears in the **Active** tab.

## Edit an Inventory

To edit an existing inventory:

1. Long-press the inventory in the list.  
2. Select **Edit**.  
3. Modify fields such as:
   - ID  
   - Locality  
   - Total observers  
   - Discarded status  

Edits are saved automatically when you confirm.

## Finish an Inventory

You can finish an inventory manually or let it finish automatically (depending on the method).

### Manual finish

1. Open the inventory.  
2. Tap the **Finish** (flag) icon.  
3. Confirm the action.

If vegetation or weather reminders are enabled, the app will prompt you to fill missing data.

### Automatic finish

Some methods end automatically:
- Timed lists (when the timer reaches zero)  
- Interval lists (after three empty intervals)  
- Point counts (after the defined duration)

## Reactivate an Inventory

Finished inventories can be reopened if needed.

1. Long-press a **finished** inventory.  
2. Select **Reactivate**.

The inventory returns to the **Active** tab and can be edited again.

## Delete an Inventory

You can delete a single inventory or multiple at once.

### Delete one

1. Long-press the inventory.  
2. Tap **Delete**.  
3. Confirm.

### Delete multiple

1. Tap the checkbox next to each inventory.  
2. Tap the **Delete** (trash) icon in the bottom bar.  
3. Confirm.

Deleting an inventory removes all associated species, POIs, vegetation, and weather data.

## Select Inventories

Selecting inventories enables batch actions such as exporting, deleting, or generating reports.

1. Tap the **checkbox** on the left of each item.  
2. A bottom action bar appears with:
   - **Delete**
   - **Export**
   - **More options** (species comparison, statistics)
   - **Clear selection**

## Import Inventories

Xolmis Mobile supports importing inventories from JSON files exported by other users or devices.

1. Open **Inventories**.  
2. Tap the **⋮** menu in the top-right corner.  
3. Select **Import**.  
4. Choose a JSON file.  
5. The app will process the file and notify you of the result.

Import behavior for existing records can be configured in **Settings → Import & Export**.

## Export Inventories

Inventories can be exported individually or in groups.

### Export one

1. Long-press the inventory.  
2. Choose the export format:
   - **CSV**
   - **Excel** (experimental)
   - **JSON**
   - **KML** (including POIs)

### Export multiple

1. Select two or more inventories.  
2. Tap the **Export** icon.  
3. Choose the desired format.

### Export all finished inventories

1. Tap the **⋮** menu in the top-right corner.  
2. Select **Export all (JSON)**.

A sharing panel will appear so you can send the file to cloud storage or another device.

## Search Inventories

Use the search bar at the top of the screen to find inventories by:

- ID  
- Locality  

Search updates results instantly as you type.

## Sort Inventories

Tap the **sort icon** in the search bar to open sorting options.

You can sort by:

- ID  
- Locality  
- Initial time
- Final time  
- Inventory type

Each field can be sorted in ascending or descending order.

---

Managing inventories efficiently helps keep your fieldwork organized and ensures smooth integration with Xolmis Desktop for long-term storage and analysis.

*[CSV]: Comma Separated Values
*[JSON]: JavaScript Object Notation
*[KML]: Keyhole Markeup Language