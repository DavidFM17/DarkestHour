//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DH_OpelBlitzTransport_NoTarp extends DH_OpelBlitzTransport;

defaultproperties
{
    DestroyedVehicleMesh=StaticMesh'DH_German_vehicles_stc.Trucks.OpelBlitz_noTarp_dest'
    Mesh=SkeletalMesh'DH_OpelBlitz_anm.OpelBlitz_body_extNT'
    SpawnOverlay(0)=material'DH_InterfaceArt_tex.Vehicles.opelblitz_notarp'
}
