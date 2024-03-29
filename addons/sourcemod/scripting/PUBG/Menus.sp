public int pubg_Handle(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char Item[32];
		menu.GetItem(position, Item, sizeof(Item));
		if (strcmp(Item, "Start", false) == 0)
		{
			if (OyuncuSayisiAl(CS_TEAM_T) != 0)
			{
				if (gozukuyor)
				{
					YeriTemizle(3);
					gozukuyor = false;
				}
				LokasyonlariYukle();
				if (g_pubg_spawn.IntValue == 1)
				{
					if (oyuncuspawn_sayisi + 1 < OyuncuSayisiAl(CS_TEAM_T))
					{
						PrintToChat(client, "[SM] \x01Oyuncu spawn sayısı yetersiz.");
						return;
					}
				}
				if (OyuncuSayisiAl(CS_TEAM_T) <= g_pubg_limit.IntValue)
				{
					PrintToChat(client, "[SM] \x01Yeterli sayıda oyuncu bulunmadığı için oyun iptal edildi.");
					return;
				}
				if (oyuncuspawn_sayisi + 1 <= 0)
				{
					PrintToChat(client, "[SM] \x01Yeterli sayıda Oyuncu spawnı bulunmadığı için oyun iptal edildi. Pubg menüsünden spawn noktaları oluşturabilirsiniz.");
					return;
				}
				if (silahspawn_sayisi + 1 <= 0)
				{
					PrintToChat(client, "[SM] \x01Yeterli sayıda Silah spawnı bulunmadığı için oyun iptal edildi. Pubg menüsünden spawn noktaları oluşturabilirsiniz.");
					return;
				}
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T)
					{
						CS_RespawnPlayer(i);
						int randomnumber = GetRandomInt(0, oyuncuspawn_sayisi);
						if (konumlar_spawn[randomnumber][0] != 0 || g_pubg_spawn.IntValue == 0)
						{
							TeleportEntity(i, konumlar_spawn[randomnumber], NULL_VECTOR, NULL_VECTOR);
							if (g_pubg_spawn.IntValue != 0)
								konumlar_spawn[randomnumber][0] = 0.0;
						}
						else
						{
							do
							{
								randomnumber = GetRandomInt(0, oyuncuspawn_sayisi);
							} while (konumlar_spawn[randomnumber][0] == 0);
							TeleportEntity(i, konumlar_spawn[randomnumber], NULL_VECTOR, NULL_VECTOR);
							konumlar_spawn[randomnumber][0] = 0.0;
						}
						EmitSoundToClientAny(i, "Plugin_Merkezi/PUBG/pubg_game_start.mp3", SOUND_FROM_PLAYER, 1, 40);
					}
				}
				PUBG_Baslat_Pre();
			}
			else
			{
				PrintHintText(client, "[PUBG] Yaşayan sadece 1 oyuncu var!");
				return;
			}
		}
		else if (strcmp(Item, "Stop", false) == 0)
		{
			FinishTheGame();
			PrintToChatAll("[SM] \x02PUBG \x01Oyunu \x0E%N \x01Tarafından Bitirildi!", client);
			SetCvar("sv_enablebunnyhopping", 1);
			SetCvar("sv_autobunnyhopping", 1);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					Ekran_Renk_Olustur(i, { 255, 0, 0, 150 } );
					if (GetClientTeam(i) == CS_TEAM_T)
					{
						Silahlari_Sil(i);
						GivePlayerItem(i, "weapon_knife");
						CanWalk(i, true);
					}
				}
			}
		}
		else if (strcmp(Item, "AirDrop", false) == 0)
		{
			//float AimOrigin[3];
			GetAimCoords(client, AirDropLoc);
			SendAirDrop(AirDropLoc);
			PrintHintText(client, "[PUBG] Air drop yola çıktı!");
		}
		else if (strcmp(Item, "Ayarlar", false) == 0)
		{
			PUBG_AyarMenu_Ac(client).Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

Menu PUBG_AyarMenu_Ac(int client)
{
	Menu menu = new Menu(pubg_genelayarmenu);
	menu.SetTitle("[PUBG] Ayar Menüsü\n▬▬▬▬▬▬▬▬▬▬▬▬▬");
	menu.AddItem("spawn", "Spawn Ayarları", YetkiDurum(client, "z") ? basladi ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	if (duo)
		menu.AddItem("duo", "Oyun Modu: Takımlı");
	else
		menu.AddItem("duo", "Oyun Modu: Takımsız");
	if (bac)
		menu.AddItem("bunny", "Bunny: Pasif");
	else
		menu.AddItem("bunny", "Bunny: Aktif");
	menu.ExitBackButton = false;
	menu.ExitButton = true;
	
	return menu;
}

public int pubg_genelayarmenu(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char item[32];
		menu.GetItem(position, item, sizeof(item));
		if (strcmp(item, "spawn", false) == 0)
			PUBG_AyarMenu_Ac2(client).Display(client, MENU_TIME_FOREVER);
		else if (strcmp(item, "duo", false) == 0)
		{
			duo = !duo;
			PUBG_AyarMenu_Ac(client).Display(client, MENU_TIME_FOREVER);
		}
		else if (strcmp(item, "bunny", false) == 0)
		{
			bac = !bac;
			PUBG_AyarMenu_Ac(client).Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (position == MenuCancel_Exit)
			command_pubg(client, 0);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

Menu PUBG_AyarMenu_Ac2(int client)
{
	Menu menu = new Menu(pubg_spawnayarmenu);
	menu.SetTitle("[PUBG] Spawn Ayar Menüsü\n▬▬▬▬▬▬▬▬▬▬▬▬▬");
	menu.AddItem("1", "Oyuncu spawn noktası belirle");
	menu.AddItem("2", "Silah spawn noktası belirle\n▬▬▬▬▬▬▬▬▬▬▬▬▬");
	menu.AddItem("3", "Oyuncu spawn noktalarını sıfırla");
	menu.AddItem("4", "Silah spawn noktalarını sıfırla\n▬▬▬▬▬▬▬▬▬▬▬▬▬");
	if (gozukuyor)
		menu.AddItem("Hide", "Spawn Noktalarını: Gizle\nHaritanıza göre sunucunuzu çökertebilir!");
	else
	{
		menu.AddItem("Show", "Spawn Noktalarını: Göster\nHaritanıza göre sunucunuzu çökertebilir!");
	}
	gorenoyuncu = client;
	menu.ExitBackButton = false;
	menu.ExitButton = true;
	return menu;
}

public int pubg_spawnayarmenu(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char item[32];
		menu.GetItem(position, item, sizeof(item));
		if (strcmp(item, "Hide", false) == 0)
		{
			YeriTemizle(3);
			gozukuyor = false;
			gorenoyuncu = -1;
			PUBG_AyarMenu_Ac2(client).Display(client, MENU_TIME_FOREVER);
		}
		else if (strcmp(item, "Show", false) == 0)
		{
			ShowModels();
			gozukuyor = true;
			PUBG_AyarMenu_Ac2(client).Display(client, MENU_TIME_FOREVER);
		}
		else
		{
			int sayi = StringToInt(item);
			LokasyonKaydet(client, sayi);
			PUBG_AyarMenu_Ac2(client).Display(client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (position == MenuCancel_Exit)
			PUBG_AyarMenu_Ac(client).Display(client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}


Menu takim_OyuncuMenusuAc()
{
	char iBuffer[16], Name[32];
	Menu menu = new Menu(pubg_takimmenusu);
	menu.SetTitle("[PUBG] Takım Arkadaşını Seç!\n▬▬▬▬▬▬▬▬▬▬▬▬▬");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i) && takim[i][2] == -1)
		{
			IntToString(i, iBuffer, sizeof(iBuffer));
			GetClientName(i, Name, sizeof(Name));
			menu.AddItem(iBuffer, Name);
		}
	}
	menu.AddItem("", "", ITEMDRAW_NOTEXT); //Bunu koymazsak menü açılmıyor garip
	menu.ExitButton = true;
	return menu;
}

public int pubg_takimmenusu(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char item[32];
		menu.GetItem(position, item, sizeof(item));
		if (basladi)
		{
			if (IsClientInGame(StringToInt(item)) && !IsFakeClient(StringToInt(item)))
			{
				if (IsPlayerAlive(StringToInt(item)) && GetClientTeam(StringToInt(item)) == CS_TEAM_T && takim[StringToInt(item)][2] == -1)
				{
					takim_OnayMenusuAc(StringToInt(item), client).Display(StringToInt(item), 10);
					return;
				}
				else if (!IsPlayerAlive(StringToInt(item)))
					PrintToChat(client, " \x07[PUBG] \x01Takım isteği göndermek istediğin kişi ölmüş.");
				else if (GetClientTeam(StringToInt(item)) != 2)
					PrintToChat(client, " \x07[PUBG] \x01Takım isteği göndermek istediğin kişi T takımında değil.");
				else if (takim[StringToInt(item)][0] != -1)
					PrintToChat(client, " \x07[PUBG] \x01Takım isteği göndermek istediğin kişi başka bir takıma girmiş.");
			}
			else
				PrintToChat(client, " \x07[PUBG] \x01Takım isteği göndermek istediğin kişi oyundan çıkmış.");
			takim_OyuncuMenusuAc().Display(client, MENU_TIME_FOREVER);
		}
		else
			PrintToChat(client, " \x07[PUBG] \x01Oyun başladıktan sonra takım isteği gönderemezsin.");
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

Menu takim_OnayMenusuAc(int client, int onaygonderen)
{
	takim[client][2] = 1;
	char titleBuffer[64], iBuffer[16], trickBuffer[32];
	IntToString(onaygonderen, iBuffer, sizeof(iBuffer));
	Format(titleBuffer, sizeof(titleBuffer), "%N sana takım isteği yolladı", onaygonderen);
	Format(trickBuffer, sizeof(trickBuffer), "%dreddet", onaygonderen);
	
	Menu menu = new Menu(takim_onaymenu);
	menu.SetTitle("[PUBG] Takım Arkadaşını Seç!\n▬▬▬▬▬▬▬▬▬▬▬▬▬");
	menu.AddItem(iBuffer, "Kabul Et!");
	menu.AddItem(trickBuffer, "Reddet!");
	menu.ExitButton = true;
	return menu;
}

public int takim_onaymenu(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char item[32];
		menu.GetItem(position, item, sizeof(item));
		if (strcmp(item, "reddet", false) != -1)
		{
			takim[StringToInt(item)][2] = 0;
			takim[client][2] = 0;
		}
		else
		{
			if (basladi)
			{
				if (IsClientInGame(StringToInt(item)) && !IsFakeClient(StringToInt(item)))
				{
					if (IsPlayerAlive(StringToInt(item)) && GetClientTeam(StringToInt(item)) == CS_TEAM_T)
					{
						float konum[3];
						konum[2] += 48;
						GetClientAbsOrigin(StringToInt(item), konum);
						TeleportEntity(client, konum, NULL_VECTOR, NULL_VECTOR);
						takim[client][0] = StringToInt(item);
						takim[StringToInt(item)][0] = client;
						for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, true) && !warden_iswarden(i) && i != client)
						{
							SetListenOverride(client, i, Listen_No);
							SetListenOverride(i, client, Listen_No);
						}
						SetListenOverride(takim[client][0], client, Listen_Yes);
						SetListenOverride(client, takim[client][0], Listen_Yes);
						PrintToChatAll("Artık %d %d ile konuşabiliyor za", client, takim[client][0]);
					}
					else if (!IsPlayerAlive(StringToInt(item)))
						PrintToChat(client, " \x07[PUBG] \x01Takım isteğini kabul etmek istediğin kişi ölmüş.");
					else if (GetClientTeam(StringToInt(item)) != 2)
						PrintToChat(client, " \x07[PUBG] \x01Takım isteğini kabul etmek istediğin kişi T takımında değil.");
				}
				else
					PrintToChat(client, " \x07[PUBG] \x01Takım isteğini kabul etmek istediğin kişi oyundan çıkmış.");
			}
			else
				PrintToChat(client, " \x07[PUBG] \x01Oyun başladıktan sonra takım isteğini kabul edemezsin.");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
} 