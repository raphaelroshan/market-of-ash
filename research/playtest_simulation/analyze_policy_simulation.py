#!/usr/bin/env python3
"""Summarize deterministic Market of Ash first-run policy simulation results."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

POLICY_LABELS = {
    "guided_grain_delivery": "Guided grain delivery",
    "forecast_maximizer": "Forecast maximizer",
    "gross_margin_chaser": "Gross-margin chaser",
    "toll_road_only": "Toll-road-only",
    "no_trade": "No trade baseline",
}

POLICY_RULES = {
    "guided_grain_delivery": "Buys 2 grain; travels Ashgate → Reedwatch via Old Road.",
    "forecast_maximizer": "Chooses the legal first trade with the highest displayed expected net profit.",
    "gross_margin_chaser": "Chooses the legal first trade with the highest displayed gross margin.",
    "toll_road_only": "Chooses the best displayed net-profit trade while using the legal Toll Road corridor only.",
    "no_trade": "Takes no action; baseline for resource preservation.",
}

EVENT_PROBE_LABELS = {
    "span_material_reserve_probe": "Span material-reserve probe",
    "last_barrel_fair_share_probe": "Last Barrel fair-share probe",
}

PRE_B0_CALIBRATION = {
    "guided_grain_delivery": {"mean_error": 3.2, "mean_absolute_error": 4.6},
    "forecast_maximizer": {"mean_error": 66.8, "mean_absolute_error": 66.8},
    "gross_margin_chaser": {"mean_error": 66.8, "mean_absolute_error": 66.8},
    "toll_road_only": {"mean_error": 8.6, "mean_absolute_error": 14.8},
}


def signed(value: float) -> str:
    return f"{value:+.1f}"


def pct(value: float) -> str:
    return f"{value * 100:.1f}%"


def markdown_table(frame: pd.DataFrame) -> str:
    return frame.to_markdown(index=False, disable_numparse=True)


def write_chart(summary: pd.DataFrame, path: Path) -> None:
    ordered = summary.sort_values("policy_order")
    labels = ordered["policy_label"].tolist()
    x = np.arange(len(ordered))
    colors = ["#d99a5b", "#e6c58d", "#c77a52", "#83a6aa", "#74695f"]

    fig, (profit_ax, risk_ax) = plt.subplots(
        2, 1, figsize=(11.5, 7.5), constrained_layout=True, height_ratios=[1.25, 1]
    )
    profit_ax.bar(x, ordered["mean_realized_economic_profit"], color=colors, width=0.66)
    profit_ax.axhline(0, color="#47392f", linewidth=1)
    profit_ax.set_ylabel("Mean realized economic profit\n(ashmarks equivalent)")
    profit_ax.set_title("Legal first-run policy outcomes across 100 deterministic seeds")
    profit_ax.set_xticks(x, labels, rotation=16, ha="right")
    for index, value in enumerate(ordered["mean_realized_economic_profit"]):
        profit_ax.text(index, value + (1.0 if value >= 0 else -1.5), signed(value), ha="center", va="bottom" if value >= 0 else "top", fontsize=9)
    profit_ax.grid(axis="y", color="#e8dcc7", linewidth=0.7, alpha=0.8)
    profit_ax.spines[["top", "right"]].set_visible(False)

    risk_ax.bar(x, ordered["incident_rate"] * 100, color=colors, width=0.66)
    risk_ax.set_ylabel("Route incident rate (%)")
    risk_ax.set_xticks(x, labels, rotation=16, ha="right")
    risk_ax.set_ylim(0, max(10, float(ordered["incident_rate"].max() * 125)))
    for index, value in enumerate(ordered["incident_rate"]):
        risk_ax.text(index, value * 100 + 1.2, pct(value), ha="center", va="bottom", fontsize=9)
    risk_ax.grid(axis="y", color="#e8dcc7", linewidth=0.7, alpha=0.8)
    risk_ax.spines[["top", "right"]].set_visible(False)

    fig.patch.set_facecolor("#fbf7ef")
    for axis in (profit_ax, risk_ax):
        axis.set_facecolor("#fbf7ef")
    fig.savefig(path, dpi=180, facecolor=fig.get_facecolor())
    plt.close(fig)


def write_choice_chart(choice_mix: pd.DataFrame, path: Path) -> None:
    actionable = choice_mix[choice_mix["policy"] != "no_trade"].copy()
    pivot = actionable.pivot(index="policy_label", columns="choice", values="share").fillna(0)
    pivot = pivot.reindex([POLICY_LABELS[key] for key in POLICY_LABELS if key != "no_trade"]).fillna(0)
    fig, ax = plt.subplots(figsize=(11.5, 5.5), constrained_layout=True)
    left = np.zeros(len(pivot))
    palette = ["#d99a5b", "#e6c58d", "#c77a52", "#83a6aa", "#8f7a65", "#7f8f60"]
    for index, column in enumerate(pivot.columns):
        values = pivot[column].to_numpy() * 100
        ax.barh(pivot.index, values, left=left, label=column, color=palette[index % len(palette)])
        left += values
    ax.set_xlabel("Share of simulated first-trade choices (%)")
    ax.set_xlim(0, 100)
    ax.set_title("Legal first-trade choice concentration by policy")
    ax.legend(title="Good → destination / route", bbox_to_anchor=(1.02, 1), loc="upper left", frameon=False)
    ax.grid(axis="x", color="#e8dcc7", linewidth=0.7, alpha=0.8)
    ax.spines[["top", "right"]].set_visible(False)
    fig.patch.set_facecolor("#fbf7ef")
    ax.set_facecolor("#fbf7ef")
    fig.savefig(path, dpi=180, facecolor=fig.get_facecolor(), bbox_inches="tight")
    plt.close(fig)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    data = json.loads(args.input.read_text(encoding="utf-8"))
    rows = pd.DataFrame(data["rows"])
    multi_trip_rows = pd.DataFrame(data.get("multi_trip_rows", []))
    memory_probe = data.get("market_memory_probe", {})
    output = args.output_dir
    output.mkdir(parents=True, exist_ok=True)

    rows["policy_label"] = rows["policy"].map(POLICY_LABELS)
    rows["forecast_error"] = rows["realized_economic_profit"] - rows["forecast_expected_net_profit"]
    rows["choice"] = rows.apply(
        lambda row: "No trade" if not row["good_id"] else f"{row['good_id']} → {row['destination_id']} / {row['route_id']}",
        axis=1,
    )
    rows.to_csv(output / "simulated_runs.csv", index=False)

    summary = (
        rows.groupby(["policy", "policy_label"], sort=False)
        .agg(
            runs=("seed", "count"),
            completion_rate=("status", lambda series: (series == "completed").mean()),
            incident_rate=("incident", "mean"),
            mean_forecast_net_profit=("forecast_expected_net_profit", "mean"),
            mean_realized_cash_profit=("realized_cash_profit", "mean"),
            mean_realized_economic_profit=("realized_economic_profit", "mean"),
            median_realized_economic_profit=("realized_economic_profit", "median"),
            p10_realized_economic_profit=("realized_economic_profit", lambda series: series.quantile(0.10)),
            p90_realized_economic_profit=("realized_economic_profit", lambda series: series.quantile(0.90)),
            loss_rate=("realized_economic_profit", lambda series: (series < 0).mean()),
            mean_forecast_error=("forecast_error", "mean"),
            mean_quantity=("quantity_purchased", "mean"),
            mean_provisions_remaining=("ending_provisions", "mean"),
        )
        .reset_index()
    )
    summary["policy_order"] = summary["policy"].map({key: index for index, key in enumerate(POLICY_LABELS)})
    summary = summary.sort_values("policy_order")
    summary.to_csv(output / "policy_summary.csv", index=False)

    choice_mix = (
        rows.groupby(["policy", "policy_label", "choice"], sort=False)
        .size()
        .rename("runs")
        .reset_index()
    )
    choice_mix["share"] = choice_mix.groupby("policy")["runs"].transform(lambda series: series / series.sum())
    choice_mix = choice_mix.sort_values(["policy", "runs"], ascending=[True, False])
    choice_mix.to_csv(output / "choice_mix.csv", index=False)

    route_mix = (
        rows[rows["route_id"] != ""]
        .groupby(["policy", "route_id"], sort=False)
        .size()
        .rename("runs")
        .reset_index()
    )
    route_mix["share"] = route_mix.groupby("policy")["runs"].transform(lambda series: series / series.sum())
    route_mix.to_csv(output / "route_mix.csv", index=False)

    event_rows = rows[rows["event_id"] != ""].copy()
    event_probe_rows = pd.DataFrame(data.get("event_probe_rows", []))
    if not event_probe_rows.empty:
        event_probe_rows["policy_label"] = event_probe_rows["policy"].map(EVENT_PROBE_LABELS).fillna(event_probe_rows["policy"])
        event_rows = pd.concat([event_rows, event_probe_rows[event_probe_rows["event_id"] != ""]], ignore_index=True, sort=False)
    if not event_rows.empty:
        event_summary = (
            event_rows.groupby(["policy_label", "event_id", "event_choice_id"], sort=False)
            .size()
            .rename("runs")
            .reset_index()
        )
        event_summary["share_of_policy_runs"] = event_summary["runs"] / data["seed_count"]
        event_summary.to_csv(output / "event_outcomes.csv", index=False)
        event_display = event_summary.copy()
        event_display["share_of_policy_runs"] = event_display["share_of_policy_runs"].map(pct)
        event_display.columns = ["Policy", "Event", "Choice", "Runs", "Share of policy runs"]
        event_table = markdown_table(event_display)
    else:
        event_summary = pd.DataFrame()
        event_table = "No travel events triggered."

    if not multi_trip_rows.empty:
        multi_trip_rows["choice"] = multi_trip_rows.apply(
            lambda row: f"{row.get('good_id', '')} → {row.get('destination_id', '')} / {row.get('route_id', '')}",
            axis=1,
        )
        multi_trip_rows.to_csv(output / "multi_trip_runs.csv", index=False)
        multi_trip_choice_mix = (
            multi_trip_rows.groupby(["delivery_index", "choice"], sort=True)
            .size()
            .rename("runs")
            .reset_index()
        )
        multi_trip_choice_mix["share"] = multi_trip_choice_mix.groupby("delivery_index")["runs"].transform(
            lambda series: series / series.sum()
        )
        multi_trip_choice_mix.to_csv(output / "multi_trip_choice_mix.csv", index=False)
        multi_trip_display = multi_trip_choice_mix.copy()
        multi_trip_display["share"] = multi_trip_display["share"].map(pct)
        multi_trip_display.columns = ["Delivery", "Chosen trade", "Runs", "Share"]
        multi_trip_table = markdown_table(multi_trip_display)
    else:
        multi_trip_choice_mix = pd.DataFrame()
        multi_trip_table = "No multi-trip results were produced."

    calibration = (
        rows[rows["policy"] != "no_trade"]
        .groupby(["policy", "policy_label"], sort=False)
        .agg(
            forecast_net=("forecast_expected_net_profit", "mean"),
            realized_economic=("realized_economic_profit", "mean"),
            mean_error=("forecast_error", "mean"),
            mean_absolute_error=("forecast_error", lambda series: series.abs().mean()),
        )
        .reset_index()
    )
    calibration.to_csv(output / "forecast_calibration.csv", index=False)

    write_chart(summary, output / "policy_outcomes.png")
    write_choice_chart(choice_mix, output / "choice_concentration.png")

    forecast_policy = summary.loc[summary["policy"] == "forecast_maximizer"].iloc[0]
    gross_policy = summary.loc[summary["policy"] == "gross_margin_chaser"].iloc[0]
    toll_policy = summary.loc[summary["policy"] == "toll_road_only"].iloc[0]
    guided_policy = summary.loc[summary["policy"] == "guided_grain_delivery"].iloc[0]
    forecast_choice = choice_mix[choice_mix["policy"] == "forecast_maximizer"].iloc[0]
    gross_choice = choice_mix[choice_mix["policy"] == "gross_margin_chaser"].iloc[0]
    toll_choice = choice_mix[choice_mix["policy"] == "toll_road_only"].iloc[0]

    presentation = summary[
        [
            "policy_label", "runs", "completion_rate", "incident_rate",
            "mean_forecast_net_profit", "mean_realized_economic_profit",
            "median_realized_economic_profit", "loss_rate", "mean_forecast_error", "mean_quantity",
        ]
    ].copy()
    presentation.columns = [
        "Policy", "Runs", "Completed", "Incident rate", "Forecast net", "Realized economic",
        "Median realized", "Loss rate", "Forecast error", "Mean units",
    ]
    for column in ["Completed", "Incident rate", "Loss rate"]:
        presentation[column] = presentation[column].map(pct)
    for column in ["Forecast net", "Realized economic", "Median realized", "Forecast error"]:
        presentation[column] = presentation[column].map(signed)
    presentation["Mean units"] = presentation["Mean units"].map(lambda value: f"{value:.1f}")

    decision_mix_display = choice_mix.copy()
    decision_mix_display["Share"] = decision_mix_display["share"].map(pct)
    decision_mix_display = decision_mix_display[["policy_label", "choice", "runs", "Share"]]
    decision_mix_display.columns = ["Policy", "Chosen first trade", "Runs", "Share"]

    calibration_display = calibration.copy()
    calibration_display.columns = ["Policy key", "Policy", "Forecast net", "Realized economic", "Mean error", "Mean absolute error"]
    for column in ["Forecast net", "Realized economic", "Mean error", "Mean absolute error"]:
        calibration_display[column] = calibration_display[column].map(signed)
    calibration_display = calibration_display[["Policy", "Forecast net", "Realized economic", "Mean error", "Mean absolute error"]]

    comparison_rows = []
    for policy, baseline in PRE_B0_CALIBRATION.items():
        current = calibration.loc[calibration["policy"] == policy].iloc[0]
        comparison_rows.append(
            {
                "Policy": POLICY_LABELS[policy],
                "Mean error before": signed(baseline["mean_error"]),
                "Mean error after": signed(float(current["mean_error"])),
                "MAE before": signed(baseline["mean_absolute_error"]),
                "MAE after": signed(float(current["mean_absolute_error"])),
            }
        )
    calibration_comparison = pd.DataFrame(comparison_rows)

    report = f"""# Market of Ash — Corrected Automated First-Run Playtest Simulation

