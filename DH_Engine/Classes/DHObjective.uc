//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHObjective extends ROObjTerritory
    hidecategories(Assault,GameObjective,JumpDest,JumpSpot,MothershipHack)
    placeable;

enum EObjectiveOperation
{
    EOO_Activate,
    EOO_Deactivate,
    EOO_Toggle,
    EOO_Lock,
    EOO_Unlock
};

enum ESpawnPointOperation
{
    ESPO_Enable,
    ESPO_Disable,
    ESPO_Toggle,
    ESPO_Lock,
    ESPO_Unlock
};

enum EVehiclePoolOperation
{
    EVPO_Enable,
    EVPO_Disable,
    EVPO_Toggle,
    EVPO_MaxSpawnsAdd,
    EVPO_MaxSpawnsSet,
    EVPO_MaxActiveAdd,
    EVPO_MaxActiveSet
};

struct SpawnPointAction
{
    var() name SpawnPointTag;
    var() ESpawnPointOperation Operation;
};

struct VehiclePoolAction
{
    var() name VehiclePoolTag;
    var() EVehiclePoolOperation Operation;
    var() int Value;
};

struct ObjOperationAction
{
    var() int ObjectiveNum;
    var() EObjectiveOperation Operation;
};

var(ROObjTerritory) bool            bSetInactiveOnCapture;      // Simliar to bRecaptureable, but doesn't disable timer, just sets to inactive (bRecaptureable must = true)
var(ROObjTerritory) bool            bUseHardBaseRate;           // Tells the capture rate to always be the base value, so we can have consistent capture times
var(ROObjective) bool               bIsInitiallyActive;         // Purpose is mainly to consolidate the variables of actors into one area (less confusing to new levelers)
var()   bool                        bVehiclesCanCapture;
var()   bool                        bTankersCanCapture;
var()   bool                        bUsePostCaptureOperations;  // Enables below variables to be used for post capture clear check/calls
var()   bool                        bDisableWhenAlliesClearObj;
var()   bool                        bDisableWhenAxisClearObj;
var()   bool                        bGroupActionsAtDisable;
var()   bool                        bHideOnMap;
var()   bool                        bHideOnMapWhenInactive;
var()   bool                        bHideLabelWhenInactive;
var()   bool                        bResetDeathPenalties;        // will reset all players death penalty counts
var()   int                         AlliedAwardedReinforcements; // Amount of reinforcement to aware for allies if the obj is captured
var()   int                         AxisAwardedReinforcements;   // Amount of reinforcement to aware for axis if the obj is captured
var()   int                         PlayersNeededToCapture;
var()   name                        NoArtyVolumeProtectionTag;   // optional Tag for associated no arty volume that protects this SP only when the SP is active

var     bool                        bCheckIfAxisCleared;
var     bool                        bCheckIfAlliesCleared;
var     bool                        bAlliesContesting;
var     bool                        bAxisContesting;
var     bool                        bIsLocked;

// Capture operations (after capture)
var(DH_CaptureActions)      array<ObjOperationAction>   AlliesCaptureObjActions;
var(DH_CaptureActions)      array<ObjOperationAction>   AxisCaptureObjActions;
var(DH_CaptureActions)      array<SpawnPointAction>     AlliesCaptureSpawnPointActions;
var(DH_CaptureActions)      array<SpawnPointAction>     AxisCaptureSpawnPointActions;
var(DH_CaptureActions)      array<VehiclePoolAction>    AlliesCaptureVehiclePoolActions;
var(DH_CaptureActions)      array<VehiclePoolAction>    AxisCaptureVehiclePoolActions;
var(DH_CaptureActions)      array<name>                 AlliesCaptureEvents;
var(DH_CaptureActions)      array<name>                 AxisCaptureEvents;

// Post capture cleared operations (after capture and cleared of enemies)
var(DH_ClearedActions)      array<ObjOperationAction>   AlliesClearedCaptureObjActions;
var(DH_ClearedActions)      array<ObjOperationAction>   AxisClearedCaptureObjActions;
var(DH_ClearedActions)      array<SpawnPointAction>     AlliesClearedCaptureSpawnPointActions;
var(DH_ClearedActions)      array<SpawnPointAction>     AxisClearedCaptureSpawnPointActions;
var(DH_ClearedActions)      array<VehiclePoolAction>    AlliesClearedCaptureVehiclePoolActions;
var(DH_ClearedActions)      array<VehiclePoolAction>    AxisClearedCaptureVehiclePoolActions;
var(DH_ClearedActions)      array<name>                 AlliesClearedCaptureEvents;
var(DH_ClearedActions)      array<name>                 AxisClearedCaptureEvents;

