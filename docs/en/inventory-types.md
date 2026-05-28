# Inventory Types

Xolmis Mobile supports several inventory (survey) methods used in ornithological fieldwork. Each method follows specific rules regarding time, species limits, and how detections are recorded. Choosing the correct type ensures that your data remains consistent with the sampling protocol used in your project.

Below is an overview of all inventory types available in the app.

## 1. Qualitative List (Free)

A simple list of all species detected at a location during a visit.

- **No time limit**  
- **No species limit**  
- Ideal for casual surveys or general checklists  
- Species are added once (no duplicates)

## 2. Timed Qualitative List

A qualitative list with a countdown timer.

- **Default duration:** 45 minutes (configurable)  
- The timer **restarts** every time a new species is added  
- If no new species are added before the timer expires, the inventory **finishes automatically**  
- A notification is shown when the list ends

Useful for standardized effort-based surveys.

## 3. Interval Qualitative List

A qualitative list divided into fixed time intervals.

- **Default interval:** 10 minutes (configurable)  
- The timer **does not restart** when species are added  
- After each interval, the next one begins automatically  
- If **three consecutive intervals** pass with no new species, the inventory **ends automatically**  
- Tracks how many intervals had no new species

Useful for detecting changes in species activity over time.

## 4. Mackinnon List

A structured list with a fixed number of species per list.

- **Default species limit:** 10 (configurable)  
- When the limit is reached, the app asks whether to:
  - Start the next list, or  
  - Stop  
- Each list is saved as a **separate inventory**

Widely used in rapid biodiversity assessments.

## 5. Transect Count

A quantitative survey conducted while moving along a route.

- Records **species and number of individuals**  
- Movement-based method  
- Species are added once, with adjustable counts  
- Suitable for walking or driving transects

## 6. Point Count

A quantitative survey conducted from a fixed point.

- **Default duration:** 8 minutes (configurable)  
- Records species and individual counts  
- Ends automatically when the timer expires  
- Ideal for standardized point sampling

## 7. Banding (Mist-Netting)

A list of species detected during banding operations.

- Optional individual counts  
- No time or species limits  
- Species added here **do not synchronize** with other active inventories

Designed for mist-netting sessions or ringing stations.

## 8. Casual Observation

A simple record of opportunistic sightings.

- Not intended to represent a complete species list  
- No time or species limits  
- Useful for isolated or incidental observations

## 9. Detection Transect

A transect where **each detection** is recorded as a separate entry.

- Each individual or group is logged independently  
- Additional fields:
  - Perpendicular distance  
  - Height  
  - Flight direction  
- Allows multiple entries of the same species

Used for distance sampling and detectability studies.

## 10. Detection Point

A point-based version of the detection transect.

- Each detection is a separate record  
- Includes distance, height, and direction fields  
- Similar to point counts, but with individual-level detail

Useful for point-based distance sampling.

## Choosing the Right Method

The best inventory type depends on your project goals:

- **General birding or casual surveys:** Qualitative List  
- **Standardized effort:** Timed or Interval Lists  
- **Rapid assessments:** Mackinnon Lists  
- **Quantitative monitoring:** Transect or Point Count  
- **Distance sampling:** Detection Transect or Detection Point  
- **Banding operations:** Banding List  
- **Opportunistic sightings:** Casual Observation  

Each method is designed to match real-world field protocols, ensuring your data remains consistent and scientifically useful.

