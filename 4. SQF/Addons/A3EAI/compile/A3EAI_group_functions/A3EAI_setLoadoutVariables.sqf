private ["_unitType", "_unitGroup", "_loadout", "_weapon", "_magazine", "_useLaunchers", "_maxLaunchers", "_unitLevel", "_launchWeapon", "_launchAmmo"];

_unitGroup = _this select 0;
_unitType = _this select 1;
_unitLevel = _this select 2;

if !(_unitType in ["uav","ugv"]) then {
	_useLaunchers = if !(A3EAI_launcherLevelReq isEqualTo -1) then {((count A3EAI_launcherTypes) > 0) && {(_unitLevel >= A3EAI_launcherLevelReq)}} else {false};
	_unitGroup setVariable ["LootPool",[]];
	_unitGroup spawn A3EAI_generateLootPool;

	//Air units only: Replace backpack with parachute
	if (_unitType in ["air","aircustom"]) then {
		{
			if !((backpack _x) isEqualTo "B_Parachute") then {
				_x addBackpack "B_Parachute";
			};
		} forEach (units _unitGroup);
		if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Debug: Unit backpacks replaced with B_Parachute for %1 group %2.",_unitType,_unitGroup]};
	};

	//Set up individual group units
	{
		_loadout = _x getVariable "loadout";
		if (isNil "_loadout") then {
			_weapon = primaryWeapon _x;
			_magazine = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines") select 0;
			_loadout = [[_weapon],[_magazine]];
			_x setVariable ["loadout",_loadout];
		};
		
		if (_useLaunchers) then {
			_maxLaunchers = (A3EAI_launchersPerGroup min _unitLevel);
			if (_forEachIndex < _maxLaunchers) then {
				_launchWeapon = A3EAI_launcherTypes call A3EAI_selectRandom;
				_launchAmmo = getArray (configFile >> "CfgWeapons" >> _launchWeapon >> "magazines") select 0;
				_x addMagazine _launchAmmo; 
				_x addWeapon _launchWeapon; 
				(_loadout select 1) pushBack _launchAmmo;
				(_loadout select 0) pushBack _launchWeapon;
				if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Debug: Modified unit %1 loadout to %2.",_x,_loadout];};
			};
		};

		if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Debug: %1 Unit %2 loadout: %3. unitLevel %4.",_unitType,_x,_x getVariable ["loadout",[]],_unitLevel];};
	} forEach (units _unitGroup);
};

true