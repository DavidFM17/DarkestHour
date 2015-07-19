//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DHCollisionStaticMeshActor extends StaticMeshActor
    notplaceable;

/**
Matt, July 2015: this actor is a way of getting a collision static mesh to work on a VehicleWeapon (generally a turret, but maybe an exposed MG or a gun shield)

You can see in the RO vehicle static mesh packages that turret col meshes were made, but are not used (DH also had 1 or 2 in 5.1).
Instead turrets only have simple box collision, which give only crude hit detection. TWI must have hit a problem, so why weren't the turret col meshes used?
The answer is that in UT2004 skeletal meshes, a col mesh can't be attached to a bone, only to the skeletal mesh origin.
That works fine for a vehicle hull, but a VehicleWeapon actor always faces directly forwards, relative to the hull.
The actual VW actor doesn't rotate relatively, only it's yaw bone rotates, which makes the weapon rotate visibly - but the actual actor itself isn't rotating.
So the VW col mesh, which is attached to the origin, always stays facing forwards, relative to the hull.
As soon as the weapon rotates, the col mesh is no longer aligned with the weapon & hit detection is completely screwed up.
The 1 RO vehicle that does use a turret col mesh is the tiger - to see the screwed up result, in single player type "show collision" in console, rotate turret & take a look !!

This is a workaround that solves the problem. This is the sequence of events, which is actually very simple:
1. If a CollisionStaticMesh has been specified in the WV class, the VW spawns a separate col static mesh actor in PostBeginPlay, with the VW as col mesh's owner.
2. VW attaches col mesh actor to VW's YawBone - col mesh will now rotate with the VW.
3. VW removes all of its own collision, so no hit will ever be detected on the VW itself.
4. Col mesh actor copies the VW's normal collision properties, so projectiles will hit the col mesh in the same way & trigger the usual functionality.
5. All relevant projectile (& related) hit detection functions begin by checking if the hit actor is a col mesh actor.
6. If a projectile has hit a col mesh actor, it simply switches the hit actor to be the col mesh's owner, which is the actual VW.
7. The hit detection functionality then simply continues as if it had hit the actual VW, with the usual hit & penetration calcs & results.
8. For other collision, e.g. a player walking on a turret, the col mesh actor also handles that as if the colliding actor had collided with the actual VW
   (although the col mesh uses simple 'box' collision for players (they use a non-zero extent trace), instead of complex, per-polygon collision).

To set up a VW col mesh actor the process is:
1. Make a simplified static mesh version of the VW skeletal mesh, with one material slot.
2. Import the col mesh into a DH static mesh file & name it something like MyVehicle_turret_coll.
3. Give it the properties of any 'normal' col static mesh (Material = none, true for EnableCollision, UseSimpleKarmaCollision & UseSimpleBoxCollision, false for others).
4. Add CollisionStaticMesh=StaticMesh'DH_TheStaticMeshPackage.MyVehicle_turret_coll' to the VW's default properties.

When modelling a new VW col mesh, e.g. a tank turret:
- Keep the mesh simple, with as few triangles as possible - just model the main shape of the turret, where a shell may potentially hit & destroy.
- Do not use the actual turret model as a col mesh, as it's unnecessarily detailed for collision calcs, which should always be a simple as possible.
- So just use the actual turret model as a template for the shape of your new, simple col mesh.
- Do not include a cannon barrel as if it's hit by a shell it may well cause the whole vehicle to explode.
- Avoid convex angles in the col mesh, as static mesh collision detection doesn't like that, so where necessary split the mesh into separate, convex, 'closed' parts
*/

// Modified to copy the owning VehicleWeapon's collision properties
simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Owner != none)
    {
        SetCollision(Owner.default.bCollideActors, Owner.default.bBlockActors);
        bCollideWorld = Owner.default.bCollideWorld;
        SetCollisionSize(Owner.CollisionRadius, Owner.CollisionHeight);
        KSetBlockKarma(Owner.default.bBlockKarma);
        bBlockZeroExtentTraces = Owner.default.bBlockZeroExtentTraces;
        bBlockNonZeroExtentTraces = Owner.default.bBlockNonZeroExtentTraces;
        bBlockHitPointTraces = Owner.default.bBlockHitPointTraces;
        bProjTarget = Owner.default.bProjTarget;
        bUseCollisionStaticMesh = Owner.default.bUseCollisionStaticMesh;
        bWorldGeometry = Owner.default.bWorldGeometry;
        bIgnoreEncroachers = Owner.default.bIgnoreEncroachers;
    }
    else
    {
        Warn(Tag @ "somehow spawned without an Owner, so is being destroyed");
        Destroy();
    }
}

// Hides or shows the owning VehicleWeapon - a debug tool
simulated function HideOwner(bool bHide)
{
    local int i;

    for (i = 0; i < Owner.Skins.Length; ++i)
    {
        if (bHide)
        {
            Owner.Skins[i] = texture'DH_VehiclesGE_tex2.ext_vehicles.Alpha';
        }
        else
        {
            Owner.Skins[i] = Owner.default.Skins[i];
        }
    }
}

// Col mesh actor should never take damage, so just in case we'll call TakeDamage on the owning VehicleWeapon, which would have otherwise have received the call
function TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional int HitIndex)
{
    Owner.TakeDamage(Damage, EventInstigator, HitLocation, Momentum, DamageType, HitIndex);
}

defaultproperties
{
    RemoteRole=ROLE_None
    bHidden=true
    bStatic=false
}