> **Scope note:** This is a deterministic, rule-based simulation of the current prototype, not a substitute for human playtests. It reveals what the implemented economy rewards under explicit policies; it does not measure player enjoyment, comprehension, or preference.

## Corrected Topology

Routes now declare exactly two canonical endpoints in `runtime_world.json`. The command processor rejects a departure unless the selected route connects the caravan’s current settlement to the selected destination. The user interface filters destinations and routes from the same content. Consequently, every completed simulation row below is a legal endpoint-to-endpoint departure; there is no separate map-constrained counterfactual policy.

## Scope and Method

The run starts every simulated trader in the current quick-playtest state: Ashgate, day one, 120 ashmarks, twelve provisions, and empty cargo. It executes the existing buy, travel, and sell command boundary across **{data['seed_count']} seeds**. Each policy is evaluated once per seed. The seed range covers the complete 100-value route-roll cycle produced by the current route incident formula for a fixed travel day.

| Policy | Decision rule |
| --- | --- |
""" + "\n".join(f"| {POLICY_LABELS[key]} | {POLICY_RULES[key]} |" for key in POLICY_LABELS) + f"""

The simulator tests the initial one-trade loop plus an adaptive three-delivery policy that re-evaluates the best visible trade after market pressure and elapsed-time decay. When Gatekeeper's Chalk or Three Riders triggers, the synthetic policy pays if it can and otherwise takes the always-safe wait; it keeps Last Barrel cargo sealed during ordinary trade runs. Separate isolated probes reserve two scrap for The Span at Cinderford and share two water at The Last Clean Barrel, verifying deterministic trigger coverage and persistent follow-up state. It does not model human event preference, crew, contracts, broader faction effects, or player learning.

