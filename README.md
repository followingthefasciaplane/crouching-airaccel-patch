## CS:S crouch air-acceleration fix

this sourcemod plugin fixes the reduced air acceleration that occurs when crouching in counter-strike: source. ive only tested that this works on css, you might need to change some things for other games, but the principle should remain the same.

## why this happens

so, there is a direct reduction in air acceleration when crouching, we all know this forever, and here's why:

```
void CCSGameMovement::HandleDuckingSpeedCrop()
{
	//=============================================================================
	// HPE_BEGIN:
	// [Forrest] 
	//=============================================================================
	// Movement speed in free look camera mode is unaffected by ducking state.
	if ( player->GetObserverMode() == OBS_MODE_ROAMING )
		return;
	//=============================================================================
	// HPE_END
	//=============================================================================

	if ( !( m_iSpeedCropped & SPEED_CROPPED_DUCK ) )
	{
		if ( ( mv->m_nButtons & IN_DUCK ) || ( player->m_Local.m_bDucking ) || ( player->GetFlags() & FL_DUCKING ) )
		{
			mv->m_flForwardMove	*= CS_PLAYER_SPEED_DUCK_MODIFIER;
			mv->m_flSideMove	*= CS_PLAYER_SPEED_DUCK_MODIFIER;
			mv->m_flUpMove		*= CS_PLAYER_SPEED_DUCK_MODIFIER;
			m_iSpeedCropped		|= SPEED_CROPPED_DUCK;
		}
	}
}
```

as we can see, this cheeky method in CCSGameMovement scales our FSU by ~0.34 whenever we are ducked..... and this is the cause of our problem here

## i don't get why our FSU matters for aa

it matters because if we look here:

```
void CGameMovement::AirMove( void )
{
	int			i;
	Vector		wishvel;
	float		fmove, smove;
	Vector		wishdir;
	float		wishspeed;
	Vector forward, right, up;

	AngleVectors (mv->m_vecViewAngles, &forward, &right, &up);  // Determine movement angles
	
	// Copy movement amounts
	fmove = mv->m_flForwardMove;
	smove = mv->m_flSideMove;
	
	// Zero out z components of movement vectors
	forward[2] = 0;
	right[2]   = 0;
	VectorNormalize(forward);  // Normalize remainder of vectors
	VectorNormalize(right);    // 

	for (i=0 ; i<2 ; i++)       // Determine x and y parts of velocity
		wishvel[i] = forward[i]*fmove + right[i]*smove;
	wishvel[2] = 0;             // Zero out z part of velocity

	VectorCopy (wishvel, wishdir);   // Determine maginitude of speed of move
	wishspeed = VectorNormalize(wishdir);

	//
	// clamp to server defined max speed
	//
	if ( wishspeed != 0 && (wishspeed > mv->m_flMaxSpeed))
	{
		VectorScale (wishvel, mv->m_flMaxSpeed/wishspeed, wishvel);
		wishspeed = mv->m_flMaxSpeed;
	}
	
	AirAccelerate( wishdir, wishspeed, sv_airaccelerate.GetFloat() );

	// Add in any base velocity to the current velocity.
	VectorAdd(mv->m_vecVelocity, player->GetBaseVelocity(), mv->m_vecVelocity );

	TryPlayerMove();

	// Now pull the base velocity back out.   Base velocity is set if you are on a moving object, like a conveyor (or maybe another monster?)
	VectorSubtract( mv->m_vecVelocity, player->GetBaseVelocity(), mv->m_vecVelocity );
}
```

specifically these lines:

```
	// Copy movement amounts
	fmove = mv->m_flForwardMove;
	smove = mv->m_flSideMove;

	for (i=0 ; i<2 ; i++)       // Determine x and y parts of velocity
		wishvel[i] = forward[i]*fmove + right[i]*smove;

    VectorCopy (wishvel, wishdir);   // Determine maginitude of speed of move
	wishspeed = VectorNormalize(wishdir);
```

so as we can see our FSU is actually what determines our wishvel in airmove, which is then passed to airaccelerate... so basically, this HandleDuckingSpeedCrop is not scaling our FSU only, its also scaling our wishspeed in AA by the same amount.

## so lets kill this function if a player is midair

i agree, so thats what we have done here