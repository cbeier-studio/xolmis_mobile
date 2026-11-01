# Statistics of Selected Inventories

Xolmis Mobile allows you to compare multiple finished inventories using a dedicated **Statistics** screen. This feature helps you evaluate sampling effort, species richness, temporal patterns, and overall survey performance across different locations or dates.

Statistics are available only when **two or more finished inventories** are selected. The Species per Inventory report is available when **one or more finished inventories** are selected.

## Accessing the Statistics Screen

1. Open the **Inventories** module.  
2. Switch to the **Finished** tab.  
3. Select two or more inventories using the checkboxes.  
4. Tap the :material-chart-box-outline: **Statistics** button in the bottom bar.

A new screen will open with summary information and several charts.

## Summary Information

At the top of the statistics screen, you will find key metrics:

- **Selected inventories** – total number of inventories included in the comparison.  
- **Sampled localities** – number of distinct localities represented.  
- **Total richness** – total number of unique species across all selected inventories.  
- **Average richness** – mean number of species per inventory.
- **Shared species** – number of species shared between all selected inventories.
- **Exclusive species** – number of species exclusive to each inventory.

These values provide a quick overview of sampling coverage and diversity.

## Species Accumulation Curve

This chart shows how species accumulate across the selected inventories.

- The **X‑axis** represents the inventories in the order they were selected.  
- The **Y‑axis** shows the cumulative number of species.  
- Three lines are displayed:
  - **Pink line** – species within the sample only  
  - **Purple line** – all species, including those outside the sample  
  - **Teal dashed line** – rarefaction curve (Mao Tau)  

This visualization is especially useful for **Mackinnon lists** or sequential surveys, helping assess sampling completeness.

### Accessing the Species per Inventory report

Below the species accumulation chart is a button to **View Species Table**.

A new screen will open with a data table, where:

- The first column lists all species recorded alphabetically.
- The second column shows the global conservation status of each species. 
- Following columns show one inventory each, listing the presence (X - within sample, O - outside sample) or abundance for each species on the first column, with the value in highlighted if it is the first occurrence of the species in this comparison.
- The penultimate column and last row show the totals for rows and columns.
- The last column shows the relative frequency of each species.

This report can be exported to CSV tapping the **Export** icon on the screen top right.

## Records per Hour

A bar chart showing the number of species detections (or species added) per hour of the day.

- Helps identify **peak activity periods**.  
- Useful for planning future surveys or understanding observer effort.  
- Can reveal under‑sampled time periods.

## Species Richness per Inventory

A bar chart comparing the total number of species recorded in each selected inventory.

- **X‑axis** – inventories  
- **Y‑axis** – species richness  
- Useful for comparing:
  - Different habitats  
  - Different dates  
  - Different observers  
  - Different sampling methods  

This chart helps highlight inventories with unusually high or low richness.

## Conservation Status

Bar chart showing the species distribution in each category of global conservation status.

If any species are in a threatened category, a **View Species Table** button is available below the chart, which opens a list of the recorded threatened species.

## Biodiversity Indices

### Diversity Indicators

- **Observed Richness (Hill N0)** - observed richness (`S`) and Hill Number N0 (q=0), which are equivalent.
- **Total Individuals** - total abundance (`N`).
- **Shannon-Wiener Index (H')**: measures diversity considering both richness and evenness, being sensitive to rare species.
- **Simpson Index (1-D)**: measures the probability that two randomly selected individuals belong to different species, being more sensitive to dominant species.
- **Pielou's Evenness (J')**: measures how evenly individuals are distributed among the present species (ranges from 0 to 1).
- **Hill Numbers**: unified family of indices expressing diversity in terms of effective number of species.
  - **Hill N1 (q=1)**: exponential of the Shannon index; weights species according to their proportional abundance.
  - **Hill N2 (q=2)**: inverse of the Simpson index; gives more weight to dominant species.
- **Chao1 Richness Estimator**: non-parametric estimate of total species richness based on the proportion of rare species (*singletons* and *doubletons*).

### Indices per Inventory

Table with the same diversity indicators calculated for each selected inventory.

## When to Use Inventory Statistics

The statistics screen is especially helpful when:

- Comparing multiple sampling sites  
- Evaluating survey effort across days or observers  
- Analyzing temporal patterns in species detection  
- Assessing the effectiveness of different methods  
- Reviewing data before exporting or importing into Xolmis Desktop  

These tools provide a quick, visual summary of your fieldwork and help guide further analysis.

---

The Statistics of Selected Inventories feature gives you a powerful overview of your survey data, helping you understand patterns, detect trends, and make informed decisions about future sampling.
