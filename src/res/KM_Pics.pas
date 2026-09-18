unit KM_Pics;
{$I KaM_Remake.inc}
interface
uses
  KM_ResTypes;


type
  TKMPic = record
    RX: TRXType;
    ID: Word;
    HighlightOnMouseOver: Boolean;
    OffsetX: Integer;
    OffsetY: Integer;
  end;

  function MakePic(aRX: TRXType; aIndex: Word; aHighlightOnMouseOver: Boolean = False; aOffsetX: Integer = 0; aOffsetY: Integer = 0): TKMPic;


implementation


function MakePic(aRX: TRXType; aIndex: Word; aHighlightOnMouseOver: Boolean = False; aOffsetX: Integer = 0; aOffsetY: Integer = 0): TKMPic;
begin
  Result.RX := aRX;
  Result.ID := aIndex;
  Result.HighlightOnMouseOver := aHighlightOnMouseOver;
  Result.OffsetX := aOffsetX;
  Result.OffsetY := aOffsetY;
end;


end.
