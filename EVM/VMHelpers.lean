-- EVM/VMHelpers.lean
-- Small utility helpers used across modules

namespace EVM.Helpers

/-- Basic conversion to 256-bit word modulo 2^256 -/
def toWord256 (n : Nat) : Nat := n % (2 ^ 256)

end EVM.Helpers
