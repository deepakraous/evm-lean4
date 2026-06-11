import Lake
open Lake DSL

package "evm" where
  version := (0, 1, 0)
  precompileModules := true

@[default_target]
lean_lib EVM where
  globs := [include_glob "EVM/**"]
