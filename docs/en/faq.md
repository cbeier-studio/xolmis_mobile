# FAQ — Frequently Asked Questions

This section answers the most common questions about using **Xolmis Mobile** in the field, managing data, and resolving typical issues.

## General

### What is Xolmis Mobile?

Xolmis Mobile is the field‑data collection companion to Xolmis Desktop. It allows you to record inventories, nests, specimens, and field notes quickly and offline during fieldwork.

### Do I need internet access to use the app?

No. Xolmis Mobile works fully offline. Internet is only needed for installing the app, updating it, or sharing exported files.

### Is Xolmis Mobile free?

Yes. The app is free and open‑source.

## Installation & Setup

### Why does the app ask for GPS, camera, or notification permissions?

- **GPS**: to record coordinates for inventories, species POIs, nests, specimens, and journal entries.  
- **Camera/Photos**: to attach images to records.  
- **Notifications**: to alert you when timed inventories finish automatically.

### The app says I must set an observer abbreviation. Why?

The observer abbreviation is required to generate:

- Inventory IDs  
- Nest field numbers  
- Specimen field numbers  

Without it, you cannot create new records.

## Inventories

### Why can’t I add more species to my list?

Possible reason is that you reached the **maximum species limit** (Mackinnon or custom limit).  

### Why did my inventory finish automatically?

Depending on the method:

- Timed lists end when the timer reaches zero.  
- Interval lists end after three consecutive intervals with no new species.  
- Point counts and timed methods end when their duration expires.

### Why are some species marked in gray?

Gray species are **outside the sample**, meaning they were added after finishing the inventory.

## Species Search

### Why can’t I find a species in the search list?

Possible reasons:

- The species is not included in the selected **country’s checklist**.  
- The taxonomy or checklist may be outdated or incomplete.  
- You typed too few characters.

You can always add a **temporary custom species name** using the “Add species” option.

## Nests & Specimens

### Why can’t I inactivate a nest?

A nest must have **at least one revision** before it can be marked inactive.

### Why is the field number not generated?

Check if:

- The **observer abbreviation** is set.  
- The date is valid.  
- The record type supports automatic numbering.

## Field Journal

### Can I add images or coordinates to a journal entry?

Yes. You can attach photos and optionally add GPS coordinates to any note.

## Import & Export

### What formats can I export?

Depending on the module:

- **CSV**  
- **Excel** (experimental)  
- **JSON**  
- **KML**
- **Plain text** (field journal)
- **Markdown** (field journal)

### How do I import data from another device?

Export a JSON file from the other device → open Xolmis Mobile → Inventories/Nests/Specimens → menu → **Import** → select the file.

### What happens if imported records already exist?

You can choose to:

- Always ask  
- Update existing records  
- Ignore existing records  

This behavior is configurable in **Settings → Import & Export**.

## Backup & Restore

### How do I back up my data?

Go to **Settings → Backup → Create backup**.

A single file containing the database and images will be generated.

### What happens when I restore a backup?

All current data is **replaced** by the backup.

Use this carefully.

## Troubleshooting

### The app is slow or unresponsive. What can I do?

Try:

- Closing and reopening the app  
- Restarting the device  
- Ensuring you are using the latest version  
- Checking if your device storage is full  

Xolmis Mobile automatically cleans temporary files on startup.

### GPS is not working. How can I fix it?

- Ensure location permission is granted  
- Enable GPS on the device  
- Move to an open area  
- If GPS still fails, you can **enter coordinates manually**

### Why did the screen go blank after deleting something?

This was a known issue in early versions and has been fixed.

Update to the latest version.

## Data & Privacy

### Where is my data stored?

All data is stored **locally on your device**.

Nothing is uploaded automatically.

### Does the app share my data with anyone?

No. You choose when and how to export or share files.

## Integration with Xolmis Desktop

### How do I transfer data to Xolmis Desktop?

1. Export inventories/nests/specimens from Mobile (JSON recommended).  
2. Open Xolmis Desktop.  
3. Use **File → Import → Import from Xolmis Mobile**.  
4. Review and validate the imported records.

### Do I need Xolmis Desktop to use the Mobile app?

No. Xolmis Mobile works independently, but Desktop is recommended for:

- Long‑term storage  
- Data validation  
- Analysis and reporting  
