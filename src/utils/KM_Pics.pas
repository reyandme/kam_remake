unit KM_Pics;
{$I KaM_Remake.inc}
interface


type
  TRXType = (
    rxTrees,
    rxHouses,
    rxUnits,
    rxGui,
    rxGuiMain,
    rxCustom, //Used for loading stuff like campaign maps (there is no main RXX file)
    rxTiles //Tiles
    );

  TKMPic = record
    RX: TRXType;
    ID: Word;
    HighlightOnMouseOver: Boolean;
    OffsetY: Integer;
    OffsetX: Integer;
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