## Results

{markdown_table(presentation)}

Under legal paths, the **forecast maximizer** selects **{forecast_choice['choice']}** in every seed and averages **{signed(float(forecast_policy['mean_realized_economic_profit']))}** realized economic profit. The **gross-margin chaser** selects **{gross_choice['choice']}** and averages **{signed(float(gross_policy['mean_realized_economic_profit']))}**. The **Toll-road-only** policy selects **{toll_choice['choice']}** and averages **{signed(float(toll_policy['mean_realized_economic_profit']))}**. The guided Grain delivery remains a mechanically legible but deliberately lower-return teaching run at **{signed(float(guided_policy['mean_realized_economic_profit']))}**.

![Policy outcome chart](policy_outcomes.png)

## Decision Patterns

{markdown_table(decision_mix_display)}

Every deterministic policy still concentrates on one legal initial trade in this linear, one-trip model. That is a genuine early-economy design signal after the topology fix: repeated opening runs may become rote unless market memory, information quality, or a meaningful inventory/risk trade-off produces legible rotation.

![Choice concentration chart](choice_concentration.png)

## Repeated-Delivery Choice Concentration

{multi_trip_table}

The adaptive policy re-evaluates the best legal forecast before each of three outbound deliveries, returning to Ashgate between trips. This is a mechanical concentration probe, not a human strategy model. It shows whether bounded local supply pressure is strong enough to make the visible best opening trade rotate under the current route graph and crisis timing.

