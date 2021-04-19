unit KM_RenderTypes;
{$I KaM_Remake.inc}
interface

type
  TTexFormat = (
    tfRGB5A1,
    tfRGBA8,
    tfAlpha8 //Mask used for team colors and house construction steps (GL_ALPHA)
    );

  TFilterType = (
    ftNearest,
    ftLinear
  );

implementation


end.
