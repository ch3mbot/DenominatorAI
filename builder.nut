import("pathfinder.rail", "RailPathFinder", 1);

class dBuilder
{
    root = null; // Reference to the AI instance

    root = null; // Reference to the AI instance
    crglist = null;
    crg = null; // The list of possible cargoes; The cargo selected to be transported
    srclist = null;
    src = null; // The list of sources for the given cargo; The source (StationID/TownID) selected
    dstlist = null;
    dst = null; // The list of destinations for the given source; The destination (StationID/TownID) selected

    srcistown = null;
    dstistown = null;
    srcplace = null;
    dstplace = null;

    constructor(that) {
        root = that;
    }
}

function dBuilder::ChooseIndustries()
{
	crglist = AICargoList();
	crglist.Valuate(AIBase.RandItem);
	// Choose a source
	foreach (icrg, dummy in crglist) {
		if (AICargo.GetTownEffect(icrg) != AICargo.TE_PASSENGERS && AICargo.GetTownEffect(icrg) != AICargo.TE_MAIL) {
			// If the source is an industry
			srclist = AIIndustryList_CargoProducing(icrg);
			// Should not be built on water
			srclist.Valuate(AIIndustry.IsBuiltOnWater);
			srclist.KeepValue(0);
			// There should be some production
			srclist.Valuate(AIIndustry.GetLastMonthProduction, icrg)
			srclist.KeepAboveValue(40);
			// Try to avoid excessive competition
			srclist.Valuate(dBuilder.GetLastMonthTransportedPercentage, icrg);
			srclist.KeepBelowValue(50);
			srcistown = false;
		}
        else
        {
            continue;
        }
		srclist.Valuate(AIBase.RandItem);
		foreach (isrc, dummy2 in srclist) {
			// Jump source if already serviced
			//if (root.serviced.HasItem(isrc * 256 + icrg)) continue;

			if (srcistown) srcplace = AITown.GetLocation(isrc);
			else srcplace = AIIndustry.GetLocation(isrc);
			if (AICargo.GetTownEffect(icrg) == AICargo.TE_NONE || AICargo.GetTownEffect(icrg) == AICargo.TE_WATER) {
				// If the destination is an industry
				dstlist = AIIndustryList_CargoAccepting(icrg);
				dstistown = false;
				dstlist.Valuate(AIIndustry.GetDistanceManhattanToTile, srcplace);
			} else {
				// If the destination is a town
				dstlist = AITownList();
				// Some minimum population values for towns
				switch (AICargo.GetTownEffect(icrg)) {
					case AICargo.TE_FOOD:
						dstlist.Valuate(AITown.GetPopulation);
						dstlist.KeepAboveValue(1000);
						break;
					case AICargo.TE_GOODS:
						dstlist.Valuate(AITown.GetPopulation);
						dstlist.KeepAboveValue(1500);
						break;
					default:
						dstlist.Valuate(AITown.GetLastMonthProduction, icrg);
						dstlist.KeepAboveValue(40);
						break;
				}
				dstistown = true;
				dstlist.Valuate(AITown.GetDistanceManhattanToTile, srcplace);
			}
			// Check the distance of the source and the destination
            dstlist.KeepBelowValue(200);
            dstlist.KeepAboveValue(60);
            if (AICargo.GetTownEffect(icrg) == AICargo.TE_MAIL) dstlist.KeepBelowValue(110);
			dstlist.Valuate(AIBase.RandItem);
			foreach (idst, dummy3 in dstlist) {
				if (dstistown)
					dstplace = AITown.GetLocation(idst);
				else dstplace = AIIndustry.GetLocation(idst);
				crg = icrg;
				src = isrc;
				dst = idst;
				return true;
			}
		}
	}
	return false;
}

/**
 * Builds a new rail line
 */
function dBuilder::BuildRailLineBetweenIndustries(industryA, industryB)
{
    this.SetRailType();
    local pathfinder = RailPathFinder();

    //get stations

    local tile_a = AIStation.GetLocation(st_a);
    local tile_b = AIStation.GetLocation(st_b);

	local rad = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);

    pathfinder.InitializePath([[tile_a, tile_a + AIMap.GetTileIndex(-1, 0)]], [[tile_b + AIMap.GetTileIndex(-1, 0), tile_b]]);
    local path = pathfinder.FindPath(-1);

    local prev = null;
    local prevprev = null;
    while (path != null) {
        if (prevprev != null) {
            if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
            if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
                AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev);
            } else {
                local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), prev) + 1);
                bridge_list.Valuate(AIBridge.GetMaxSpeed);
                bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
                AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), prev, path.GetTile());
            }
            prevprev = prev;
            prev = path.GetTile();
            path = path.GetParent();
            } else {
            AIRail.BuildRail(prevprev, prev, path.GetTile());
            }
        }
        if (path != null) {
            prevprev = prev;
            prev = path.GetTile();
            path = path.GetParent();
        }
    }
}