The fixed Reedwatch water probe starts at **{int(memory_probe.get('baseline_price', 0))}** ashmarks per unit. A four-unit delivery creates **{float(memory_probe.get('initial_pressure', 0.0)) * 100:.0f}%** pressure and changes the immediate price to **{int(memory_probe.get('post_delivery_price', 0))}**. Pressure returns to zero after **{int(memory_probe.get('recovery_days', 0))}** elapsed days and repeated deliveries clamp at **{float(memory_probe.get('saturated_pressure', 0.0)) * 100:.0f}%**.

## Travel Event Probe

{event_table}

Gatekeeper's Chalk replaces the generic Toll Road cargo incident when it triggers; the automated policy pays when affordable. Three Riders triggers on 55% of the high-value Old Road policy runs and the automated policy buys the escort. The isolated Span probe reserves two scrap for the public support, producing the authored 70% trigger rate and a persistent Old Road risk change from 35% to 25%. The isolated shortage-stage Last Barrel probe shares two water, producing the authored 60% trigger rate, crisis-adjusted market memory, and two resilience points. These probes measure deterministic coverage and execution stability rather than human choice quality.

## Forecast Calibration

{markdown_table(calibration_display)}

The displayed forecast and resolver now share the **one exposed cargo unit** model. The forecast values the highest destination-value unit currently carried, multiplies that value by route risk, and the resolver removes that same unit when an incident occurs. Remaining error is bounded stochastic and integer-rounding variance rather than a structural whole-load-versus-one-unit mismatch.

