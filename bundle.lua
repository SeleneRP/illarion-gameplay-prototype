local bundle = {}

bundle.id = "illarion"
bundle.name = "Illarion (Gameplay only)"

function bundle.init_server()
	require_all("illarion.server.item")
end

return bundle