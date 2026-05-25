-- DP-1 owns workspaces 1-10, DP-2 owns workspaces 11-20.
-- This is required for wsaction.fish: floor((active_ws - 1) / 10) * 10 + slot
-- ensures Super+1 on DP-2 (e.g. active ws=13) → ws 11, not ws 1.
hl.workspace_rule({ workspace="1",  monitor="DP-1", default=true })
hl.workspace_rule({ workspace="2",  monitor="DP-1" })
hl.workspace_rule({ workspace="3",  monitor="DP-1" })
hl.workspace_rule({ workspace="4",  monitor="DP-1" })
hl.workspace_rule({ workspace="5",  monitor="DP-1" })
hl.workspace_rule({ workspace="6",  monitor="DP-1" })
hl.workspace_rule({ workspace="7",  monitor="DP-1" })
hl.workspace_rule({ workspace="8",  monitor="DP-1" })
hl.workspace_rule({ workspace="9",  monitor="DP-1" })
hl.workspace_rule({ workspace="10", monitor="DP-1" })

hl.workspace_rule({ workspace="11", monitor="DP-2", default=true })
hl.workspace_rule({ workspace="12", monitor="DP-2" })
hl.workspace_rule({ workspace="13", monitor="DP-2" })
hl.workspace_rule({ workspace="14", monitor="DP-2" })
hl.workspace_rule({ workspace="15", monitor="DP-2" })
hl.workspace_rule({ workspace="16", monitor="DP-2" })
hl.workspace_rule({ workspace="17", monitor="DP-2" })
hl.workspace_rule({ workspace="18", monitor="DP-2" })
hl.workspace_rule({ workspace="19", monitor="DP-2" })
hl.workspace_rule({ workspace="20", monitor="DP-2" })
