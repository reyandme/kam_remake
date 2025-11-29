unit MapUtilTypes;
interface

type
  TFOWType = (ftRevealAll, ftRevealPlayers, ftMapSetting);

  TCLIParamRecord = record
    MapDatPath: string;
    ShowHelp: Boolean;
    FOWType: TFOWType;
    OutputFile: string;
  end;

implementation

end.
