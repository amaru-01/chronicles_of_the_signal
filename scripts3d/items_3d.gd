class_name Items3D
extends RefCounted
## Item catalogue for the 3D game plus the passive upgrade effects. Items live in
## GameState.inventory (saved with the game); upgrades are just inventory items whose ids
## start with "upgrade_". Gameplay code asks this class for the effective numbers.

const ITEMS: Dictionary = {
	"fragment_01": {"name": "Memory Fragment I", "desc": "A rooftop at night. A face you almost know."},
	"fragment_02": {"name": "Memory Fragment II", "desc": "A server room. Your own hands, typing a command you cannot read."},
	"fragment_03": {"name": "Memory Fragment III", "desc": "A door sliding shut. You, younger, carrying a crate marked ARCHIVE."},
	"fragment_04": {"name": "Memory Fragment IV", "desc": "The Curator's voice, softer than you expect."},
	"fragment_05": {"name": "Memory Fragment V", "desc": "A market stall at dusk. A gift, wrapped in paper, for someone who never got anything."},
	"chip_market": {"name": "Market Datachip", "desc": "Sale records. The Curator bought one sentry for every voice it wanted quiet."},
	"upgrade_echo_core": {"name": "Echo Core", "desc": "Signal integrity slowly regenerates (+2 every 1.5 s)."},
	"chip_hub": {"name": "Plaza Datachip", "desc": "A cracked chip. A sketch of Vantage Plaza before the Signal went quiet: crowded, loud, alive."},
	"chip_static": {"name": "Static Row Datachip", "desc": "Courier logs from the alley. Every route ends at a gate that no longer opens."},
	"chip_archive": {"name": "Archive Datachip", "desc": "An index of deleted names. Yours is on it, written in your own hand."},
	"upgrade_pulse_core": {
		"name": "Pulse Core", "desc": "Hack pulse hits harder (+1 damage) and recharges faster (-0.3 s).",
	},
	"upgrade_strike_edge": {"name": "Strike Edge", "desc": "Melee strike deals +1 damage."},
	"upgrade_plating": {"name": "Hardened Plating", "desc": "Physical damage taken -25%."},
	"upgrade_signal_cell": {"name": "Signal Cell", "desc": "Signal integrity damage taken -30%."},
	"upgrade_phase_boots": {"name": "Phase Boots", "desc": "Move 15% faster."},
}

## Display order of the upgrades in the journal.
const UPGRADES: Array[String] = [
	"upgrade_pulse_core", "upgrade_strike_edge", "upgrade_plating", "upgrade_signal_cell", "upgrade_phase_boots",
	"upgrade_echo_core",
]


static func name_of(item_id: String) -> String:
	return str((ITEMS.get(item_id, {}) as Dictionary).get("name", item_id))


static func desc_of(item_id: String) -> String:
	return str((ITEMS.get(item_id, {}) as Dictionary).get("desc", ""))


static func owned(item_id: String) -> bool:
	return GameState.inventory.has(item_id)


# --- effective numbers ----------------------------------------------------------

static func pulse_damage() -> int:
	return 2 + (1 if owned("upgrade_pulse_core") else 0)


static func pulse_cooldown() -> float:
	return 0.9 - (0.3 if owned("upgrade_pulse_core") else 0.0)


static func strike_damage() -> int:
	return 1 + (1 if owned("upgrade_strike_edge") else 0)


static func speed_multiplier() -> float:
	return 1.15 if owned("upgrade_phase_boots") else 1.0


## Signal integrity restored per regeneration tick (every 1.5 s) with the Echo Core.
static func regen_per_tick() -> int:
	return 2 if owned("upgrade_echo_core") else 0


## Damage to HP after armour.
static func physical_damage(amount: int) -> int:
	return roundi(amount * 0.75) if owned("upgrade_plating") else amount


## Damage to signal integrity after the Signal Cell.
static func signal_damage(amount: int) -> int:
	return roundi(amount * 0.7) if owned("upgrade_signal_cell") else amount
