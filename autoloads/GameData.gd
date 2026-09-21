extends Node

var endings := {
	"model": {
		"title": "Model Sustainable Destination",
		"description": "SustainableIsland became a global example of tourism done right. Local businesses thrive, marine and forest ecosystems are protected, and visitors return year after year for the island's authentic beauty."
	},
	"overtourism": {
		"title": "Overtourism Boom",
		"description": "The economy boomed in the short term, but reefs are bleached, forests are thinning, and locals worry the island is losing what made it special. Growth outpaced the island's ability to sustain it."
	},
	"protected_poor": {
		"title": "Protected but Poor",
		"description": "The island's nature is pristine, but jobs are scarce and the economy struggled to grow. Conservation succeeded, but the local community needed more economic opportunity."
	},
	"failed": {
		"title": "Failed Destination",
		"description": "Neither the economy nor the environment fared well. Tourists stopped coming, businesses closed, and the island's natural resources were left degraded with little to show for it."
	}
}

var zones := [
	{
		"id": "hotel",
		"name": "Hotel Site",
		"sdg": "SDG 8 - Decent Work & Economic Growth",
		"decisions": [
			{"title": "Build Large Resort", "description": "A big resort chain wants to build here, bringing lots of jobs and revenue fast.", "economy": 15, "employment": 10, "environment": -10, "satisfaction": 5},
			{"title": "Build Eco-Lodge", "description": "A smaller, locally-run eco-lodge with sustainable design.", "economy": 8, "employment": 6, "environment": 2, "satisfaction": 4}
		]
	},
	{
		"id": "marine",
		"name": "Marine Reserve",
		"sdg": "SDG 14 - Life Below Water",
		"decisions": [
			{"title": "Open for Unrestricted Snorkel Tours", "description": "Let any operator run snorkel tours over the reef.", "economy": 10, "employment": 4, "environment": -12, "satisfaction": 3},
			{"title": "Establish Protected Marine Zone", "description": "Limit boat traffic and protect coral from damage.", "economy": 3, "employment": 2, "environment": 10, "satisfaction": 2}
		]
	},
	{
		"id": "forest",
		"name": "Forest",
		"sdg": "SDG 15 - Life on Land",
		"decisions": [
			{"title": "Log for Construction Materials", "description": "Clear forest to supply cheap building materials.", "economy": 8, "employment": 3, "environment": -15, "satisfaction": -2},
			{"title": "Create Eco-Trail & Conservation Area", "description": "Build a guided nature trail that protects the forest.", "economy": 4, "employment": 3, "environment": 8, "satisfaction": 5}
		]
	},
	{
		"id": "town",
		"name": "Town Center",
		"sdg": "SDG 8 & 12 - Work & Responsible Consumption",
		"decisions": [
			{"title": "Support Local Markets & Businesses", "description": "Fund local vendors and artisans to serve tourists.", "economy": 6, "employment": 8, "environment": 1, "satisfaction": 4},
			{"title": "Bring in Foreign Chain Retailers", "description": "Big-name retailers promise fast revenue.", "economy": 12, "employment": 2, "environment": -3, "satisfaction": -1}
		]
	},
	{
		"id": "waste",
		"name": "Waste Management",
		"sdg": "SDG 12 - Responsible Consumption & Production",
		"decisions": [
			{"title": "Invest in Recycling & Waste Systems", "description": "Build proper waste infrastructure for the island.", "economy": -4, "employment": 2, "environment": 9, "satisfaction": 3},
			{"title": "Minimal Waste Investment", "description": "Cut costs by doing the bare minimum.", "economy": 4, "employment": -1, "environment": -8, "satisfaction": -3}
		]
	}
]
