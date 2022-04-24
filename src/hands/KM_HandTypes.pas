unit KM_HandTypes;
interface
uses
  KM_ResFonts;

type
  TKMHandType = (
    hndHuman,
    hndComputer
  );

  TKMHandEntityType = (etNone, etUnit, etGroup, etHouse);

  //* House lock state
  TKMHandHouseLock = (
    hlNone,
    hlDefault,
    hlBlocked, // Never allowed
    hlGranted // Always allowed
  );

  TKMOverlayTextSettings = record
    WordWrap: Boolean;
    Font: TKMFont;
  end;

const
  HAND_NONE = -1; //No player
  HAND_ANIMAL = -2; //animals

const
  DELIVERY_NO_ID = -1;

implementation

end.