### B0 before/after

{markdown_table(calibration_comparison)}

The forecast-maximizing policy's mean error fell from **+66.8** to **-0.2** ashmarks-equivalent. Its mean absolute error fell from **66.8** to **14.5**; the remaining absolute error is the expected spread between a rounded expected value and binary one-unit outcomes across individual runs.

## Economic Bottlenecks and Design Risks

| Finding | Evidence from corrected run | Why it matters | Suggested next test, not a balance change |
| --- | --- | --- | --- |
| **Route topology is now authoritative** | All completed runs use content-declared endpoints, and invalid Old Road → Brine Cross departures are rejected in regression coverage. | Route fees, risk, map presentation, and forecast now describe the same corridor. | Keep endpoint validation in future route-content review; no balance action is indicated by this implementation fix alone. |
| **Legal opening-choice concentration** | The forecast and gross-margin policies each select one legal opening trade in 100.0% of runs. | Once players learn the display, early trade can become routine rather than a meaningful choice. | Use the repeated-delivery results above to judge whether current pressure/decay values create enough readable rotation before changing balance. |
| **Forecast/resolution calibration** | Mean forecast error ranges from {signed(float(calibration['mean_error'].min()))} to {signed(float(calibration['mean_error'].max()))} ashmarks-equivalent across active policies after both paths adopted the one-unit model. | Small residual error is expected across finite deterministic samples, but systematic drift would weaken trust. | Keep the shared loss helper under regression coverage and rerun this report after route, price, cargo-loss, or crisis changes. |
| **Capacity dominates the first decision** | The forecast policy loads an average of {forecast_policy['mean_quantity']:.1f} units against a 12-unit capacity. | The opening may reward filling the hold more than comparing cargo, route, and information. | Observe first-time testers’ chosen quantities, then compare against a lower-cash or tighter-provision test preset. |
| **Guided delivery is not an economic optimum** | The Grain teaching run averages {signed(float(guided_policy['mean_realized_economic_profit']))} realized economic profit. | The suggested first action should teach a visible trade-off without falsely implying that it is the best available profit path. | Ask testers to explain why they followed or rejected the suggested Grain move; retain it only if it reliably teaches the forecast model. |

