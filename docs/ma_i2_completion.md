# MA-I2 — Trade Fantasy Completion

**Completed:** 2026-09-02  
**Player behavior:** The guided opening now completes a profitable, contract-free trade circuit before introducing optional work: buy Ashgate Water, compare roads, survive the Old Road, sell into Reedwatch demand, load return Grain, come home, and sell again.

## What the first five minutes teach

1. **Demand and purchase:** Ashgate names the source, Reedwatch need, 15→32 unit spread, 60-ashmark purchase, projected 4/12 hold, and expected route-adjusted value before Buy is pressed.
2. **Commitment:** Departure compares every legal itinerary with fee, day, provisions, held load, gross value, risk, confidence, and expected net. Planning remains reversible.
3. **Consequence:** The Old Road and Three Riders decision interrupt travel; costs appear before the choice and arrival compares expected with realized state.
4. **Sale and market memory:** Selling four Water pays 128 ashmarks and shows `local unit 32 → 27 after supply`. The next market view explains that the player's delivery softened the price and that demand recovers over time.
5. **Return commerce:** Reedwatch Grain becomes a viable return load. The player travels back and sells it in Ashgate, proving a circuit rather than a mission payout.
6. **Optional authored work:** Only after ordinary trade closes the loop does the tutorial ask the player to compare the Job Board. Opening it advances the lesson; accepting a contract is never required.

## Deterministic acceptance

- The fresh campaign has no active or completed contract through both ordinary sales.
- Purchase feedback names cash spent and resulting capacity.
- Route forecast text names fee, provision use, and disclosed cargo risk.
- The Reedwatch sale creates an `ordinary_trade` market-delivery record and lowers the next local Water price.
- The receipt includes both pre-sale and post-sale unit prices.
- Tutorial version 2 persists the optional-work lesson and derives progress from authoritative command history, cargo, location, and presentation state.
- Legacy guided saves with completed relief still progress into return trade instead of becoming stuck.

## Evidence

| Beat | Screenshot |
|---|---|
| Buy where supply is strong | [Ashgate Water plan](visual_evidence/v0.14.0-ma-i2-trade-fantasy-2026-09-02/settlement-shop-1600x900.png) |
| Compare the committed road | [Departure itinerary comparison](visual_evidence/v0.14.0-ma-i2-trade-fantasy-2026-09-02/departure-desk-1600x900.png) |
| Sell where need is real | [Reedwatch before/after market receipt](visual_evidence/v0.14.0-ma-i2-trade-fantasy-2026-09-02/market-change-receipt-1600x900.png) |

## Verification

```text
Tutorial flow: PASS
Map UI smoke: PASS
Browser capture validation: PASS
Native UI captures: PASS (1600x900)
Native UI render validation: PASS
```

## Known limitation

This gate uses the existing code-native settlement and road art. MA-I3 owns the authored character/motif/audio pass, optional black-market beat, save-at-every-phase proof, and complete ending receipt capture.

## Next gate

**MA-I3 — Creative vertical:** turn this proven economic circuit into one memorable authored journey through persistent characters, audiovisual motifs, optional black-market pressure, and a terminal causal receipt.
