//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_DP28ClientTracer extends ROClientTracer;

// Theel: Do I need to change the tracer classes? Why green tracers?
defaultproperties
{
    LightHue=80
    LightSaturation=128
    LightRadius=10.0
    Bounces=1
    //compile error  StaticMesh=StaticMesh'DH_ROTracers.Russ_Tracer'
    //compile error  DeflectedMesh=StaticMesh'DH_ROTracers.Russ_Tracer_Ball'
    SpeedFudgeScale=0.5
    BallisticCoefficient=0.511
    Speed=50696.0 // 840 m/s
    DrawType=DT_StaticMesh
    mTracerClass=class'DH_Effects.DHShellTracer_Green'
    DrawScale=2.0
}