//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHSpawnPoint_SquadRallyPoint extends DHSpawnPointBase
    notplaceable;

var DHSquadReplicationInfo SRI;
var int SquadIndex;
var int RallyPointIndex;
var int SpawnsRemaining;
var int SpawnKillCount;
var sound CreationSound;

var int ConstructionRadiusInMeters;
var int OverrunRadiusInMeters;
var int EncroachmentRadiusInMeters;
var int EncroachmentPenaltyBlockThreshold;
var int EncroachmentPenaltyOverrunThreshold;
var int EncroachmentPenaltyCounter;

var int ConstructionCounter;

replication
{
    reliable if (Role == ROLE_Authority)
        SquadIndex, RallyPointIndex, SpawnsRemaining;
}

function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Role == ROLE_Authority)
    {
        SRI = DarkestHourGame(Level.Game).SquadReplicationInfo;

        if (SRI == none)
        {
            Destroy();
        }

        PlaySound(CreationSound, SLOT_None, 4.0,, 60.0,, true);

        SetTimer(1.0, true);
    }
}

auto state Constructing
{
    function Timer()
    {
        local int SquadmateCount;
        local int EnemyCount;

        GetPlayerCountsWithinRadius(default.ConstructionRadiusInMeters, SquadmateCount, EnemyCount);

        if (EnemyCount > 0)
        {
            // Enemies are within the construction radius, start depleting the construction.
            ConstructionCounter -= EnemyCount;
        }
        else if (SquadmateCount > 0)
        {
            ConstructionCounter += SquadmateCount;
        }
        else
        {
            // No one is around to construct, start depleting the construction
            // counter.
            ConstructionCounter -= 1;
        }

        if (ConstructionCounter >= 60) // TODO: remove magic number
        {
            GotoState('Active');
        }
        else if (ConstructionCounter <= 0)
        {
            // TODO: send overrun message?

            Destroy();
        }
    }

Begin:
SetTimer(1.0, true);
}

state Active
{
    function Timer()
    {
        local int OverrunningEnemiesCount;
        local int EncroachingEnemiesCount;

        GetPlayerCountsWithinRadius(default.OverrunRadiusInMeters,, OverrunningEnemiesCount);

        // Destroy the rally point immediately if there are enemies within a
        // very short distance.
        if (OverrunningEnemiesCount >= 1)
        {
            // "A squad rally point has been overrun by enemies."
            SRI.BroadcastLocalizedMessage(SRI.SquadMessageClass, 54);

            Destroy();
        }

        // TODO: 3-strike rule for spawn kills on the rally point
        GetPlayerCountsWithinRadius(default.EncroachmentRadiusInMeters,, EncroachingEnemiesCount);

        if (EncroachingEnemiesCount > 0)
        {
            // There are enemies nearby, so increase the encroachment penalty
            // counter by the number of nearby enemies.
            EncroachmentPenaltyCounter += EncroachingEnemiesCount;
        }
        else
        {
            // There are no enemies nearby, decrease the penalty timer by the
            // amount of nearby friendlies.
            EncroachmentPenaltyCounter -= 2;    // TODO; get rid of magic number
        }

        EncroachmentPenaltyCounter = Max(0, EncroachmentPenaltyCounter);

        if (EncroachmentPenaltyCounter < default.EncroachmentPenaltyBlockThreshold)
        {
            BlockReason = SPBR_None;
        }
        else if (EncroachmentPenaltyCounter < default.EncroachmentPenaltyOverrunThreshold)
        {
            // The encoruachment penalty counter has reached a point where we
            // are now blocking the spawn from being used until enemies
            BlockReason = SPBR_EnemiesNearby;
        }
        else
        {
            // "A squad rally point has been overrun by enemies."
            SRI.BroadcastLocalizedMessage(SRI.SquadMessageClass, 54);

            Destroy();
        }

        // TODO: we need a way to 'reactivate' the previous squad rally point if
        // this one is blocked.
        if (IsBlocked())
        {
        }
    }

    event BeginState()
    {
        SetIsActive(true);

        // "The squad has established a new rally point."
        SRI.BroadcastSquadLocalizedMessage(TeamIndex, SquadIndex, SRI.SquadMessageClass, 44);
    }
}

