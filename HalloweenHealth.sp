/*
##############################################
#	Credits for medi-pack spawning code:
#	TF2 Medi-packs by [NATO]Hunter
##############################################
*/
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.1.0"

new g_FilteredEntity = -1;

public Plugin:myinfo =
{
	name = "[TF2] Halloween Health Spawner",
	author = "DarthNinja",
	description = "Spawn Halloween themed health packs!",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
		RegAdminCmd("sm_halloweenhealth", MedickPax, ADMFLAG_BAN);

		CreateConVar("sm_halloweenhealth_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

		LoadTranslations("common.phrases");
}

public OnMapStart()
{
		PrecacheModel("models/props_halloween/halloween_medkit_large.mdl");
		PrecacheModel("models/props_halloween/halloween_medkit_medium.mdl");
		PrecacheModel("models/props_halloween/halloween_medkit_small.mdl");
}

public Action:MedickPax(client,args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_halloweenhealth <full / medium / small>");
		return Plugin_Handled;
	}
	if (client < 1)
	{
		ReplyToCommand(client, "This command must be used ingame");
		return Plugin_Handled;
	}
	decl String:buffer[128];
	GetCmdArg(1, buffer, sizeof(buffer));
	new size = 0

	if (StrEqual(buffer, "full", false))
	{
		ShowActivity2(client, "\x04[Halloween Health\x04]\x01 ","spawned a \x04Full\x01 health kit!", client);
		LogAction(client, -1, "[Halloween Health] %L spawned a Full health kit.", client);
		size = 3
		TF_SpawnMedipack(client, "item_healthkit_full", true, size);
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "medium", false))
	{
		ShowActivity2(client, "\x04[Halloween Health\x04]\x01 ","spawned a \x04Medium\x01 health kit!", client);
		LogAction(client, -1, "[Halloween Health] %L spawned a Medium health kit.", client);
		size = 2
		TF_SpawnMedipack(client, "item_healthkit_medium", true, size);
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "small", false))
	{
		ShowActivity2(client, "\x04[Halloween Health\x04]\x01 ","spawned a \x04Small\x01 health kit!", client);
		LogAction(client, -1, "[Halloween Health] %L spawned a Small health kit.", client);
		size = 1
		TF_SpawnMedipack(client, "item_healthkit_small", true, size);
		return Plugin_Handled;
	}

	ReplyToCommand(client, "Usage: sm_spawnmedipack <full / medium / small>");
	return Plugin_Handled;
}



stock bool:IsEntLimitReached()
{
	if (GetEntityCount() >= (GetMaxEntities()-64))
	{
		PrintToChatAll("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d", GetEntityCount(), GetMaxEntities());
		return true;
	}
	else
		return false;
}

public bool:MedipackTraceFilter(ent, contentMask)
{
	return (ent != g_FilteredEntity);
}

stock TF_SpawnMedipack(client, String:name[], bool:cmd, size)
{
	new Float:PlayerPosition[3];
	if (cmd)
	{
		GetClientAbsOrigin(client, PlayerPosition);
	}
	else
	{
		//PlayerPosition = g_MedicPosition[client];
	}

	if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 && IsEntLimitReached() == false)
	{
		PlayerPosition[2] += 4;
		g_FilteredEntity = client;
		if (cmd)
		{
			new Float:PlayerPosEx[3], Float:PlayerAngle[3], Float:PlayerPosAway[3];
			GetClientEyeAngles(client, PlayerAngle);
			PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[2] = 0.0;
			ScaleVector(PlayerPosEx, 75.0);
			AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);

			new Handle:TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID, RayType_EndPoint, MedipackTraceFilter);
			TR_GetEndPosition(PlayerPosition, TraceEx);
			CloseHandle(TraceEx);
		}

		new Float:Direction[3];
		Direction[0] = PlayerPosition[0];
		Direction[1] = PlayerPosition[1];
		Direction[2] = PlayerPosition[2]-1024;
		new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, MedipackTraceFilter);

		new Float:MediPos[3];
		TR_GetEndPosition(MediPos, Trace);
		CloseHandle(Trace);
		MediPos[2] += 4;

		new Medipack = CreateEntityByName(name);
		DispatchKeyValue(Medipack, "OnPlayerTouch", "!self,Kill,,0,-1");
		switch (size)
		{
			case 3:
				DispatchKeyValue(Medipack, "powerup_model", "models/props_halloween/halloween_medkit_large.mdl");
			case 2:
				DispatchKeyValue(Medipack, "powerup_model", "models/props_halloween/halloween_medkit_medium.mdl");
			case 1:
				DispatchKeyValue(Medipack, "powerup_model", "models/props_halloween/halloween_medkit_small.mdl");
		}
		if (DispatchSpawn(Medipack))
		{
			SetEntProp(Medipack, Prop_Send, "m_iTeamNum", 0, 4);
			TeleportEntity(Medipack, MediPos, NULL_VECTOR, NULL_VECTOR);
			EmitSoundToAll("items/spawn_item.wav", Medipack, _, _, _, 0.75);
		}
	}
}
