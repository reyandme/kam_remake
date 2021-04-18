unit KM_InputLog;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  Generics.Collections;


type


  TKMInputKind = (ikNone,
                  ikMouseDown,  // X, Y, Btn, Shift
                  ikMouseMove,  // X, Y, Shift
                  ikMouseUp,    // X, Y, Btn, Shift
                  ikKeyDown,  // Key, Shift
                  ikKeyPress, // Key (Char)
                  ikKeyUp);   // Key, Shift

  TKMInputData = record
    Kind: TKMInputKind; // 1
    Time: Cardinal;     // 4
    Shift: TShiftState; // 1
    X, Y: SmallInt;     // 4
//    Btn: Byte;        // 1
    Key: Word;          // 2
  end;

  TKMInputLogger = class
  private
    fInputList: TList<TKMInputData>;
  public

  end;

implementation

end.

