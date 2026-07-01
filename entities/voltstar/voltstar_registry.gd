extends Node
## Tracks alive [`Voltstar`] instances via registration on ready/exit_tree.[br]
## Lets [`Voltstar._move`] query nearby Voltstars without per-frame `get_nodes_in_group`.[br]
## Must be registered as an autoload in Project Settings → Autoload with name [code]VoltstarRegistry[/code].

var voltstars: Array[Node] = []

func register(v: Node) -> void:
	voltstars.append(v)

func unregister(v: Node) -> void:
	voltstars.erase(v)
