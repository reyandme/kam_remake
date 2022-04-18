unit KM_UnitGroupTypes;
interface
uses
  KM_Points;

type
  // Unit Group types
  TKMGroupInitialOrder = (gioNoOrder, gioSendGroup, gioAttackPosition);
  TKMOrderWalkKind = (wtokNone,
                      wtokPlayerOrder,  //player order
                      wtokHaltOrder,    //could be player order, or AI order (as part of OrderRepeat)
                      wtokFlagPoint,    //after warrior get out of barracks/townhall
                      wtokAISquad, wtokAIGotoDefencePos, wtokAIAttackCustomPos, //initiated by AI
                      wtokMissionScript, wtokScript); //initiated by mission script or script
  TKMOrderWalkKindSet = set of TKMOrderWalkKind;

  //* Group order
  TKMGroupOrder = (
    goNone,         // Last order was executed and now we have nothing to do
    goWalkTo,       // Ordered to walk somewhere or just change formation
    goAttackHouse,  // Attack house
    goAttackUnit,   // Attack specific unit
    goStorm         // Run forward
  );

  //MapEd allows to set order for a group that will be executed on mission start
  TKMMapEdOrder = record
    Order: TKMGroupInitialOrder;
    Pos: TKMPointDir;
  end;

implementation


end.

