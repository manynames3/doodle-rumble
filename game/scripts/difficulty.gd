extends RefCounted
## Player-selected pace layered over the six chapter-specific AI profiles.
const EASY := 0
const MEDIUM := 1
const HARD := 2
const NAMES := ["Easy", "Medium", "Hard"]
## v0.6.1's Medium and Hard readiness rates are the reference. The selected
## gains multiply attack readiness and hazard cadence. v0.6.3 adds another
## 30% to Hard hazard cadence, without shortening any attack warning.
const PRESSURE_GAINS := [1.0, 1.20, 1.50]
const V061_REST_FACTORS := [1.0, 0.86, 0.72]
const V061_HAZARD_FACTORS := [1.0, 0.82, 0.68]
const REST_FACTORS := [1.0, 0.86 / 1.20, 0.72 / 1.50]
const THINK_FACTORS := [1.0, 0.90, 0.80]
const MOVE_FACTORS := [1.0, 1.06, 1.12]
const HAZARD_FACTORS := [1.0, 0.82 / 1.20, 0.68 / 1.50 / 1.30]

static func valid_level(value: Variant) -> bool:
	return value is int and value >= EASY and value <= HARD

static func normalized_level(value: int) -> int:
	return clampi(value, EASY, HARD)

static func rest_factor(level: int) -> float:
	return REST_FACTORS[normalized_level(level)]

static func think_factor(level: int) -> float:
	return THINK_FACTORS[normalized_level(level)]

static func move_factor(level: int) -> float:
	return MOVE_FACTORS[normalized_level(level)]

static func hazard_interval(base_seconds: float, level: int) -> float:
	# Existing hazard zones and full warnings remain untouched. The lower bound
	# leaves time for the longest warning, active window, and another dodge.
	return maxf(3.6 / 1.30 if normalized_level(level) == HARD else 3.6, base_seconds * HAZARD_FACTORS[normalized_level(level)])

static func opening_hazard_delay(level: int) -> float:
	return hazard_interval(8.0, level)