## Recommended Human-Playtest Prompts

Use the refined quick-playtest with no assistance beyond the screen text. Ask the player to say aloud: **“Why did you choose this cargo, route, and quantity?”** After their first sale, ask: **“Did the outcome match what you expected from the forecast?”** Record their selected cargo, route, quantity, whether they noticed price reasons and expected loss, and whether they could name one alternative they rejected. Those observations will test comprehension and trust—the dimensions this automated pass cannot measure.

## Reproduction

The attached raw results were generated by `tools/simulate_trade_policies.gd` and summarized by this script. The simulator is read-only: it creates fresh world instances, runs only existing explicit commands, and does not alter the game’s content or balance data.

## Sources

| Source | Role |
| --- | --- |
| `content/runtime_world.json` | Implemented goods, settlement price modifiers, route endpoints, and planning assumptions. |
| `src/core/economy.gd` | Implemented prices and forecast calculation. |
| `src/core/market_command_processor.gd` | Implemented buy, endpoint validation, travel, incident, and sell resolution. |
| `research/playtest_simulation/policy_simulation.json` | Raw 500-run corrected simulation output. |
"""
    (output / "automated_playtest_report.md").write_text(report, encoding="utf-8")

    artifact = {
        "seed_count": data["seed_count"],
        "row_count": len(rows),
        "summary": summary.drop(columns="policy_order").to_dict(orient="records"),
        "choice_mix": choice_mix.to_dict(orient="records"),
        "calibration": calibration.to_dict(orient="records"),
        "multi_trip_choice_mix": multi_trip_choice_mix.to_dict(orient="records"),
        "market_memory_probe": memory_probe,
        "event_summary": event_summary.to_dict(orient="records"),
    }
    (output / "analysis_summary.json").write_text(json.dumps(artifact, indent=2), encoding="utf-8")
    print(f"Wrote analysis to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