// Grouped capture operations (these will need to be the same in each grouped objective, unless you desire different actions based on the last captured grouped objective)
var(DH_GroupedActions)      array<int>                  GroupedObjectiveReliances; // array of Objective Nums this objective is grouped with (doesn't need to list itself)
var(DH_GroupedActions)      array<ObjOperationAction>   AlliesCaptureGroupObjActions;
var(DH_GroupedActions)      array<ObjOperationAction>   AxisCaptureGroupObjActions;
var(DH_GroupedActions)      array<SpawnPointAction>     AlliesGroupSpawnPointActions;
var(DH_GroupedActions)      array<SpawnPointAction>     AxisGroupSpawnPointActions;
var(DH_GroupedActions)      array<VehiclePoolAction>    AlliesGroupVehiclePoolActions;
var(DH_GroupedActions)      array<VehiclePoolAction>    AxisGroupVehiclePoolActions;
var(DH_GroupedActions)      array<name>                 AlliesGroupCaptureEvents;
var(DH_GroupedActions)      array<name>                 AxisGroupCaptureEvents;

// Contested operations (used when a side begins capturing)
var(DH_ContestedActions)    array<ObjOperationAction>   AlliesContestObjActions;
var(DH_ContestedActions)    array<ObjOperationAction>   AxisContestObjActions;
var(DH_ContestedActions)    array<SpawnPointAction>     AlliesContestSpawnPointActions;
var(DH_ContestedActions)    array<SpawnPointAction>     AxisContestSpawnPointActions;
var(DH_ContestedActions)    array<VehiclePoolAction>    AlliesContestVehiclePoolActions;
var(DH_ContestedActions)    array<VehiclePoolAction>    AxisContestVehiclePoolActions;
var(DH_ContestedActions)    array<name>                 AlliesContestEvents;
var(DH_ContestedActions)    array<name>                 AxisContestEvents;

// Contest end operations (used when a side fails to capture and contest ends)
var(DH_ContestEndActions)   array<ObjOperationAction>   AlliesContestEndObjActions;
var(DH_ContestEndActions)   array<ObjOperationAction>   AxisContestEndObjActions;
var(DH_ContestEndActions)   array<SpawnPointAction>     AlliesContestEndSpawnPointActions;
var(DH_ContestEndActions)   array<SpawnPointAction>     AxisContestEndSpawnPointActions;
var(DH_ContestEndActions)   array<VehiclePoolAction>    AlliesContestEndVehiclePoolActions;
var(DH_ContestEndActions)   array<VehiclePoolAction>    AxisContestEndVehiclePoolActions;
var(DH_ContestEndActions)   array<name>                 AlliesContestEndEvents;
var(DH_ContestEndActions)   array<name>                 AxisContestEndEvents;

function PostBeginPlay()
{
    local DHGameReplicationInfo DHGRI;
    local RONoArtyVolume        NAV;

    // Call super above ROObjective
    super(GameObjective).PostBeginPlay();

    DHGRI = DHGameReplicationInfo(Level.Game.GameReplicationInfo);

    // Find the volume to use if the mapper set one
    if (VolumeTag != '')
    {
        foreach AllActors(class'Volume', AttachedVolume, VolumeTag)
        {
            AttachedVolume.AssociatedActor = self;
            break;
        }
    }

    // Find any associated no arty volume (that will only protect this objective if the objective is active)
    // Note that we don't need to record a reference to the no arty volume actor, we only need to set its AssociatedActor reference to be this objective
    if (NoArtyVolumeProtectionTag != '')
    {
        foreach AllActors(class'RONoArtyVolume', NAV, NoArtyVolumeProtectionTag)
        {
            NAV.AssociatedActor = self;
            break;
        }
    }

    ObjState = InitialObjState;

    // Override the GameObjective variable bInitiallyActive with DH
    if (Role == ROLE_Authority)
    {
        SetActive(bIsInitiallyActive);
    }

    // Add self to game objectives
    if (DarkestHourGame(Level.Game) != none)
    {
        DarkestHourGame(Level.Game).DHObjectives[ObjNum] = self;
    }

    // Add self to game replication info objectives
    if (DHGRI != none)
    {
        DHGRI.DHObjectives[ObjNum] = self;
    }
}

function Reset()
{
    super.Reset();

    SetActive(bIsInitiallyActive);

    bCheckIfAxisCleared = false;
    bCheckIfAlliesCleared = false;
    bAlliesContesting = false;
    bAxisContesting = false;
    bIsLocked = false;
}

function DoSpawnPointAction(SpawnPointAction SPA)
{
    local DHSpawnManager SM;

    SM = DarkestHourGame(Level.Game).SpawnManager;

    if (SM == none)
    {
        return;
    }

    switch (SPA.Operation)
    {
        case ESPO_Enable:
            SM.SetSpawnPointIsActiveByTag(SPA.SpawnPointTag, true);
            break;
        case ESPO_Disable:
            SM.SetSpawnPointIsActiveByTag(SPA.SpawnPointTag, false);
            break;
        case ESPO_Toggle:
            SM.ToggleSpawnPointIsActiveByTag(SPA.SpawnPointTag);
            break;
        case ESPO_Lock:
            SM.SetSpawnPointIsLockedByTag(SPA.SpawnPointTag, true);
            break;
        case ESPO_Unlock:
            SM.SetSpawnPointIsLockedByTag(SPA.SpawnPointTag, false);
            break;
        default:
            Warn("Unhandled ESpawnPointOperation");
            break;
    }
}

