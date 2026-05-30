@tool
extends SceneTree

func _init():
    print("Loading main.tscn...")
    var scene = load("res://gui/main.tscn")
    var root = scene.instantiate()
    var garage = root.get_node("CanvasLayer/TabContainer/Garage")
    
    var upg_row = garage.get_node("VBoxContainer/UpgradesRow")
    
    for panel in upg_row.get_children():
        var icon = panel.get_node("VBox/Icon")
        icon.custom_minimum_size = Vector2(100, 100)
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        
        var n_lower = panel.name.replace("Panel", "").to_lower()
        if n_lower == "tires":
            icon.texture = load("res://opona bez tla.png")
        elif n_lower == "suspension":
            icon.texture = load("res://sprezyna bez tla.png")
        elif n_lower == "engine":
            icon.texture = load("res://engine bez tla.png")
        elif n_lower == "nitro":
            icon.texture = load("res://benzyna bez tla.png")
        
    print("Packing main.tscn...")
    var packed = PackedScene.new()
    packed.pack(root)
    ResourceSaver.save(packed, "res://gui/main.tscn")
    
    # Also update garage.tscn background
    print("Updating garage.tscn background...")
    var gscene = load("res://scenes/planes/garage.tscn")
    var groot = gscene.instantiate()
    var spr = groot.get_node_or_null("Sprite2D")
    if spr:
        spr.texture = load("res://garage_bg_1780171716335.png")
        spr.scale = Vector2(1.5, 1.5)
        var gpacked = PackedScene.new()
        gpacked.pack(groot)
        ResourceSaver.save(gpacked, "res://scenes/planes/garage.tscn")
        
    print("UI Icons Updated.")
    quit()
