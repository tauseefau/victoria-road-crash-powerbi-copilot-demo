# Report Spec

## Report identity
- Report name: FireReport (existing PBIP, name unchanged)
- Semantic model: FireReport.SemanticModel
- Audience: Road-safety analysts and leadership (inferred, no audience stated)
- Primary purpose: See where and when people die on Victorian roads, and whether it is improving
- Delivery target: Local PBIP only, no publishing

## Semantic model binding
- Entry mode: Local Model
- Workspace name: n/a
- Workspace ID: n/a
- Model name: FireReport
- Model ID: n/a
- connectionString: byPath ../FireReport.SemanticModel (already set, unchanged)

## User decisions and constraints
- Scope: One dashboard on the existing blank page
- Page count: 1
- Interactivity: No navigation. Two slicers (Year, Region). Default cross-filtering between visuals.
- Design direction: Dark visual theme
- Publishing: None
- Tooling: powerbi-report-author CLI, TMDL edits, Power BI Desktop preview. Modeling MCP is not connected, so model changes are direct TMDL edits.
- Model edit permissions: Add 7 measures and 2 calculated columns to victorian_road_crash_data, and a sort-by on DAY_OF_WEEK. No existing column, table or relationship changes.
- Accessibility: WCAG AA text contrast on dark, alt text on every chart, no meaning carried by colour alone
- Data caveats:
  - 2026 is incomplete (228 crashes against about 15,000 a year), so a page filter limits the dashboard to 2012-2025. This hides 35 deaths from the totals.
  - 1,294 crashes have no region (1 death). They count in totals but are hidden from the region chart.
  - Only victorian_road_crash_data is used. It holds one row per crash and all needed fields, so no joins are needed.
  - CFA_Incident_Response.xlsx is in the folder but not in the model, so fire incidents are not covered.

## Narrative
- Core story: Deaths have not fallen since 2012, and high-speed roads carry a share of deaths far above their share of crashes.
- Audience promise: In under a minute, know the toll, its trend, and where the risk concentrates.
- Key questions answered: How many? Is it improving? When do crashes happen? Which regions, speed zones and crash types are deadliest?

## Design identity
- Tone: Industrial Cockpit (dark instrument panel)
- Signature: Day-by-hour heat grid, with colour reserved for risk
- Brownfield delta: n/a, the page is blank

## Page plan
1. Victorian Road Safety
   - Archetype: Operational Monitor
   - Layout variant (A/B/C): A. Four KPIs of equal weight, then two time panels over three risk rankings.
   - Purpose: Size the toll, show the trend, locate the risk
   - Visuals: 4 KPI cards, deaths by year, crashes by day and hour, deaths by region, death rate by speed zone, deaths by crash type
   - Fields/measures: See Model requirements
   - Slicers/interactions: Year and Region dropdowns

## Design system summary
- Theme name + base palette: "Road Safety Dark", based on base.json. Page #0E1116, panels #1A2029, text #E8EDF2, muted text #A3AEBA, gridlines #2E3742.
- Color semantics: Deaths and death rate coral #FF6B5E. Serious injuries amber #F2B84B. Crashes blue #5AA9E6.
- Typography pairing: Segoe UI Semibold for titles and values, Segoe UI for body
- Layout pattern: 12x12 grid, 32 margin, 24 gutter, dense
- Accessibility commitments: All text pairs at or above 4.5:1 on #1A2029. Every chart has alt text.

## Model requirements
- Existing measures: None
- New measures (table victorian_road_crash_data):
  - Crashes = COUNTROWS(victorian_road_crash_data)
  - Deaths = SUM(victorian_road_crash_data[FATALITY])
  - Serious Injuries = SUM(victorian_road_crash_data[SERIOUSINJURY])
  - Deaths per 1,000 Crashes = DIVIDE([Deaths], [Crashes]) * 1000
  - Crashes vs Prior Year, Deaths vs Prior Year, Serious Injuries vs Prior Year: text such as "2025: +5 vs 2024", using the latest year in context
- New calculated columns:
  - Crash Hour = HOUR(victorian_road_crash_data[ACCIDENT_TIME])
  - Day Order = 1 (Monday) to 7 (Sunday), from DAY_OF_WEEK
- Relationship/sort requirements: DAY_OF_WEEK sorted by Day Order. No relationship changes.

## Canonical design contract

