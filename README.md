https://github.com/click4dylan/CSGO_GameMovement_Reversed/blob/master/IGameMovement.cpp  
https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/gamemovement.cpp

i havent actually tested this and u will need to update plugin to actually function work (this is just a concept) and gamedata urself depending on the game but in theory:

in `CCSGameMovement::AirMove` the player's wishspeed is calculated based on their forward, side, and up, capped sv_air_max_wishspeed (usually 30). 
wishspeed is then passed to `CCSGameMovement::AirAccelerate`, which applies air acceleration to the player's velocity based on the wishspeed, wishdir, sv_airaccelerate.
the resulting acceleration is added to the velocity.

however, `CCSGameMovement::ApplyDuckRatio` (found in reversed igamemovement) scales down the player's forward, side, and upward movement values, as well as their maximum speed, by multiplying them with a duck ratio value.
the duck ratio is calculated based on the player's current ducked amount and decreases as the player becomes more crouched. 

as a result, ducking creates a reduction in perceived airaccel while surfing. this kinda aims to detour it and reset the duck ratio to 0 if airborne (we ignore if on ground).
the duck ratio is only relevant to speed reduction so this should not effect any other properties of crouching, such as player dimensions.
