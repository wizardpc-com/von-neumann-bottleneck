# Sol read-only ALU boundary audit

No blocking defect found. `arithmetic_content_pack.gd` formal32 cases checks CARRY
only for OP=2; other operations leave CARRY don't-care. Existing source directly
connects FullAdder.COUT to CARRY. ALU1/ALU4 simplified simulator matches that
contract; no new zero-gating decision is justified. ALU reuses actual library
FullAdder; ALU4 binds the player's ALU1 signature. Global save restoration checks
source level/kind/canonical circuit/dependency signatures and re-verifies official
cases. Root alone runs Git/engine/native UI; worker edited and ran nothing.
