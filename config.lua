Config                            	= {}
Config.DrawDistance               = 100.0
Config.MarkerType                 = 1
Config.MarkerSize                 = { x = 1.5, y = 1.5, z = 1.0 }
Config.MarkerColor                = { r = 50, g = 50, b = 204 }

Config.MaxInService               = 15
Config.EnablePlayerManagement     = true
Config.EnableSocietyOwnedVehicles = false
Config.Locale                     = 'fr'

Config.Delays = {
	Ingredients = 1000 * 2,
	Fermentation = 1000 * 2,
	Conditionnement = 1000 * 2
}

Config.Items = {
	biere = 30,
}

Config.Zones = {
	Brasseur = {

		Blip = {
			Coords 	= vector3(1966.96, 4634.13, 40.6),
			Sprite 	= 499,
			Display = 4,
			Scale  	= 0.6,
			Colour 	= 5,
			Name	= _U("map_blip"),
		},

		Ingredients = {
			vector3(94.01, 6356.10, 31.37),
			Coords 	= vector3(94.01, 6356.10, 31.37),
			Sprite 	= 499,
			Display = 4,
			Scale  	= 0.6,
			Colour 	= 5,
			Name	= _U("ingredients")
		},

		Fermentation = {
			vector3(1442.49, 6331.86, 23.98), 
			Coords 	= vector3(1442.49, 6331.86, 23.98),
			Sprite 	= 499,
			Display = 4,
			Scale  	= 0.6,
			Colour 	= 5,
			Name	= _U("fermentation"),
		},

		Conditionnement = {
			vector3(2360.89, 3133.78, 48.20),
			Coords 	= vector3(2360.89, 3133.78, 48.20),
			Sprite 	= 499,
			Display = 4,
			Scale  	= 0.6,
			Colour 	= 5,
			Name	= _U("Conditionnement"),
		},
		
		Vente = {
			vector3(-303.84, 6285.81, 31.60),
			Coords 	= vector3(-303.84, 6285.81, 31.60),
			Sprite 	= 499,
			Display = 4,
			Scale  	= 0.6,
			Colour 	= 5,
			Name	= _U("delivery_point"),
		},

		Cloakroom = {
			vector3(1966.96, 4634.13, 41.10),
			Coords 	= vector3(1966.96, 4634.13, 41.10),
			Sprite 	= 499,
			Display = 4,
			Scale  	= 0.6,
			Colour 	= 5,
			Name	= _U("Cloakroom"),
		},

		Vehicles = {
			{
				Spawner = vector3(1956.31, 4649.98, 40.732),
				SpawnPoints = {
					{ coords = vector3(1956.89, 4644.55, 40.97), heading = 120.26, radius = 6.0 },
				}
			},
		},

		VehicleDeleters = {
			vector3(1943.4, 4629.4, 40.50),
		},
	}
}

Config.AuthorizedVehicles = {
	Shared = {
		{
			model = 'rumpo3',
			label = 'Véhicule de travail'
		},
	},

}