function DoVehiclePoolAction(VehiclePoolAction VPA)
{
    local DHSpawnManager SM;

    SM = DarkestHourGame(Level.Game).SpawnManager;

    if (SM == none)
    {
        return;
    }

    switch (VPA.Operation)
    {
        case EVPO_Enable:
            SM.SetVehiclePoolIsActiveByTag(VPA.VehiclePoolTag, true);
            break;
        case EVPO_Disable:
            SM.SetVehiclePoolIsActiveByTag(VPA.VehiclePoolTag, false);
            break;
        case EVPO_Toggle:
            SM.ToggleVehiclePoolIsActiveByTag(VPA.VehiclePoolTag);
            break;
        case EVPO_MaxSpawnsAdd:
            SM.AddVehiclePoolMaxSpawnsByTag(VPA.VehiclePoolTag, VPA.Value);
            break;
        case EVPO_MaxSpawnsSet:
            SM.SetVehiclePoolMaxSpawnsByTag(VPA.VehiclePoolTag, VPA.Value);
            break;
        case EVPO_MaxActiveAdd:
            SM.AddVehiclePoolMaxActiveByTag(VPA.VehiclePoolTag, VPA.Value);
            break;
        case EVPO_MaxActiveSet:
            SM.SetVehiclePoolMaxActiveByTag(VPA.VehiclePoolTag, VPA.Value);
            break;
        default:
            Warn("Unhandled EVehiclePoolOperation");
            break;
    }
}

function DoObjectiveAction(ObjOperationAction OOA)
{
    local DarkesthourGame G;

    if (bIsLocked)
    {
        return;
    }

    G = DarkesthourGame(Level.Game);

    switch (OOA.Operation)
    {
        case EOO_Activate:
            G.DHObjectives[OOA.ObjectiveNum].SetActive(true);
            break;
        case EOO_Deactivate:
            G.DHObjectives[OOA.ObjectiveNum].SetActive(false);
            break;
        case EOO_Toggle:
            G.DHObjectives[OOA.ObjectiveNum].SetActive(!G.DHObjectives[OOA.ObjectiveNum].bActive);
            break;
        case EOO_Lock:
            G.DHObjectives[OOA.ObjectiveNum].bIsLocked = true;
            break;
        case EOO_Unlock:
            G.DHObjectives[OOA.ObjectiveNum].bIsLocked = false;
            break;
        default:
            Warn("Unhandled EObjectiveOperation");
            break;
    }
}

function HandleContestedActions(int Team, bool bStarted)
{
    local int i;

    // Contested started
    if (bStarted)
    {
        if (Team == AXIS_TEAM_INDEX)
        {
            for (i = 0; i < AxisContestObjActions.Length; ++i)
            {
                DoObjectiveAction(AxisContestObjActions[i]);
            }

            for (i = 0; i < AxisContestSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AxisContestSpawnPointActions[i]);
            }

            for (i = 0; i < AxisContestVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AxisContestVehiclePoolActions[i]);
            }

            for (i = 0; i < AxisContestEvents.Length; ++i)
            {
                TriggerEvent(AxisContestEvents[i], none, none);
            }
        }
        else if (Team == ALLIES_TEAM_INDEX)
        {
            for (i = 0; i < AlliesContestObjActions.Length; ++i)
            {
                DoObjectiveAction(AlliesContestObjActions[i]);
            }

            for (i = 0; i < AlliesContestSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AlliesContestSpawnPointActions[i]);
            }

            for (i = 0; i < AlliesContestVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AlliesContestVehiclePoolActions[i]);
            }

            for (i = 0; i < AlliesContestEvents.Length; ++i)
            {
                TriggerEvent(AlliesContestEvents[i], none, none);
            }
        }
    }
    // Contested failed/ended
    else
    {
        if (Team == AXIS_TEAM_INDEX)
        {
            for (i = 0; i < AxisContestEndObjActions.Length; ++i)
            {
                DoObjectiveAction(AxisContestEndObjActions[i]);
            }

            for (i = 0; i < AxisContestEndSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AxisContestEndSpawnPointActions[i]);
            }

            for (i = 0; i < AxisContestEndVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AxisContestEndVehiclePoolActions[i]);
            }

            for (i = 0; i < AxisContestEndEvents.Length; ++i)
            {
                TriggerEvent(AxisContestEndEvents[i], none, none);
            }
        }
        else if (Team == ALLIES_TEAM_INDEX)
        {
            for (i = 0; i < AlliesContestEndObjActions.Length; ++i)
            {
                DoObjectiveAction(AlliesContestEndObjActions[i]);
            }

            for (i = 0; i < AlliesContestEndSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AlliesContestEndSpawnPointActions[i]);
            }

            for (i = 0; i < AlliesContestEndVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AlliesContestEndVehiclePoolActions[i]);
            }

            for (i = 0; i < AlliesContestEndEvents.Length; ++i)
            {
                TriggerEvent(AlliesContestEndEvents[i], none, none);
            }
        }
    }
}

