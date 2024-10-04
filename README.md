## CS:S Crouch Air-Acceleration Fix

This SourceMod plugin addresses the reduced air acceleration that occurs when crouching in Counter-Strike: Source. 
This plugin has been tested on Counter-Strike: Source. While the principle may apply to other Source engine games, you'll need to add support for it. The same principle should also be applicable to +speed.  
This plugin does not change the behavior of crouching in terms of bounding box, hull size, or ground movement. It simply patches air acceleration while crouched to match that of standing.

### Background

In Counter-Strike: Source, air acceleration is directly reduced while crouching. This occurs due to the following code in the `CCSGameMovement` class:

```cpp
void CCSGameMovement::HandleDuckingSpeedCrop()
{
    // ... 
    if ( ( mv->m_nButtons & IN_DUCK ) || ( player->m_Local.m_bDucking ) || ( player->GetFlags() & FL_DUCKING ) )
    {
        mv->m_flForwardMove    *= CS_PLAYER_SPEED_DUCK_MODIFIER;
        mv->m_flSideMove       *= CS_PLAYER_SPEED_DUCK_MODIFIER;
        mv->m_flUpMove         *= CS_PLAYER_SPEED_DUCK_MODIFIER;
        m_iSpeedCropped        |= SPEED_CROPPED_DUCK;
    }
    // ...
}
```

This method scales the player's FSU by approximately 0.34 when ducking.

### Impact on Air Acceleration

The scaling of movement values affects air acceleration due to how the AirMove function calculates wishvel and wishspeed:

```cpp
void CGameMovement::AirMove( void )
{
    // ... 
    fmove = mv->m_flForwardMove;
    smove = mv->m_flSideMove;
    
    for (i=0 ; i<2 ; i++)
        wishvel[i] = forward[i]*fmove + right[i]*smove;
    
    VectorCopy (wishvel, wishdir);
    wishspeed = VectorNormalize(wishdir);
    // ...
}
```

The scaled movement values directly influence the wishvel calculation, which in turn affects the wishspeed passed to the AirAccelerate.

### Solution

This plugin prevents the `HandleDuckingSpeedCrop` function from executing when a player is mid-air, maintaining standard air acceleration values while crouching.

