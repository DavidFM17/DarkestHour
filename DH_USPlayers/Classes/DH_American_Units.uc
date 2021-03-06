//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_American_Units extends DHRoleInfo
    abstract;

defaultproperties
{
    Texture=texture'DHEngine_Tex.Allies_RoleInfo'
    HeadgearProbabilities(0)=0.2
    HeadgearProbabilities(1)=0.8
    SleeveTexture=texture'DHUSCharactersTex.Sleeves.US_sleeves'
    VoiceType="DH_USPlayers.DHUSVoice"
    AltVoiceType="DH_USPlayers.DHUSVoice"
    DetachedArmClass=class'ROEffects.SeveredArmSovTunic'
    DetachedLegClass=class'ROEffects.SeveredLegSovTunic'
    Side=SIDE_Allies
}
