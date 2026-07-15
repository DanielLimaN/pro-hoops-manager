extends Node

func _ready():
	print("=== TEST_SWAP START ===")
	
	# Create a mock _player_data_cache like team.gd
	var cache = [
		{pos = "PG", name = "Marcus Silva", ovr = 92},
		{pos = "SG", name = "João Pedro", ovr = 88},
		{pos = "SF", name = "Carlos Mendez", ovr = 86},
		{pos = "PF", name = "Anderson Costa", ovr = 85},
		{pos = "C", name = "Tyrone Walker", ovr = 83},
		{pos = "PG", name = "Lucas Almeida", ovr = 78},
		{pos = "SG", name = "Diego Ramos", ovr = 81},
		{pos = "SF", name = "Rafael Souza", ovr = 79},
		{pos = "PF", name = "Bruno Oliveira", ovr = 76},
		{pos = "C", name = "Pedro Henrique", ovr = 74},
	]
	
	print("Initial cache order:")
	for i in range(cache.size()):
		print("  [", i, "] ", cache[i].name)
	
	# Simulate right-click on player at index 0 (Marcus Silva)
	var source = cache[0]
	print("\nSource player: ", source.name)
	print("Source reference is same as cache[0]: ", source == cache[0])
	
	# Collect bench players
	var bench = []
	for p in cache:
		var p_idx = cache.find(p)
		if p_idx >= 5:
			bench.append(p)
	print("\nBench players:")
	for b in bench:
		print("  ", b.name)
	
	# Simulate swap: source (Marcus, idx=0) with target (Lucas, idx in bench)
	var target = null
	for b in bench:
		if b.pos == "PG":
			target = b
			break
	
	print("\nTarget player: ", target.name)
	print("Target reference is same as cache[5]: ", target == cache[5])
	
	# Execute swap (same logic as _execute_player_swap)
	var src_idx = cache.find(source)
	var tgt_idx = cache.find(target)
	print("\nsrc_idx: ", src_idx, " tgt_idx: ", tgt_idx)
	
	# Swap
	print("\nBEFORE swap: [", src_idx, "]=", cache[src_idx].name, " [", tgt_idx, "]=", cache[tgt_idx].name)
	cache[src_idx] = target
	cache[tgt_idx] = source
	print("AFTER swap:  [", src_idx, "]=", cache[src_idx].name, " [", tgt_idx, "]=", cache[tgt_idx].name)
	
	# Verify cache order
	print("\nCache order after swap:")
	for i in range(cache.size()):
		print("  [", i, "] ", cache[i].name)
	
	# Test find() after swap
	var test_src_idx = cache.find(source)
	var test_tgt_idx = cache.find(target)
	print("\nAfter swap: cache.find(source)=", test_src_idx, " cache.find(target)=", test_tgt_idx)
	print("source is cache[test_src_idx]: ", source == cache[test_src_idx])
	print("target is cache[test_tgt_idx]: ", target == cache[test_tgt_idx])
	
	# Test iteration (like _refresh_player_rows does)
	print("\nIterating over cache (like _refresh_player_rows):")
	for i in range(cache.size()):
		var d = cache[i]
		var idx = cache.find(d)
		print("  i=", i, " name=", d.name, " idx=", idx, " match=", (i == idx))
	
	print("\n=== TEST_SWAP PASSED ===")
	queue_free()
