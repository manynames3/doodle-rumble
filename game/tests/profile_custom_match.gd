extends SceneTree
## Actual main-scene frame profile. Run with a separate --isolated-qa profile
## using a native renderer; headless timing omits the custom-art GPU path.
const DT := 1.0 / 60.0
var game: Node2D
var view: SubViewport

func _initialize() -> void:
    root.hide()
    call_deferred("run")

func make_record(label: String, detail_count: int, color: String) -> Dictionary:
    var record: Dictionary = root.get_node("Doodles").new_record()
    record.name = label
    record.color = color
    record.kit = "bat"
    var strokes: Array = record.strokes
    var parts := ["head", "body", "left_arm", "right_arm", "left_leg", "right_leg"]
    var centers := [Vector2(256, 104), Vector2(256, 236), Vector2(188, 245), Vector2(324, 245), Vector2(220, 375), Vector2(292, 375)]
    for i in detail_count:
        var part_idx := i % parts.size()
        var center: Vector2 = centers[part_idx] + Vector2(float((i / 6) % 12) * 3.0 - 18.0, float((i / 72) % 6) * 4.0 - 12.0)
        var points: Array = []
        for j in 20:
            points.append([center.x + float(j) * 0.8, center.y + sin(float(j) * 0.5 + float(i)) * 2.0])
        strokes.append({"part":parts[part_idx], "color":color, "width":3.0, "points":points, "detail":true})
    record.strokes = strokes
    return record

func measure(label: String, ids: Array, frames: int) -> void:
    game.mode = "local"
    game.selected = ids
    game.arena_kind = "desktop"
    game.optional_hazards = false
    if "--warm-cache" in OS.get_cmdline_user_args() and ids[0] not in ["orange","blue"]:
        game.selection_tab = "custom"
        game.open_selection("local")
        for frame in 150: await process_frame
    var setup_started := Time.get_ticks_usec()
    game.start_match()
    var setup_ms := float(Time.get_ticks_usec()-setup_started)/1000.0
    game.countdown = 0.0
    if "--freeze-hud" in OS.get_cmdline_user_args():
        for child in game.ui.get_children():
            if child is Node2D and child.has_method("pose"):
                child.preview = false
    var total: Array[float] = []
    var late: Array[float] = []
    var simulation: Array[float] = []
    var draw_calls: Array[float] = []
    var entry_frames: Array[float] = []
    for frame in frames + 20:
        if frame % 20 == 0: print("PROFILE_PROGRESS ",label," frame=",frame)
        var begin := Time.get_ticks_usec()
        game._physics_process(DT)
        var after_sim := Time.get_ticks_usec()
        await process_frame
        # Frame draw synchronizes through the native loop.
        var elapsed_ms := float(Time.get_ticks_usec() - begin) / 1000.0
        if frame < 20:
            entry_frames.append(elapsed_ms)
        if frame >= 20:
            total.append(elapsed_ms)
            if frame >= 120: late.append(elapsed_ms)
            simulation.append(float(after_sim - begin) / 1000.0)
            draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    print("PROFILE_DONE ",label)
    total.sort()
    late.sort()
    simulation.sort()
    draw_calls.sort()
    var sum := 0.0
    for sample in total: sum += sample
    print("MATCH_PROFILE %s frames=%d mean_ms=%.3f median_ms=%.3f p95_ms=%.3f max_ms=%.3f simulation_median_ms=%.3f simulation_p95_ms=%.3f draw_calls_median=%.0f" % [label,frames,sum / frames,total[frames/2],total[int(frames*0.95)],total[-1],simulation[frames/2],simulation[int(frames*0.95)],draw_calls[frames/2]])
    print("MATCH_STEADY %s frames=%d median_ms=%.3f p95_ms=%.3f max_ms=%.3f" % [label,late.size(),late[late.size()/2],late[int(late.size()*0.95)],late[-1]])
    entry_frames.sort()
    print("MATCH_ENTRY %s setup_ms=%.3f first_frame_p95_ms=%.3f peak_ms=%.3f" % [label,setup_ms,entry_frames[int(entry_frames.size()*0.95)],entry_frames[-1]])

func run() -> void:
    if not "--isolated-qa" in OS.get_cmdline_user_args():
        push_error("Isolated QA required")
        quit(1)
        return
    await process_frame
    view = SubViewport.new()
    view.size = Vector2i(1280,720)
    view.disable_3d = true
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    game = load("res://scenes/main.tscn").instantiate()
    view.add_child(game)
    game.test_mode = true
    game.set_process(false)
    game.set_physics_process(false)
    await process_frame
    var library := root.get_node("Doodles")
    var light_a: String = library.save_record(make_record("Profile light A",45,"#f4a343"))
    var light_b: String = library.save_record(make_record("Profile light B",45,"#68c6d9"))
    var dense_a: String = library.save_record(make_record("Profile dense A",300,"#f4a343"))
    var dense_b: String = library.save_record(make_record("Profile dense B",300,"#68c6d9"))
    if light_a.is_empty() or light_b.is_empty() or dense_a.is_empty() or dense_b.is_empty():
        push_error("Could not save isolated records")
        quit(1)
        return
    print("PROFILE_ENV ", OS.get_processor_name()," ", DisplayServer.get_name()," ",RenderingServer.get_video_adapter_name())
    if not "--stress-only" in OS.get_cmdline_user_args():
        await measure("originals",["orange","blue"],300)
        await measure("two_51_stroke_drawings",[light_a,light_b],300)
        await measure("two_306_stroke_drawings",[dense_a,dense_b],300)
    if "--stress" in OS.get_cmdline_user_args() or "--stress-only" in OS.get_cmdline_user_args():
        var stress_a: String = library.save_record(make_record("Profile stress A",900,"#f4a343"))
        var stress_b: String = library.save_record(make_record("Profile stress B",900,"#68c6d9"))
        if stress_a.is_empty() or stress_b.is_empty():
            push_error("Could not save stress-test records")
            quit(1)
            return
        await measure("two_906_stroke_drawings",[stress_a,stress_b],300)
    game.queue_free()
    view.queue_free()
    root.get_node("Sound").shutdown()
    await process_frame
    quit(0)
