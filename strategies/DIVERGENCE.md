# Divergence from Strategies

When a guideline for language X can't follow a strategy, the divergence is
recorded **in the guideline file**, not in the strategy.

This keeps divergence visible where it matters — in the guideline that actually
diverges — rather than hidden in the strategy file where someone implementing
the guideline might never see it.

## Format

Add this block to `divergences.md` in the same directory as the guideline:

```
DIVERGES FROM: [Strategy Name]
STEP: [N] ("[quoted strategy step text]")  ← optional; include when
diverging at the guideline level to tie the divergence to a specific step.
REASON: [Why — language limitation, ecosystem convention, or better
alternative exists.]
APPROACH: [What we do instead and why it still serves the principle.]
```

## Example

```
## Parameterized Test Functions
DIVERGES FROM: Data-Driven Test Cases
REASON: Python's pytest parametrize decorator iterates at collection
time, not inside a single test body. The framework handles isolation
differently from the strategy's step 5.
APPROACH: Use @pytest.mark.parametrize with tuple data. Each parameter
set becomes a distinct test node — isolation is provided by the
framework, not by the test body. The principle (No Conditional Test
Logic) is still served: no branching in test code, each case fails
independently.
```

## When to diverge

Divergence is not failure. It means the language or ecosystem has a different
path to the same principle. Valid reasons to diverge:

- **Language limitation.** The strategy assumes a capability the language
  doesn't have (e.g., subtests, first-class functions, generics).
- **Ecosystem convention.** The language community has a strong, well-tested
  convention that achieves the same outcome differently.
- **Better alternative.** A language-specific approach serves the principle
  more effectively than the general strategy would.

## When NOT to diverge

- **Convenience.** "It's easier to just..." is not divergence, it's skipping
  the strategy. If the strategy applies, follow it.
- **Unfamiliarity.** Not knowing how to apply the strategy in language X is
  a research task, not a divergence.
- **Partial application.** If you can follow most of the strategy but not one
  step, adapt that step rather than diverging from the whole strategy.