function HandleGroupActions(int Team)
{
    local DarkesthourGame DHGame;
    local bool bGroupedObjNotSame;
    local int  i;

    DHGame = DarkesthourGame(Level.Game);

    if (Team == AXIS_TEAM_INDEX)
    {
        for (i = 0; i < GroupedObjectiveReliances.Length; ++i)
        {
            // Check if the grouped objective isn't captured for Axis
            if (!DHGame.DHObjectives[GroupedObjectiveReliances[i]].isAxis())
            {
                // One of the grouped objectives is not captured for Axis yet
                bGroupedObjNotSame = true;
            }
        }

        // If all the grouped objectives are captured for Axis, do grouped actions
        if (GroupedObjectiveReliances.Length > 0 && !bGroupedObjNotSame)
        {
            for (i = 0; i < AxisCaptureGroupObjActions.Length; ++i)
            {
                DoObjectiveAction(AxisCaptureGroupObjActions[i]);
            }

            for (i = 0; i < AxisGroupSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AxisGroupSpawnPointActions[i]);
            }

            for (i = 0; i < AxisGroupVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AxisGroupVehiclePoolActions[i]);
            }

            for (i = 0; i < AxisGroupCaptureEvents.Length; ++i)
            {
                TriggerEvent(AxisGroupCaptureEvents[i], none, none);
            }
        }
    }
    else if (Team == ALLIES_TEAM_INDEX)
    {
        for (i = 0; i < GroupedObjectiveReliances.Length; ++i)
        {
            // Check if the grouped objective isn't captured for Allies
            if (!DHGame.DHObjectives[GroupedObjectiveReliances[i]].isAllies())
            {
                // One of the grouped objectives is not captured for Allies yet
                bGroupedObjNotSame = true;
            }
        }

        // If all the grouped objectives are captured for Allies, do grouped actions
        if (GroupedObjectiveReliances.Length > 0 && !bGroupedObjNotSame)
        {
            for (i = 0; i < AlliesCaptureGroupObjActions.Length; ++i)
            {
                DoObjectiveAction(AlliesCaptureGroupObjActions[i]);
            }

            for (i = 0; i < AlliesGroupSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AlliesGroupSpawnPointActions[i]);
            }

            for (i = 0; i < AlliesGroupVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AlliesGroupVehiclePoolActions[i]);
            }

            for (i = 0; i < AlliesGroupCaptureEvents.Length; ++i)
            {
                TriggerEvent(AlliesGroupCaptureEvents[i], none, none);
            }
        }
    }

}

