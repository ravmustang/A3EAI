#define RADIO_ITEM "EpochRadio0"
#define PLAYER_UNITS "Epoch_Male_F","Epoch_Female_F"

private ["_unitGroup","_canCall","_vehicle","_detectStartPos","_searchLength"];
_unitGroup = _this select 0;

if (_unitGroup getVariable ["EnemiesIgnored",false]) then {[_unitGroup,"Behavior_Reset"] call A3EAI_forceBehavior};

_vehicle = _unitGroup getVariable ["assignedVehicle",objNull];
_canCall = true;
_searchLength = _unitGroup getVariable "SearchLength";
if (isNil "_searchLength") then {_searchLength = (waypointPosition [_unitGroup,0]) distance (waypointPosition [_unitGroup,1]);};
if (_vehicle isKindOf "Plane") then {_searchLength = _searchLength * 2;};

if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Debug: Group %1 %2 detection started with search length %3.",_unitGroup,(typeOf (_vehicle)),_searchLength];};

if ((diag_tickTime - (_unitGroup getVariable ["UVLastCall",-A3EAI_UAVCallReinforceCooldown])) > A3EAI_UAVCallReinforceCooldown) then {
	_detectStartPos = getPosATL _vehicle;
	_vehicle flyInHeight (60 + (random 30));
	
	while {!(_vehicle getVariable ["vehicle_disabled",false]) && {(_unitGroup getVariable ["GroupSize",-1]) > 0} && {local _unitGroup}} do {
		private ["_detected","_vehPos","_nearNoAggroAreas","_playerPos","_canReveal"];
		_vehPos = getPosATL _vehicle;
		_canReveal = !((combatMode _unitGroup) isEqualTo "BLUE");
		_detected = (getPosATL _vehicle) nearEntities [[PLAYER_UNITS,"LandVehicle"],300];
		if ((count _detected) > 5) then {_detected resize 5};
		_nearNoAggroAreas = if (_detected isEqualTo []) then {[]} else {nearestLocations [_vehPos,["A3EAI_NoAggroArea"],1500]};
		{
			_playerPos = getPosATL _x;
			if ((isPlayer _x) && {({if (_playerPos in _x) exitWith {1}} count _nearNoAggroAreas) isEqualTo 0}) then {
				if (((lineIntersectsSurfaces [(aimPos _vehicle),(eyePos _x),_vehicle,_x,true,1]) isEqualTo []) && {A3XAI_UAVDetectChance call A3XAI_chance}) then {
					if (_canCall) then {
						if (isDedicated) then {
							_nul = [_playerPos,_x,_unitGroup getVariable ["unitLevel",0]] spawn A3EAI_spawn_reinforcement;
						} else {
							A3EAI_spawnReinforcements_PVS = [_playerPos,_x,_unitGroup getVariable ["unitLevel",0]];
							publicVariableServer "A3EAI_spawnReinforcements_PVS";
						};
						_unitGroup setVariable ["UVLastCall",diag_tickTime];
						_canCall = false;
					};
					if (_canReveal && {(_unitGroup knowsAbout _x) < 2}) then {
						_unitGroup reveal [_x,2.5]; 
						if (({if (RADIO_ITEM in (assignedItems _x)) exitWith {1}} count (units (group _x))) > 0) then {
							[_x,[41+(floor (random 5)),[_unitGroup,[configFile >> "CfgVehicles" >> (typeOf _vehicle),"displayName",""] call BIS_fnc_returnConfigEntry]]] call A3EAI_radioSend;
						};
					};
				};
			};
			uiSleep 0.1;
		} forEach _detected;
		if (((_vehicle distance _detectStartPos) > _searchLength) or {_vehicle getVariable ["vehicle_disabled",false]}) exitWith {};
		uiSleep 15;
	};
	
	_vehicle flyInHeight (125 + (random 25));
};
if (A3EAI_debugLevel > 1) then {diag_log format ["A3EAI Debug: Group %1 %2 detection end.",_unitGroup,(typeOf (_vehicle))];};
