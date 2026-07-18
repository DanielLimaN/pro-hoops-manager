
extends Node

# Autoload reference

# === SURFACES ===
const BG_APP := Color("#06030E")
const BG_TOPBAR := Color("#0B0514")
const BG_SIDEBAR := Color("#0B0514")
const BG_SURFACE := Color("#0F0720")
const BG_SURFACE_ALT := Color("#150826")
const BG_ELEVATED := Color("#1A0B2E")

# === BORDERS ===
const BORDER_SUBTLE := Color("#1F1432")
const BORDER_DEFAULT := Color("#2D1B4E")
const BORDER_ACCENT := Color("#A78BFA")
const BORDER_ACCENT_SOFT := Color("#A78BFA66")
const BORDER := Color("#1F1432") # Re-mapping from team.gd

# === BRAND ===
const BRAND := Color("#A78BFA")
const BRAND_PRIMARY := Color("#A78BFA")
const BRAND_SOFT := Color("#A78BFA22")
const BRAND_ACCENT := Color("#A78BFA66")
const BRAND_DEEP := Color("#7C3AED")
const BRAND_DARK := Color("#5B21B6")

# === SEMANTIC ===
const SUCCESS := Color("#10B981")
const WARNING := Color("#FBBF24")
const WARNING_DARK := Color("#F59E0B")
const DANGER := Color("#EF4444")
const INFO := Color("#60A5FA")
const HIGHLIGHT := Color("#F472B6")

# === TEXT ===
const TEXT := Color("#FFFFFF")
const TEXT_SEC := Color("#E0E7FF")
const TEXT_MUTED := Color("#94A3B8")
const TEXT_DISABLED := Color("#6B5B95")

# === TYPOGRAPHY ===
var FONT_INTER: Font
var FONT_INTER_BOLD: Font
var FONT_INTER_EXTRABOLD: Font
var FONT_INTER_BLACK: Font

func _init():
	FONT_INTER = _make_font(500)
	FONT_INTER_BOLD = _make_font(700)
	FONT_INTER_EXTRABOLD = _make_font(800)
	FONT_INTER_BLACK = _make_font(900)

func _make_font(weight: int) -> Font:
	var sf = SystemFont.new()
	sf.font_names = PackedStringArray(["Inter", "Helvetica Neue", "Arial", "sans-serif"])
	sf.font_weight = weight
	return sf

# === LAYOUT ===
const SIDEBAR_WIDTH := 240
const TOP_BAR_HEIGHT := 64
const CONTENT_PADDING := 20
const CARD_GAP := 16