function HandleCompletion(PlayerReplicationInfo CompletePRI, int Team)
{
    local DarkestHourGame           G;
    local DHPlayerReplicationInfo   PRI;
    local DHGameReplicationInfo     GRI;
    local DHRoleInfo                RI;
    local Controller                C;
    local Pawn                      P;
    local int                       i;
    local array<string>             PlayerIDs;
    local int                       RoundTime;

    CurrentCapProgress = 0.0;
    bAlliesContesting = false; // set to false as the objective was captured
    bAxisContesting = false;   // ...

    G = DarkestHourGame(Level.Game);
    GRI = DHGameReplicationInfo(G.GameReplicationInfo);

    if (G == none || GRI == none)
    {
        return;
    }

    // If it's not recapturable, make it inactive
    if (!bRecaptureable)
    {
        bActive = false;

        // Only turn off the timer if bUsePostCaptureOperations is false, we will turn it off after it's clear of enemies (in timer)
        if (!bUsePostCaptureOperations)
        {
            SetTimer(0.0, false);
        }

        DisableCapBarsForThisObj(); // might want to move this to above if statement, but would need testing
    }

    // Don't "disable" the objective, just "deactivate it"
    if (bSetInactiveOnCapture)
    {
        SetActive(false);
    }

    // Give players points for helping with the capture
    for (C = Level.ControllerList; C != none; C = C.NextController)
    {
        P = DHPawn(C.Pawn);

        if (P == none)
        {
            P = ROVehicle(C.Pawn);

            if (P == none)
            {
                P = ROVehicleWeaponPawn(C.Pawn);

                if (!bVehiclesCanCapture)
                {
                    continue;
                }
            }
            else if (!bVehiclesCanCapture)
            {
                continue;
            }
        }

        // If bUseDeathPenaltyCount, then reset everyone's count as an objective was captured!
        if (bResetDeathPenalties && GRI.bUseDeathPenaltyCount && DHPlayer(C) != none)
        {
            DHPlayer(C).DeathPenaltyCount = DHPlayer(C).default.DeathPenaltyCount;
        }

        PRI = DHPlayerReplicationInfo(C.PlayerReplicationInfo);

        if (PRI != none)
        {
            RI = DHRoleInfo(PRI.RoleInfo);
        }

        if (!C.bIsPlayer || P == none || !WithinArea(P) || C.PlayerReplicationInfo.Team == none || C.PlayerReplicationInfo.Team.TeamIndex != Team)
        {
            continue;
        }

        if (!bTankersCanCapture && RI != none && RI.bCanBeTankCrew)
        {
            continue;
        }

        Level.Game.ScoreObjective(C.PlayerReplicationInfo, 10);

        if (PlayerController(C) != none)
        {
             PlayerIDs[PlayerIDs.Length] = PlayerController(C).GetPlayerIDHash();
        }
    }

    BroadcastLocalizedMessage(class'DHObjectiveMessage', Team, none, none, self);

    if (G.Metrics != none)
    {
        RoundTime = GRI.ElapsedTime - GRI.RoundStartTime;
        G.Metrics.OnObjectiveCaptured(ObjNum, Team, RoundTime, PlayerIDs);
    }

    // Award reinforcements
    G.ModifyReinforcements(AXIS_TEAM_INDEX, AxisAwardedReinforcements * FMax(0.1, (G.NumPlayers / G.MaxPlayers)));
    G.ModifyReinforcements(ALLIES_TEAM_INDEX, AlliedAwardedReinforcements * FMax(0.1, (G.NumPlayers / G.MaxPlayers)));

    // Handle attrition unlock
    if (G.DHLevelInfo != none && G.DHLevelInfo.AttritionMaxOpenObj > 0)
    {
        G.AttritionUnlockObjective(ObjNum);
    }

    switch (Team)
    {
        case AXIS_TEAM_INDEX:

            for (i = 0; i < AxisCaptureObjActions.Length; ++i)
            {
                DoObjectiveAction(AxisCaptureObjActions[i]);
            }

            for (i = 0; i < AxisCaptureSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AxisCaptureSpawnPointActions[i]);
            }

            for (i = 0; i < AxisCaptureVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AxisCaptureVehiclePoolActions[i]);
            }

            for (i = 0; i < AxisCaptureEvents.Length; ++i)
            {
                TriggerEvent(AxisCaptureEvents[i], none, none);
            }

            // Do a check for the post capture clear system
            if (bUsePostCaptureOperations)
            {
                bCheckIfAxisCleared = false;  // stop checking for when Axis are cleared (supports recapturable objectives)
                bCheckIfAlliesCleared = true; // begin checking for when Allies are cleared
            }

            if (!bGroupActionsAtDisable)
            {
                HandleGroupActions(AXIS_TEAM_INDEX);
            }

            break;

        case ALLIES_TEAM_INDEX:

            for (i = 0; i < AlliesCaptureObjActions.Length; ++i)
            {
                DoObjectiveAction(AlliesCaptureObjActions[i]);
            }

            for (i = 0; i < AlliesCaptureSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AlliesCaptureSpawnPointActions[i]);
            }

            for (i = 0; i < AlliesCaptureVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AlliesCaptureVehiclePoolActions[i]);
            }

            for (i = 0; i < AlliesCaptureEvents.Length; ++i)
            {
                TriggerEvent(AlliesCaptureEvents[i], none, none);
            }

            // Do a check for the post capture clear system
            if (bUsePostCaptureOperations)
            {
                bCheckIfAlliesCleared = false; // stop checking for when Allies are cleared (supports recapturable objectives)
                bCheckIfAxisCleared = true;    // begin checking for when Axis are cleared
            }

            if (!bGroupActionsAtDisable)
            {
                HandleGroupActions(ALLIES_TEAM_INDEX);
            }

            break;
    }
}

