extends Node

signal time_advanced(progress: float)
signal match_updated(match_data: Dictionary)
signal kpi_updated(kpi_id: String, value: String)
signal inbox_received(message_data: Dictionary)
signal navigation_requested(route: String)
signal advance_simulation_requested(target: Dictionary)
signal date_updated(date_data: Dictionary)
signal day_completed(summary: Dictionary)
signal stats_updated(stats: Dictionary)
signal simulation_complete
signal match_found(match_data: Dictionary)
