#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
    name = "crouchaccel",
    author = "jessetooler",
    description = "attempts to remove the air accel penalty from crouching.",
    version = PLUGIN_VERSION,
    url = "https://www.example.com/"
};

Handle g_hGameConf = null;
Handle g_hApplyDuckRatioHook = null;

public void OnPluginStart()
{
    g_hGameConf = LoadGameConfigFile("csgo");
    if (g_hGameConf == null)
    {
        SetFailState("Failed to load gamedata file: csgo.games.txt");
        return;
    }

    g_hApplyDuckRatioHook = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
    if (g_hApplyDuckRatioHook == null)
    {
        SetFailState("Failed to create a detour for CCSGameMovement::ApplyDuckRatio.");
        return;
    }

    DHookAddParam(g_hApplyDuckRatioHook, HookParamType_Float);

    if (!DHookSetFromConf(g_hApplyDuckRatioHook, g_hGameConf, SDKConf_Signature, "CCSGameMovement::ApplyDuckRatio"))
    {
        SetFailState("Failed to configure detour from gamedata.");
        return;
    }

    DHookEnableDetour(g_hApplyDuckRatioHook, true, CCSGameMovement_ApplyDuckRatio_Detour);
}

public MRESReturn CCSGameMovement_ApplyDuckRatio_Detour(int thisPtr, Handle hParams)
{
    int clientIndex = GetClientFromGameMovement(thisPtr);

    // get rid of duck movement penalties when in the air
    if (!(GetEntityFlags(clientIndex) & FL_ONGROUND))
    {
        float newDuckAmount = 1.0; 
        DHookSetParam(hParams, 1, newDuckAmount); // assuming its actually the first parameter

        return MRES_Supercede; // override the original function
    }

    return MRES_Ignored; // we dont care if the player is on the ground
}

int GetClientFromGameMovement(int gameMovement)
{
    // retrieve the client index from the game movement object
    // adjust the offset as needed
    int clientIndex = LoadFromAddress(view_as<Address>(gameMovement + 4), NumberType_Int32);
    return clientIndex;
}