function Timer()
{
    local ROPlayerReplicationInfo PRI;
    local DHRoleInfo              RI;
    local Controller              FirstCapturer, C;
    local Pawn                    Pawn;
    local DHPawn                  P;
    local ROVehicle               ROVeh;
    local ROVehicleWeaponPawn     VehWepPawn;
    local float                   OldCapProgress, LeaderBonus[2], Rate[2];
    local int                     NumTotal[2], Num[2], NumForCheck[2], i;
    local byte                    CurrentCapAxisCappers, CurrentCapAlliesCappers, CP;

    if (ROTeamGame(Level.Game) == none || !ROTeamGame(Level.Game).IsInState('RoundInPlay') || (!bActive && !bUsePostCaptureOperations))
    {
        return;
    }

    // Some RO code (that is retarded)
    LeaderBonus[AXIS_TEAM_INDEX] = 1.0;
    LeaderBonus[ALLIES_TEAM_INDEX] = 1.0;

    // Loop through Controller list & determine how many players from each team are inside the attached volume, or if there is no volume, within the Radius that was set
    for (C = Level.ControllerList; C != none; C = C.NextController)
    {
        if (C.bIsPlayer && C.PlayerReplicationInfo.Team != none && ((ROPlayer(C) != none && ROPlayer(C).GetRoleInfo() != none) || ROBot(C) != none))
        {
            Pawn = C.Pawn;
            P = DHPawn(C.Pawn);
            ROVeh = ROVehicle(C.Pawn);
            VehWepPawn = ROVehicleWeaponPawn(C.Pawn);

            PRI = ROPlayerReplicationInfo(C.PlayerReplicationInfo);
            RI = DHRoleInfo(PRI.RoleInfo);

            if (Pawn != none && Pawn.Health > 0 && WithinArea(Pawn))
            {
                if ((!bTankersCanCapture && RI != none && RI.bCanBeTankCrew) || (!bVehiclesCanCapture && (ROVeh != none || VehWepPawn != none)))
                {
                    Pawn = none;
                    continue;
                }

                Num[C.PlayerReplicationInfo.Team.TeamIndex]++;

                if (RI != none)
                {
                    NumForCheck[C.PlayerReplicationInfo.Team.TeamIndex] += PRI.RoleInfo.ObjCaptureWeight;
                }
                else
                {
                    NumForCheck[C.PlayerReplicationInfo.Team.TeamIndex]++;
                }

                FirstCapturer = C; // used so that first person to initiate capture doesn't get the 'map updated' notification

                // Leader bonuses are given to a side if a leader is there
            }

            // Fixes the cap bug
            Pawn = none;

            // Update total nums
            NumTotal[C.PlayerReplicationInfo.Team.TeamIndex]++;
        }
    }

    // Now that we calculated how many of each team is in the objective, lets do the bUsePostCaptureOperations checks
    if (bUsePostCaptureOperations)
    {
        if (bCheckIfAxisCleared && NumForCheck[0] <= 0)
        {
            // IT IS CLEARED OF AXIS (SO DO ALLIES ACTIONS)
            bCheckIfAxisCleared = false; // stop checking

            for (i = 0; i < AlliesClearedCaptureObjActions.Length; ++i)
            {
                DoObjectiveAction(AlliesClearedCaptureObjActions[i]);
            }

            for (i = 0; i < AlliesClearedCaptureSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AlliesClearedCaptureSpawnPointActions[i]);
            }

            for (i = 0; i < AlliesClearedCaptureVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AlliesClearedCaptureVehiclePoolActions[i]);
            }

            for (i = 0; i < AlliesClearedCaptureEvents.Length; ++i)
            {
                TriggerEvent(AlliesClearedCaptureEvents[i], none, none);
            }

            if (bGroupActionsAtDisable)
            {
                HandleGroupActions(ALLIES_TEAM_INDEX);
            }

            if (bDisableWhenAlliesClearObj)
            {
                CurrentCapProgress = 0.0;
                bActive = false;
                SetTimer(0.0, false);
                DisableCapBarsForThisObj();

                return;
            }
            else if (!bRecaptureable)
            {
                SetTimer(0.0, false);

                return;
            }
        }

        if (bCheckIfAlliesCleared && NumForCheck[1] <= 0)
        {
            // IT IS CLEARED OF ALLIES (SO DO AXIS ACTIONS)
            bCheckIfAlliesCleared = false; // stop checking

            for (i = 0; i < AxisClearedCaptureObjActions.Length; ++i)
            {
                DoObjectiveAction(AxisClearedCaptureObjActions[i]);
            }

            for (i = 0; i < AxisClearedCaptureSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AxisClearedCaptureSpawnPointActions[i]);
            }

            for (i = 0; i < AxisClearedCaptureVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AxisClearedCaptureVehiclePoolActions[i]);
            }

            if (bGroupActionsAtDisable)
            {
                HandleGroupActions(AXIS_TEAM_INDEX);
            }

            if (bDisableWhenAxisClearObj)
            {
                CurrentCapProgress = 0.0;
                bActive = false;
                SetTimer(0.0, false);
                DisableCapBarsForThisObj();

                return;
            }
            else if (!bRecaptureable)
            {
                SetTimer(0.0, false);

                return;
            }
        }
    }

    // Do nothing else if it's not active
    if (!bActive)
    {
        return;
    }

    OldCapProgress = CurrentCapProgress;

    // Figure out the rate of capture that each side is capable of
    // Rate is defined as: Number of players in the area * BaseCaptureRate * Leader bonus (if any) * Percentage of players on the team in the area
    for (i = 0; i < 2; ++i)
    {
        if (Num[i] >= PlayersNeededToCapture && bUseHardBaseRate)
        {
            Rate[i] = BaseCaptureRate;
        }
        else if (Num[i] >= PlayersNeededToCapture)
        {
            Rate[i] = FMin(Num[i] * BaseCaptureRate * LeaderBonus[i] * (float(Num[i]) / NumTotal[i]), MaxCaptureRate);
        }
        else
        {
            Rate[i] = 0.0;
        }
    }

    // Figure what the replicated # of cappers should be (to take into account the leader bonus)
    CurrentCapAxisCappers = NumForCheck[AXIS_TEAM_INDEX]; // * int(4.0 * LeaderBonus[AXIS_TEAM_INDEX]);
    CurrentCapAlliesCappers = NumForCheck[ALLIES_TEAM_INDEX]; // * int(4.0 * LeaderBonus[ALLIES_TEAM_INDEX]);

    // Note: Comparing number of players as opposed to rates to decide which side has advantage for the capture, for fear that rates could be abused in this instance
    if (ObjState != OBJ_Axis && NumForCheck[AXIS_TEAM_INDEX] > NumForCheck[ALLIES_TEAM_INDEX])
    {
        // Have to work down the progress the other team made first, but this is quickened since the fall off rate still occurs
        if (CurrentCapTeam == ALLIES_TEAM_INDEX)
        {
            CurrentCapProgress -= 0.25 * (MaxCaptureRate + Rate[AXIS_TEAM_INDEX]);
        }
        else
        {
            // Axis are contesting capture
            if (!bAxisContesting && ObjState != OBJ_Neutral) // this stops multiple actions each timer loop
            {
                HandleContestedActions(AXIS_TEAM_INDEX, true);
                bAxisContesting = true;
            }

            CurrentCapTeam = AXIS_TEAM_INDEX;
            CurrentCapProgress += 0.25 * Rate[AXIS_TEAM_INDEX];
        }
    }
    else if (ObjState != OBJ_Allies && NumForCheck[ALLIES_TEAM_INDEX] > NumForCheck[AXIS_TEAM_INDEX])
    {
        if (CurrentCapTeam == AXIS_TEAM_INDEX)
        {
            CurrentCapProgress -= 0.25 * (MaxCaptureRate + Rate[ALLIES_TEAM_INDEX]);
        }
        else
        {
            // Allies are contesting capture
            if (!bAlliesContesting && ObjState != OBJ_Neutral) //this stops multiple actions each timer loop
            {
                HandleContestedActions(ALLIES_TEAM_INDEX, true);
                bAlliesContesting = true;
            }

            CurrentCapTeam = ALLIES_TEAM_INDEX;
            CurrentCapProgress += 0.25 * Rate[ALLIES_TEAM_INDEX];
        }
    }
    else if (NumForCheck[ALLIES_TEAM_INDEX] == NumForCheck[AXIS_TEAM_INDEX] && NumForCheck[AXIS_TEAM_INDEX] != 0)
    {
        // Stalemate! No change.
    }
    else
    {
        CurrentCapProgress -= 0.25 * MaxCaptureRate;
    }

    CurrentCapProgress = FClamp(CurrentCapProgress, 0.0, 1.0);

    if (CurrentCapProgress == 0.0)
    {
        // CurrentCapProgress hit zero again, so we should check if the objective was contested and handle any necessary actions
        if (bAxisContesting)
        {
            HandleContestedActions(AXIS_TEAM_INDEX, false);
        }
        else if (bAlliesContesting)
        {
            HandleContestedActions(ALLIES_TEAM_INDEX, false);
        }

        // Contest has ended
        bAxisContesting = false;
        bAlliesContesting = false;
        CurrentCapTeam = NEUTRAL_TEAM_INDEX;
    }
    else if (CurrentCapProgress == 1.0)
    {
        ObjectiveCompleted(none, CurrentCapTeam);
    }

    // Go through and update capture bars
    for (C = Level.ControllerList; C != none; C = C.NextController)
    {
        P = DHPawn(C.Pawn);
        ROVeh = ROVehicle(C.Pawn);
        VehWepPawn = ROVehicleWeaponPawn(C.Pawn);

        if (!C.bIsPlayer)
        {
            continue;
        }

        if (P != none)
        {
            if (!bActive || !WithinArea(P))
            {
                if (P.CurrentCapArea == ObjNum)
                {
                    P.CurrentCapArea = 255;
                }
            }
            else
            {
                if (P.CurrentCapArea != ObjNum)
                {
                    P.CurrentCapArea = ObjNum;
                }

                CP = byte(Ceil(CurrentCapProgress * 100));

                // Hack to save on variables replicated (if Allies, add 100 so the range is 101-200 instead of 1-100, or just 0 if it is 0)
                if (CurrentCapTeam == ALLIES_TEAM_INDEX && CurrentCapProgress != 0.0)
                {
                    CP += 100;
                }

                if (P.CurrentCapProgress != CP)
                {
                    P.CurrentCapProgress = CP;
                }

                // Replicate # of players in capture zone
                if (P.CurrentCapAxisCappers != CurrentCapAxisCappers)
                {
                    P.CurrentCapAxisCappers = CurrentCapAxisCappers;
                }

                if (P.CurrentCapAlliesCappers != CurrentCapAlliesCappers)
                {
                    P.CurrentCapAlliesCappers = CurrentCapAlliesCappers;
                }
            }
        }

        // Draw the capture bar for rovehicles and rovehiclepawns
        if (P == none && ROVeh != none)
        {
            if (!bActive || !WithinArea(ROVeh))
            {
                if (ROVeh.CurrentCapArea == ObjNum)
                {
                    ROVeh.CurrentCapArea = 255;
                }
            }
            else
            {
                if (ROVeh.CurrentCapArea != ObjNum)
                {
                    ROVeh.CurrentCapArea = ObjNum;
                }

                CP = byte(Ceil(CurrentCapProgress * 100));

                // Hack to save on variables replicated (if Allies, add 100 so the range is 101-200 instead of 1-100, or just 0 if it is 0)
                if (CurrentCapTeam == ALLIES_TEAM_INDEX && CurrentCapProgress != 0.0)
                {
                    CP += 100;
                }

                if (ROVeh.CurrentCapProgress != CP)
                {
                    ROVeh.CurrentCapProgress = CP;
                }

                // Replicate # of players in capture zone
                if (ROVeh.CurrentCapAxisCappers != CurrentCapAxisCappers)
                {
                    ROVeh.CurrentCapAxisCappers = CurrentCapAxisCappers;
                }

                if (ROVeh.CurrentCapAlliesCappers != CurrentCapAlliesCappers)
                {
                    ROVeh.CurrentCapAlliesCappers = CurrentCapAlliesCappers;
                }
            }
        }

        if (P == none && ROVeh == none && VehWepPawn != none)
        {
            if (!bActive || !WithinArea(VehWepPawn))
            {
                if (VehWepPawn.CurrentCapArea == ObjNum)
                {
                    VehWepPawn.CurrentCapArea = 255;
                }
            }
            else
            {
                if (VehWepPawn.CurrentCapArea != ObjNum)
                {
                    VehWepPawn.CurrentCapArea = ObjNum;
                }

                CP = byte(Ceil(CurrentCapProgress * 100));

                // Hack to save on variables replicated (if Allies, add 100 so the range is 101-200 instead of 1-100, or just 0 if it is 0)
                if (CurrentCapTeam == ALLIES_TEAM_INDEX && CurrentCapProgress != 0.0)
                {
                    CP += 100;
                }

                if (VehWepPawn.CurrentCapProgress != CP)
                {
                    VehWepPawn.CurrentCapProgress = CP;
                }

                // Replicate # of players in capture zone
                if (VehWepPawn.CurrentCapAxisCappers != CurrentCapAxisCappers)
                {
                    VehWepPawn.CurrentCapAxisCappers = CurrentCapAxisCappers;
                }

                if (VehWepPawn.CurrentCapAlliesCappers != CurrentCapAlliesCappers)
                {
                    VehWepPawn.CurrentCapAlliesCappers = CurrentCapAlliesCappers;
                }
            }
        }
    }

    // Check if we should send map info change notification to players
    if (!(OldCapProgress ~= CurrentCapProgress))
    {
        // Check if we changed from 1.0 or from 0.0 (no need to send events otherwise)
        if (OldCapProgress ~= 0.0 || OldCapProgress ~= 1.0)
        {
            ROTeamGame(Level.Game).NotifyPlayersOfMapInfoChange(NEUTRAL_TEAM_INDEX, FirstCapturer);
        }
    }

    UpdateCompressedCapProgress();
}

// Overriden to the fix a console warning that would display when EventInstigator was none.
function Trigger(Actor Other, Pawn EventInstigator)
{
    local PlayerReplicationInfo PRI;

    if (!bActive || ROTeamGame(Level.Game) == none || !ROTeamGame(Level.Game).IsInState('RoundInPlay'))
    {
        return;
    }

    if (EventInstigator != none)
    {
        PRI = EventInstigator.PlayerReplicationInfo;
    }

    if (ObjState == OBJ_Axis)
    {
        ObjectiveCompleted(PRI, ALLIES_TEAM_INDEX);
    }
    else if (ObjState == OBJ_Allies)
    {
        ObjectiveCompleted(PRI, AXIS_TEAM_INDEX);
    }
}

defaultproperties
{
    bDoNotUseLabelShiftingOnSituationMap=true
    Texture=texture'DHEngine_Tex.Objective'
    bVehiclesCanCapture=true
    bTankersCanCapture=true
    bResetDeathPenalties=true
    PlayersNeededToCapture=1
}
