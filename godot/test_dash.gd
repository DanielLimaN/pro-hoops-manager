extends SceneTree
func _init():
    var scn = load("res://scenes/ui/dashboard/dashboard.tscn")
    if scn:
        var inst = scn.instantiate()
        print("INSTANTIATED SUCCESSFULLY")
    else:
        print("FAILED TO LOAD")
    quit()