simulated function bool CanSpawnWithParameters(DHGameReplicationInfo GRI, int TeamIndex, int RoleIndex, int SquadIndex, int VehiclePoolIndex)
{
    if (!super.CanSpawnWithParameters(GRI, TeamIndex, RoleIndex, SquadIndex, VehiclePoolIndex))
    {
        return false;
    }

    if (self.SquadIndex != SquadIndex)
    {
        return false;
    }

    if (SpawnsRemaining == 1)
    {
        // TODO: must be SL to use; where are we gonna get this from? a PRI??
    }

    return true;
}


function GetPlayerCountsWithinRadius(float RadiusInMeters, optional out int SquadmateCount, optional out int EnemyCount)
{
    local Pawn P;
    local DHPlayerReplicationInfo OtherPRI;

    foreach RadiusActors(class'Pawn', P, class'DHUnits'.static.MetersToUnreal(RadiusInMeters))
    {
        if (P != none && !P.bDeleteMe && P.Health > 0 && P.PlayerReplicationInfo != none)
        {
            if (P.GetTeamNum() == TeamIndex)
            {
                OtherPRI = DHPlayerReplicationInfo(P.PlayerReplicationInfo);

                if (OtherPRI != none && OtherPRI.SquadIndex == SquadIndex)
                {
                    SquadmateCount += 1;
                }
            }
            else
            {
                EnemyCount += 1;
            }
        }
    }
}

function GetSpawnPosition(out vector SpawnLocation, out rotator SpawnRotation, int VehiclePoolIndex)
{
    local vector HitLocation, HitNormal;

    if (Trace(HitLocation, HitNormal, Location - vect(0, 0, 32), Location + vect(0, 0, 32)) != none)
    {
        SpawnLocation = HitLocation;
        SpawnLocation.Z += class'DHPawn'.default.CollisionHeight / 2;
    }
    else
    {
        SpawnLocation = Location;
        SpawnLocation.Z += class'DHPawn'.default.CollisionHeight / 2;
    }

    SpawnRotation = Rotation;
}

// Returns true if the spawn point is "visible" to a player with the arguments
// provided.
simulated function bool IsVisibleTo(int TeamIndex, int RoleIndex, int SquadIndex, int VehiclePoolIndex)
{
    if (!super.IsVisibleTo(TeamIndex, RoleIndex, SquadIndex, VehiclePoolIndex))
    {
        return false;
    }

    if (self.SquadIndex != SquadIndex)
    {
        return false;
    }

    return true;
}

function bool PerformSpawn(DHPlayer PC)
{
    local DarkestHourGame G;
    local vector SpawnLocation;
    local rotator SpawnRotation;

    G = DarkestHourGame(Level.Game);

    if (PC == none || PC.Pawn != none || G == none)
    {
        return false;
    }

    if (CanSpawnWithParameters(GRI, PC.GetTeamNum(), PC.GetRoleIndex(), PC.GetSquadIndex(), PC.VehiclePoolIndex))
    {
        GetSpawnPosition(SpawnLocation, SpawnRotation, PC.VehiclePoolIndex);

        if (G.SpawnPawn(PC, SpawnLocation, SpawnRotation, self) == none)
        {
            return false;
        }

        SpawnsRemaining -= 1;

        if (SpawnsRemaining <= 0)
        {
            // "A squad rally point has been exhausted."
            SRI.BroadcastSquadLocalizedMessage(TeamIndex, SquadIndex, SRI.SquadMessageClass, 46);

            Destroy();
        }

        return true;
    }

    return false;
}

defaultproperties
{
    StaticMesh=StaticMesh'DH_Military_stc.Parachute.Chute_pack'
    DrawType=DT_StaticMesh
    TeamIndex=-1
    SquadIndex=-1
    RallyPointIndex=-1
    SpawnsRemaining=9
    SpawnKillCount=0
    CreationSound=Sound'Inf_Player.Gibimpact.Gibimpact'
    EncroachmentRadiusInMeters=25
    EncroachmentPenaltyBlockThreshold=10
    EncroachmentPenaltyOverrunThreshold=30
    OverrunRadiusInMeters=10
    ConstructionRadiusInMeters=25
}

