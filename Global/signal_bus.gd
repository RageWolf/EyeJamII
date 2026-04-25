# SignalBus.gd (Autoload)
extends Node

@warning_ignore("unused_signal")
signal system_broken(position: Vector3, power_system)
@warning_ignore("unused_signal")
signal system_fixed(power_system)
@warning_ignore("unused_signal")
signal feed_started
@warning_ignore("unused_signal")
signal feed_cancelled
@warning_ignore("unused_signal")
signal screen_shake(intensity: float)
@warning_ignore("unused_signal")
signal update_anim
