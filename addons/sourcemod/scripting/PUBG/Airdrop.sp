void SendAirDrop(float Location[3])
{
	Location[2] += 256; // Bu kısmı arttırınca Timerin süresini de arttırmak gerekiyor
	int airdrop = CreateEntityByName("prop_physics_multiplayer");
	DispatchKeyValue(airdrop, "model", "models/props/de_nuke/hr_nuke/metal_crate_001/metal_crate_001_76_low.mdl");
	DispatchKeyValue(airdrop, "overridescript", /*"inertia,1,damping,0"*/"inertia,1");
	DispatchKeyValue(airdrop, "physicsmode", "1");
	DispatchKeyValue(airdrop, "nodamageforces", "1");
	DispatchKeyValue(airdrop, "spawnflags", "2");
	SetEntProp(airdrop, Prop_Send, "m_CollisionGroup", 1);
	SetEntPropString(airdrop, Prop_Data, "m_iName", "airdrop");
	DispatchSpawn(airdrop);
	TeleportEntity(airdrop, Location, NULL_VECTOR, NULL_VECTOR);
	if (IsValidEntity(airdrop))
	{
		SDKHook(airdrop, SDKHook_StartTouch, AirDrop_Touch);
		SetEntityGravity(airdrop, 0.1);
	}
	SetEntityRenderColor(airdrop, 255, 87, 51, 255);
	SetCvar("sv_turbophysics", 1);
	CreateTimer(3.0, OnTheGround, airdrop, TIMER_FLAG_NO_MAPCHANGE);
}

public Action AirDrop_Touch(int entity, int client)
{
	if (!(0 < client <= MaxClients) || GetClientTeam(client) != CS_TEAM_T)
		return;
	if(GetEntitiesDistance(client, entity) < 50.0)
	{
		float origin[3];
		GetClientAbsOrigin(client, origin);
		origin[2] += 150.0;
		TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action OnTheGround(Handle timer, int entity)
{
	SDKUnhook(entity, SDKHook_StartTouch, AirDrop_Touch);
	SetCvar("sv_turbophysics", 0);
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	if (basladi)
	{
		//İlk E basışı
		if (!(g_iPlayerPrevButtons[client] & IN_USE) && iButtons & IN_USE)
		{
			int ent = GetClientAimTarget(client, false);
			if (IsValidEntity(ent))
			{
				if (GetEntitiesDistance(client, ent) < 82.0)
				{
					char sName[32];
					GetEntPropString(ent, Prop_Data, "m_iName", sName, sizeof(sName));
					if (StrContains(sName, "airdrop") != -1)
					{
						if (StrEqual(sName, "airdrop"))
						{
							SetProgressBar(client, g_AirDrops_Time.IntValue);
							client_airdrop[client] = ent;
							airdrop_timer[client] = CreateTimer(g_AirDrops_Time.FloatValue, airdropac, client, TIMER_FLAG_NO_MAPCHANGE);
							g_OnceStopped[client] = true;
						}
						else if (StrEqual(sName, "bos_airdrop"))
							PrintCenterText(client, "[PUBG] Bu airdrop boş!");
					}
				}
			}
		}
		//E'ye basılı tutarken
		else if (iButtons & IN_USE)
		{
			if (client_airdrop[client] != -1)
			{
				int ent = GetClientAimTarget(client, false);
				if (ent == client_airdrop[client])
				{
					char sName[33];
					GetEntPropString(ent, Prop_Data, "m_iName", sName, sizeof(sName));
					if (StrEqual(sName, "bos_airdrop"))
					{
						ResetProgressBar(client);
						PrintCenterText(client, "[PUBG] Bir oyuncu bu drobu senden önce boşalttı!");
						airdrop_timer[client] = null;
						client_airdrop[client] = -1;
					}
				}
				else
				{
					client_airdrop[client] = -1;
					ResetProgressBar(client);
				}
			}
		}
		//E'ye basmayı bırakınca
		else if (g_OnceStopped[client])
		{
			g_iPlayerPrevButtons[client] = 0;
			g_OnceStopped[client] = false;
			if (airdrop_timer[client] != null)
			{
				delete airdrop_timer[client];
				airdrop_timer[client] = null;
			}
			ResetProgressBar(client);
		}
		
		g_iPlayerPrevButtons[client] = iButtons;
	}
}

public Action airdropac(Handle timer, int client)
{
	char sName[33];
	if (client_airdrop[client] && IsValidEdict(client_airdrop[client]))
	{
		GetEntPropString(client_airdrop[client], Prop_Data, "m_iName", sName, sizeof(sName));
		if (StrEqual(sName, "airdrop"))
		{
			ResetProgressBar(client);
			Ekran_Renk_Olustur(client, { 255, 87, 51, 130 } );
			EmitSoundToClientAny(client, "Plugin_Merkezi/PUBG/pubg_weapon_pickup.mp3", SOUND_FROM_PLAYER, 1, 60);
			RastgeleSilahCikar(client, 5);
			SetEntPropString(client_airdrop[client], Prop_Data, "m_iName", "bos_airdrop");
		}
	}
	client_airdrop[client] = -1;
	return Plugin_Handled;
}

void SetProgressBar(int iClient, int iProgressTime)
{
	float flGameTime = GetGameTime();
	
	SetEntDataFloat(iClient, m_flSimulationTime, flGameTime + float(iProgressTime), true);
	SetEntData(iClient, m_iProgressBarDuration, iProgressTime, 4, true);
	SetEntDataFloat(iClient, m_flProgressBarStartTime, flGameTime, true);
	
	// Progress bar type 0-15
	SetEntData(iClient, m_iBlockingUseActionInProgress, 15, 4, true);
}
void ResetProgressBar(int iClient)
{
	SetEntDataFloat(iClient, m_flProgressBarStartTime, 0.0, true);
	SetEntData(iClient, m_iProgressBarDuration, 0, 1, true);
}

float GetEntitiesDistance(int ent1, int ent2)
{
	float orig1[3];
	GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", orig1);
	
	float orig2[3];
	GetEntPropVector(ent2, Prop_Send, "m_vecOrigin", orig2);
	
	return GetVectorDistance(orig1, orig2);
}

//Forked from Franc1sco franug (dev_zones)
/*void KnockbackSetVelocity(int client, const float startpoint[3], const float endpoint[3], float magnitude)
{
	// Create vector from the given starting and ending points.
	float vector[3];
	MakeVectorFromPoints(startpoint, endpoint, vector);
	
	// Normalize the vector (equal magnitude at varying distances).
	NormalizeVector(vector, vector);
	
	// Apply the magnitude by scaling the vector (multiplying each of its components).
	ScaleVector(vector, magnitude);
	
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vector);
}*/