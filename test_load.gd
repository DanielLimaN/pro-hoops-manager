extends SceneTree

func _init():
    var s1 = load("res://scenes/ui/components/substitution_submenu.tscn")
    if s1:
        print("Submenu: OK")
        var i1 = s1.instantiate()
        print("Submenu instanciado com sucesso")
    else:
        print("Erro no Submenu")
        
    var s2 = load("res://scenes/ui/components/substitution_candidate_row.tscn")
    if s2:
        print("CandidateRow: OK")
        var i2 = s2.instantiate()
        print("Row instanciada com sucesso")
    else:
        print("Erro no CandidateRow")

    quit()