```yaml
Design Brief:
  generated_by: powerbi-report-cli
  contract_version: 1
  mode: greenfield
  design_identity:
    tone: Industrial Cockpit
    signature: Day-by-hour heat grid on a dark panel, colour reserved for risk
  archetype: Operational
  navigation_model: none
  color_map:
    - measure: victorian_road_crash_data[Deaths]
      color: "#FF6B5E"
      tint: "#4A2A2A"
    - measure: victorian_road_crash_data[Deaths per 1,000 Crashes]
      color: "#FF6B5E"
      tint: "#4A2A2A"
    - measure: victorian_road_crash_data[Serious Injuries]
      color: "#F2B84B"
      tint: "#4A3D22"
    - measure: victorian_road_crash_data[Crashes]
      color: "#5AA9E6"
      tint: "#1F3A52"
  pages:
    - name: Victorian Road Safety
      role: landing
      archetype: Operational
      layout_variant: A
      variant_rationale: Four KPIs of comparable weight and five supporting questions, with no single hero metric.
      navigation: []
      page_background: "#0E1116"
      layout_summary: Title and slicers, KPI strip, two time panels, three risk rankings.
      layout_contract:
        canvas:
          width: 1920
          height: 1080
          margin: 32
          gutter: 24
          snap: 8
        grid:
          columns: 12
          rows: 12
          regions:
            header: [1, 1, 9, 2]
            filters: [9, 1, 13, 2]
            kpis: [1, 2, 13, 4]
            trend: [1, 4, 7, 8]
            heatgrid: [7, 4, 13, 8]
            regions_rank: [1, 8, 5, 13]
            speed_rank: [5, 8, 9, 13]
            type_rank: [9, 8, 13, 13]
        placements:
          - id: page_title
            region: header
            kind: textbox
            text: "Victoria's road deaths haven't fallen since 2012, and 100 km/h roads carry 42% of them"
            purpose: State the statewide 2012-2025 finding before any chart.
          - id: year_slicer
            region: filters
            kind: slicer
            field_bindings: LocalDateTable_54414416-33de-4d1f-a775-2118f4f740e5[Year]
            slicer_type: dropdown
            slot: 1
            of: 2
          - id: region_slicer
            region: filters
            kind: slicer
            field_bindings: victorian_road_crash_data[DTP_REGION]
            slicer_type: dropdown
            slot: 2
            of: 2
          - id: crashes_card
            region: kpis
            kind: cardVisual
            purpose: How many injury crashes were recorded?
            field_bindings: victorian_road_crash_data[Crashes]
            insight_basis: "Reference label: victorian_road_crash_data[Crashes vs Prior Year]"
            color_strategy: measure_match
            slot: 1
            of: 4
          - id: deaths_card
            region: kpis
            kind: cardVisual
            purpose: How many people died?
            field_bindings: victorian_road_crash_data[Deaths]
            insight_basis: "Reference label: victorian_road_crash_data[Deaths vs Prior Year]"
            color_strategy: measure_match
            slot: 2
            of: 4
          - id: serious_card
            region: kpis
            kind: cardVisual
            purpose: How many people were seriously injured?
            field_bindings: victorian_road_crash_data[Serious Injuries]
            insight_basis: "Reference label: victorian_road_crash_data[Serious Injuries vs Prior Year]"
            color_strategy: measure_match
            slot: 3
            of: 4
          - id: rate_card
            region: kpis
            kind: cardVisual
            purpose: How lethal is the average crash?
            field_bindings: victorian_road_crash_data[Deaths per 1,000 Crashes]
            insight_basis: "Static reference label: deaths per 1,000 recorded crashes"
            color_strategy: measure_match
            slot: 4
            of: 4
          - id: deaths_trend
            region: trend
            kind: lineChart
            purpose: Are road deaths falling over time?
            field_bindings: { Category: "LocalDateTable_54414416-33de-4d1f-a775-2118f4f740e5[Year]", Y: "victorian_road_crash_data[Deaths]" }
            sort_policy: category_asc
            color_strategy: measure_match
          - id: day_hour_heatgrid
            region: heatgrid
            kind: pivotTable
            purpose: At which day and hour do crashes concentrate?
            field_bindings: { Rows: "victorian_road_crash_data[DAY_OF_WEEK]", Columns: "victorian_road_crash_data[Crash Hour]", Values: "victorian_road_crash_data[Crashes]" }
            sort_policy: natural_order
            color_strategy: gradient
          - id: region_bar
            region: regions_rank
            kind: barChart
            purpose: Which regions lose the most people?
            field_bindings: { Category: "victorian_road_crash_data[DTP_REGION]", Y: "victorian_road_crash_data[Deaths]" }
            sort_policy: value_desc
            color_strategy: measure_match
          - id: speed_bar
            region: speed_rank
            kind: barChart
            purpose: Which speed zones make a crash most deadly?
            field_bindings: { Category: "victorian_road_crash_data[SPEED_ZONE]", Y: "victorian_road_crash_data[Deaths per 1,000 Crashes]" }
            sort_policy: value_desc
            color_strategy: measure_match
          - id: type_bar
            region: type_rank
            kind: barChart
            purpose: Which crash types cause the most deaths?
            field_bindings: { Category: "victorian_road_crash_data[ACCIDENT_TYPE]", Y: "victorian_road_crash_data[Deaths]" }
            sort_policy: value_desc
            color_strategy: measure_match
        space_audit:
          content_cell_count: 132
          placed_cell_count: 132
          empty_cell_pct: 0
          unplaced_regions: []
          largest_region:
            name: trend
            pct_of_content: 18
          balance_rationale: The KPI strip, two time panels and three rankings fill the page. No region dominates, because the page answers several questions of equal weight.
  interaction_pattern:
    drill_targets: []
    cross_filter_rules: Default cross-highlight between all visuals. Slicers filter every visual.
  accessibility:
    alt_text_strategy: Chart type plus the question it answers, on every chart
    contrast_notes: "#A3AEBA muted text and all three accent colours exceed 4.5:1 on #1A2029. Heat grid cells show no numbers by default, so tooltips carry exact values."
  theme:
    base: references/design/assets/base.json adapted to dark
    user_overrides: None
```

## Implementation notes

- Model changes: Direct TMDL edits to tables/victorian_road_crash_data.tmdl, then load through Desktop. Calculated columns need a recalculation.
- PBIR/report authoring: Rename "Page 1" to "Victorian Road Safety", add a custom theme, author visuals, add page filter Year <= 2025.
- Validation: powerbi-report-author validate, then check rendered values against the CSV: 202,069 crashes, 3,607 deaths, 83,956 serious injuries, 17.9 deaths per 1,000.
- Desktop screenshot verification: Open FireReport in its own Desktop instance, reload, screenshot, fix.
- Publishing boundary: Local only.
- Risks: The title is static, statewide, 2012-2025 text and does not change with slicers. The model's CSV import uses QuoteStyle.None, so model totals may differ from the CSV check if any field holds quoted commas.