function dBuilder::BuildStation(is_source)
{
    local tilelist, otherplace, isneartown = null;
	local rad = AIStation.GetCoverageRadius(AIStation.STATION_TRAIN);
	// Determine the direction of the station, and get tile lists
	if (is_source) {
		if (srcistown) {
			tilelist = dBuilder.GetTilesAroundTown(src, 1, 1);
			isneartown = true;
		} else {
			tilelist = AITileList_IndustryProducing(src, rad);
			isneartown = false;
		}
		otherplace = dstplace;
	} else {
		if (dstistown) {
			tilelist = dBuilder.GetTilesAroundTown(dst, 1, 1);
			isneartown = true;
		} else {
			tilelist = AITileList_IndustryAccepting(dst, rad);
			tilelist.Valuate(AITile.GetCargoAcceptance, crg, 1, 1, rad);
			tilelist.RemoveBelowValue(8);
			isneartown = false;
		}
		otherplace = srcplace;
	}
	tilelist.Valuate(AITile.IsBuildable);
	tilelist.KeepValue(1);

    //sort list
    if (isneartown) {
		tilelist.Valuate(AITile.GetCargoAcceptance, crg, 1, 1, rad);
		tilelist.KeepAboveValue(10);
	} else {
		tilelist.Valuate(AIMap.DistanceManhattan, otherplace);
	}
	tilelist.Sort(AIList.SORT_BY_VALUE, !isneartown);
	local success = false;
    local stationID = 0;
	foreach (tile, dummy in tilelist) {
		// Find a place where the station can bee built

        local dx = AIMap.GetTileX(tile);
        local dy = AIMap.GetTileY(tile);

        if(!(dx > 0 && dy > 0 && dx < AIMap.GetMapSizeX() && dy < AIMap.GetMapSizeY()))
        {
            continue;
        }
        local rectCheckList = AITileList();
        rectCheckList.AddRectangle(tile, AIMap.GetTileIndex(dy + 10, dy + 10));
        if(this.CanFitSquareWithDims(rectCheckList, 11, 11))
        {
            AILog.Info("found rectangle at: [" + dx + ", " + dy + "]");
            success = true;
            break;
        }
	}
	if (!success) return false;

}

function dBuilder::CanFitSquareWithDims(tilelist, xdim, ydim)
{
    foreach (tile, dummy in tilelist)
    {
        if (!AITile.IsBuildable(tile)) return false;
    }

    return true;
}


/**
 * Sets the current rail type of the AI based on the maximum number of cargoes transportable.
 * Taken from SimpleAI
 */
function dBuilder::SetRailType()
{
	local railtypes = AIRailTypeList();
	local cargoes = AICargoList();
	local max_cargoes = 0;
	// Check each rail type for the number of available cargoes
	foreach (railtype, dummy in railtypes) {
		// Avoid the universal rail in NUTS and other similar ones
		local buildcost = AIRail.GetBuildCost(railtype, AIRail.BT_TRACK);
		if (buildcost > Banker.InflatedValue(2000)) continue;
		local current_railtype = AIRail.GetCurrentRailType();
		AIRail.SetCurrentRailType(railtype);
		local num_cargoes = 0;
		// Count the number of available cargoes
		foreach (cargo, dummy2 in cargoes) {
			if (dBuilder.ChooseWagon(cargo, null) != null) num_cargoes++;
		}
		if (num_cargoes > max_cargoes) {
			max_cargoes = num_cargoes;
			current_railtype = railtype;
		}
		AIRail.SetCurrentRailType(current_railtype);
	}
}

/**
 * Get the percentage of transported cargo from a given industry.
 * @param ind The IndustryID of the industry.
 * @param cargo The cargo to be checked.
 * @return The percentage transported, ranging from 0 to 100.
 */
function dBuilder::GetLastMonthTransportedPercentage(ind, cargo)
{
	local production = AIIndustry.GetLastMonthProduction(ind, cargo);
	if (production != 0)
		return (100 * AIIndustry.GetLastMonthTransported(ind, cargo) / production);
	else
		return 0;
}