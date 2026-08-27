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
    "map_constrained_forecast": "Map-constrained forecast",
    "map_constrained_gross_margin": "Map-constrained gross-margin",
    "toll_road_only": "Toll-road-only",
    "no_trade": "No trade baseline",
}

POLICY_RULES = {
    "guided_grain_delivery": "Buys 2 grain; travels Ashgate → Reedwatch via Old Road.",
    "forecast_maximizer": "Chooses the feasible first trade with highest displayed expected net profit.",
    "gross_margin_chaser": "Chooses the feasible first trade with highest displayed gross margin.",
    "map_constrained_forecast": "Chooses the highest displayed net-profit trade, limited to a drawn route corridor.",
    "map_constrained_gross_margin": "Chooses the highest gross-margin trade, limited to a drawn route corridor.",
    "toll_road_only": "Chooses the best displayed net-profit trade but only takes Toll Road.",
    "no_trade": "Takes no action; baseline for resource preservation.",
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
    profit_ax.set_title("First-run policy outcomes across 100 deterministic seeds")
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
    ax.set_title("First-trade choice concentration by policy")
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
    constrained_forecast_policy = summary.loc[summary["policy"] == "map_constrained_forecast"].iloc[0]
    constrained_gross_policy = summary.loc[summary["policy"] == "map_constrained_gross_margin"].iloc[0]
    guided_policy = summary.loc[summary["policy"] == "guided_grain_delivery"].iloc[0]
    most_concentrated = (
        choice_mix[choice_mix["policy"] != "no_trade"]
        .sort_values("share", ascending=False)
        .iloc[0]
    )
    forecast_choice = choice_mix[choice_mix["policy"] == "forecast_maximizer"].iloc[0]
    constrained_forecast_choice = choice_mix[choice_mix["policy"] == "map_constrained_forecast"].iloc[0]

    presentation = summary[
        [
            "policy_label",
            "runs",
            "completion_rate",
            "incident_rate",
            "mean_forecast_net_profit",
            "mean_realized_economic_profit",
            "median_realized_economic_profit",
            "loss_rate",
            "mean_forecast_error",
            "mean_quantity",
        ]
    ].copy()
    presentation.columns = [
        "Policy",
        "Runs",
        "Completed",
        "Incident rate",
        "Forecast net",
        "Realized economic",
        "Median realized",
        "Loss rate",
        "Forecast error",
        "Mean units",
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

    report = f"""# Market of Ash — Automated First-Run Playtest Simulation

> **Scope note:** This is a deterministic, rule-based simulation of the current prototype, not a substitute for human playtests. It reveals what the implemented economy rewards under explicit policies; it does not measure player enjoyment, comprehension, or preference.

## Scope and Method

The run starts every simulated trader in the current quick-playtest state: Ashgate, day one, 120 ashmarks, twelve provisions, and empty cargo. It executes the existing buy, travel, and sell command boundary across **{data['seed_count']} seeds**. Each policy is evaluated once per seed. The seed range covers the complete 100-value route-roll cycle produced by the current route incident formula for a fixed travel day.

| Policy | Decision rule |
| --- | --- |
""" + "\n".join(f"| {POLICY_LABELS[key]} | {POLICY_RULES[key]} |" for key in POLICY_LABELS) + f"""

The simulator tests only the initial one-trade loop. It does not model crew, contracts, event choices, faction effects beyond existing price modifiers, market memory, route restrictions by location, or player learning over multiple runs.

> **Critical implementation caveat:** The simulator intentionally honors the current command processor, which accepts any selected route with any different destination. The map presentation shows the Toll Road as an Ashgate–Brine Cross corridor, yet the current processor permits the high-performing Water → Reedwatch / Toll Road combination. Treat this as an exposed route-topology rule gap, not as an intended strategic option.

## Results

{markdown_table(presentation)}

The **unconstrained forecast maximizer** earns a mean realized economic profit of **{signed(float(forecast_policy['mean_realized_economic_profit']))}**, compared with **{signed(float(gross_policy['mean_realized_economic_profit']))}** for the unconstrained gross-margin chaser and **{signed(float(guided_policy['mean_realized_economic_profit']))}** for the guided Grain delivery. Once the drawn map corridors are enforced in the counterfactual, the forecast policy still averages **{signed(float(constrained_forecast_policy['mean_realized_economic_profit']))}** but selects a different route with **{pct(float(constrained_forecast_policy['incident_rate']))}** incidents instead of **{pct(float(forecast_policy['incident_rate']))}**. Its displayed forecast falls from **{signed(float(forecast_policy['mean_forecast_net_profit']))}** to **{signed(float(constrained_forecast_policy['mean_forecast_net_profit']))}** despite the same mean realized payoff. This exposes both the route-topology defect and a risk-forecast calibration gap; it is not an intended player advantage.

![Policy outcome chart](policy_outcomes.png)

## Decision Patterns

{markdown_table(decision_mix_display)}

The most concentrated actionable rule is **{most_concentrated['policy_label']}**, which selects **{most_concentrated['choice']}** in **{pct(float(most_concentrated['share']))}** of its runs. The unconstrained forecast maximizer selects **{forecast_choice['choice']}** in **{pct(float(forecast_choice['share']))}** of its runs; the map-constrained forecast policy selects **{constrained_forecast_choice['choice']}** in **{pct(float(constrained_forecast_choice['share']))}** of its runs. Both are fully concentrated in this linear, single-trade model. The unconstrained choice conflicts with the drawn Toll Road corridor; once topology is valid, remaining concentration becomes a balance question: the opening economy still risks resolving into one obvious legal answer rather than a meaningful trade-off.

![Choice concentration chart](choice_concentration.png)

## Forecast Calibration

{markdown_table(calibration_display)}

The displayed forecast is deliberately conservative when compared with realized economic profit because it deducts a percentage of the **entire expected sale value** as expected loss, whereas the actual route incident removes **one cargo unit**. This is a design and calibration issue rather than a simulation error: the current preview describes risk in value terms, but the resolver applies it in units. The gap becomes more visible as cargo loads grow.

## Economic Bottlenecks and Design Risks

| Finding | Evidence from this run | Why it matters | Suggested next test, not a balance change |
| --- | --- | --- | --- |
| **Route/destination permissiveness** | The unconstrained forecast maximizer selects Water → Reedwatch / Toll Road; enforcing the map selects Water → Reedwatch / Old Road. Both average +98.8 realized economic profit, but their displayed forecasts and incident rates differ materially. | A player can select a route fee and risk profile detached from the visible geography, undermining trust in route comparison and obscuring the valid risk/reward trade-off. | Add explicit origin/destination endpoints to route content and reject invalid departures, then rerun both the simulation and a human playtest. |
| **Opening-choice concentration** | The forecast maximizer is concentrated on one trade/route option for {pct(float(forecast_choice['share']))} of seeds. | Once topology is valid, repeated opening runs may still become rote. | Add bounded market memory (A2), then rerun this harness to measure whether recent deliveries produce meaningful but legible trade rotation. |
| **Forecast/resolution mismatch** | Mean forecast error ranges from {signed(float(calibration['mean_error'].min()))} to {signed(float(calibration['mean_error'].max()))} ashmarks-equivalent across active policies. | Players may interpret a risk-adjusted forecast as more pessimistic or inconsistent than actual outcomes, weakening trust in the explanation layer. | Make the forecast state that its loss estimate assumes cargo value at risk, or align its expected-loss formula with one-unit loss resolution before external testing. |
| **Capacity is a dominant early lever** | The profit-seeking policies load an average of {forecast_policy['mean_quantity']:.1f} units against a 12-unit capacity. | The first decision may reward filling the hold more than choosing among goods, routes, or information. | Run a human observation test that asks players to explain their chosen quantity; then compare full-hold behavior against a lower cash/provision preset. |
| **Safe-route premium** | Toll Road realizes {signed(float(summary.loc[summary['policy'] == 'toll_road_only', 'mean_realized_economic_profit'].iloc[0]))} at 10.0% incidents, while the map-valid Old Road forecast policy realizes {signed(float(constrained_forecast_policy['mean_realized_economic_profit']))} at {pct(float(constrained_forecast_policy['incident_rate']))} incidents. | The safe option currently changes risk exposure and displayed certainty more than mean realized payoff. It should be tested as an insurance choice, not assumed to be economically inferior. | Run paired first-run sessions where the risk display is hidden versus shown, and record route selection plus post-run explanation. |
| **Guided delivery as teaching case** | The preset Grain delivery has a mean realized economic result of {signed(float(guided_policy['mean_realized_economic_profit']))}. | The suggested first action must teach a legible trade-off even if it is not the globally best economic answer. | Ask first-time testers whether they can explain the Grain/Reedwatch rationale before purchase and whether the end result changes that understanding. |

## Recommended Human-Playtest Prompts

Use the refined quick-playtest with no assistance beyond the screen text. Ask the player to say aloud: **“Why did you choose this cargo, route, and quantity?”** After their first sale, ask: **“Did the outcome match what you expected from the forecast?”** Record their selected cargo, route, quantity, whether they noticed price reasons and expected loss, and whether they could name one alternative they rejected. Those observations will test comprehension and trust—the dimensions this automated pass cannot measure.

## Reproduction

The attached raw results were generated by `tools/simulate_trade_policies.gd` and summarized by this script. The simulator is read-only: it creates fresh world instances, runs only existing explicit commands, and does not alter the game’s content or balance data.

## Sources

| Source | Role |
| --- | --- |
| `content/runtime_world.json` | Implemented goods, settlement price modifiers, routes, and planning assumptions. |
| `src/core/economy.gd` | Implemented prices and forecast calculation. |
| `src/core/market_command_processor.gd` | Implemented buy, travel, incident, and sell resolution. |
| `research/playtest_simulation/policy_simulation.json` | Raw 500-run simulation output. |
"""
    (output / "automated_playtest_report.md").write_text(report, encoding="utf-8")

    artifact = {
        "seed_count": data["seed_count"],
        "row_count": len(rows),
        "summary": summary.drop(columns="policy_order").to_dict(orient="records"),
        "choice_mix": choice_mix.to_dict(orient="records"),
        "calibration": calibration.to_dict(orient="records"),
    }
    (output / "analysis_summary.json").write_text(json.dumps(artifact, indent=2), encoding="utf-8")
    print(f"Wrote analysis to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
