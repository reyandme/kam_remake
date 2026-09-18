unit KM_GUICampaignMapView;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Math,
  KM_Controls, KM_ControlsBase,
  KM_Campaigns;

const
  MAP_DESIGN_W = 1024;
  MAP_DESIGN_H = 768;

  FLAG_TEX_LOCKED = 10;
  FLAG_TEX_UNLOCKED = 11;
  FLAG_W = 23;
  FLAG_H = 29;

  FLAG_LABEL_OFFSET_X = 10;
  FLAG_LABEL_OFFSET_Y = 7;

  NODE_TEX = 16;
  NODE_LABEL_OFFSET_X = 7;
  NODE_LABEL_OFFSET_Y = 2;

type
  TKMCampaignMapStyle = (cmUndefined, cmScreen, cmPreview);

  TKMCampaignMapView = class(TKMPanel)
  private
    fStyle: TKMCampaignMapStyle;
    fCampaign: TKMCampaign;
    fNodeSize: Integer;

    fImageBG: TKMImage;
    fPanelMarks: TKMPanel;

    fFlags: array[0..MAX_CAMP_MAPS - 1] of TKMImage;
    fFlagLabels: array[0..MAX_CAMP_MAPS - 1] of TKMLabel;
    fNodes: array[0..MAX_CAMP_NODES - 1] of TKMImage;
    fNodeLabels: array[0..MAX_CAMP_NODES - 1] of TKMLabel;

    function GetFlag(aIndex: Integer): TKMImage;
    function GetFlagLabel(aIndex: Integer): TKMLabel;
    function GetNode(aIndex: Integer): TKMImage;
    function GetNodeLabel(aIndex: Integer): TKMLabel;
    procedure PlaceFlagLabel(aIndex: Integer);
    procedure PlaceNodeLabel(aIndex: Integer);
  public
    constructor Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aStyle: TKMCampaignMapStyle;
                       aNodeSize: Integer = 0; aNodeLabels: Boolean = False);

    property Campaign: TKMCampaign read fCampaign;
    property Background: TKMImage read fImageBG;
    property Flags[aIndex: Integer]: TKMImage read GetFlag;
    property FlagLabels[aIndex: Integer]: TKMLabel read GetFlagLabel;
    property Nodes[aIndex: Integer]: TKMImage read GetNode;
    property NodeLabels[aIndex: Integer]: TKMLabel read GetNodeLabel;

    procedure SetCampaign(aCampaign: TKMCampaign);
    procedure RefreshBackground;
    procedure Clear;

    procedure ResizeToScreen(aScreenHeight: Word);

    procedure PlaceFlag(aIndex: Integer);
    procedure PlaceFlags;
    procedure PlaceNode(aMapIndex, aNodeIndex: Integer);

    procedure StoreFlag(aIndex: Integer);
    procedure StoreNode(aMapIndex, aNodeIndex: Integer);
  end;


implementation
uses
  KM_Defaults, KM_ResTypes, KM_ResFonts, KM_RenderUI;


{ TKMCampaignMapView }
constructor TKMCampaignMapView.Create(aParent: TKMPanel; aLeft, aTop, aWidth, aHeight: Integer; aStyle: TKMCampaignMapStyle;
                                      aNodeSize: Integer = 0; aNodeLabels: Boolean = False);
var
  I: Integer;
begin
  inherited Create(aParent, aLeft, aTop, aWidth, aHeight);

  fStyle := aStyle;
  fNodeSize := aNodeSize;

  fImageBG := TKMImage.Create(Self, 0, 0, aWidth, aHeight, 0, rxGuiMain);
  fImageBG.ImageStretch;

  if fStyle = cmPreview then
    Exit;

  fPanelMarks := TKMPanel.Create(Self, 0, 0, aWidth, aHeight);
  fPanelMarks.AnchorsStretch;

  for I := 0 to High(fFlags) do
  begin
    fFlags[I] := TKMImage.Create(fPanelMarks, aWidth, aHeight, FLAG_W, FLAG_H, FLAG_TEX_LOCKED, rxGuiMain);

    fFlagLabels[I] := TKMLabel.Create(fPanelMarks, aWidth, aHeight, IntToStr(I + 1), fntMini, taCenter);
    fFlagLabels[I].FontColor := icLightGray2;
    fFlagLabels[I].Hitable := False;
  end;

  for I := 0 to High(fNodes) do
  begin
    fNodes[I] := TKMImage.Create(fPanelMarks, aWidth, aHeight, fNodeSize, fNodeSize, NODE_TEX, rxGuiMain);
    fNodes[I].ImageCenter;

    if aNodeLabels then
    begin
      fNodeLabels[I] := TKMLabel.Create(fPanelMarks, aWidth, aHeight, IntToStr(I + 1), fntMini, taCenter);
      fNodeLabels[I].FontColor := icLightGray2;
      fNodeLabels[I].Hitable := False;
    end;
  end;
end;


function TKMCampaignMapView.GetFlag(aIndex: Integer): TKMImage;
begin
  Result := fFlags[aIndex];
end;


function TKMCampaignMapView.GetFlagLabel(aIndex: Integer): TKMLabel;
begin
  Result := fFlagLabels[aIndex];
end;


function TKMCampaignMapView.GetNode(aIndex: Integer): TKMImage;
begin
  Result := fNodes[aIndex];
end;


function TKMCampaignMapView.GetNodeLabel(aIndex: Integer): TKMLabel;
begin
  Result := fNodeLabels[aIndex];
end;


procedure TKMCampaignMapView.SetCampaign(aCampaign: TKMCampaign);
begin
  fCampaign := aCampaign;
  RefreshBackground;
end;


procedure TKMCampaignMapView.RefreshBackground;
begin
  if fCampaign = nil then
    Exit;

  fImageBG.RX := fCampaign.BackGroundPic.RX;
  fImageBG.TexID := fCampaign.BackGroundPic.ID;
end;


procedure TKMCampaignMapView.Clear;
var
  I: Integer;
begin
  fCampaign := nil;
  fImageBG.TexID := 0;

  if fStyle = cmPreview then
    Exit;

  for I := 0 to High(fFlags) do
  begin
    fFlags[I].Hide;
    fFlagLabels[I].Hide;
  end;
end;


procedure TKMCampaignMapView.ResizeToScreen(aScreenHeight: Word);
begin
  Assert(fStyle = cmScreen);

  fPanelMarks.Scale := Min(MAP_DESIGN_H, aScreenHeight) / MAP_DESIGN_H;
  fPanelMarks.Left := Round(MAP_DESIGN_W * (1 - fPanelMarks.Scale) / 2);
  fImageBG.Left := fPanelMarks.Left;
  fImageBG.Height := Min(MAP_DESIGN_H, aScreenHeight);
  fImageBG.Width := Round(MAP_DESIGN_W * fPanelMarks.Scale);

  PlaceFlags;
end;


procedure TKMCampaignMapView.PlaceFlagLabel(aIndex: Integer);
begin
  fFlagLabels[aIndex].AbsLeft := fFlags[aIndex].AbsLeft + FLAG_LABEL_OFFSET_X;
  fFlagLabels[aIndex].AbsTop := fFlags[aIndex].AbsTop + FLAG_LABEL_OFFSET_Y;
end;


procedure TKMCampaignMapView.PlaceFlag(aIndex: Integer);
var
  scale: Single;
begin
  if (fCampaign = nil) or (aIndex >= fCampaign.Spec.MissionsCount) then
    Exit;

  scale := fPanelMarks.Scale;
  fFlags[aIndex].Left := fCampaign.Spec.Maps[aIndex].Flag.X - Round((fFlags[aIndex].Width / 2) * (1 - scale));
  fFlags[aIndex].Top := fCampaign.Spec.Maps[aIndex].Flag.Y - Round(fFlags[aIndex].Height * (1 - scale));

  PlaceFlagLabel(aIndex);
end;


procedure TKMCampaignMapView.PlaceFlags;
var
  I: Integer;
begin
  if fCampaign = nil then
    Exit;

  for I := 0 to fCampaign.Spec.MissionsCount - 1 do
    PlaceFlag(I);
end;


procedure TKMCampaignMapView.PlaceNodeLabel(aIndex: Integer);
begin
  if fNodeLabels[aIndex] = nil then
    Exit;

  fNodeLabels[aIndex].AbsLeft := fNodes[aIndex].AbsLeft + NODE_LABEL_OFFSET_X;
  fNodeLabels[aIndex].AbsTop := fNodes[aIndex].AbsTop + NODE_LABEL_OFFSET_Y;
end;


procedure TKMCampaignMapView.PlaceNode(aMapIndex, aNodeIndex: Integer);
begin
  if fCampaign = nil then
    Exit;

  fNodes[aNodeIndex].Left := fCampaign.Spec.Maps[aMapIndex].Nodes[aNodeIndex].X - fNodeSize div 2;
  fNodes[aNodeIndex].Top := fCampaign.Spec.Maps[aMapIndex].Nodes[aNodeIndex].Y - fNodeSize div 2;

  PlaceNodeLabel(aNodeIndex);
end;


procedure TKMCampaignMapView.StoreFlag(aIndex: Integer);
var
  scale: Single;
begin
  Assert(fStyle = cmScreen);

  scale := fPanelMarks.Scale;
  fCampaign.Spec.Maps[aIndex].Flag.X := fFlags[aIndex].Left + Round((fFlags[aIndex].Width / 2) * (1 - scale));
  fCampaign.Spec.Maps[aIndex].Flag.Y := fFlags[aIndex].Top + Round(fFlags[aIndex].Height * (1 - scale));

  PlaceFlagLabel(aIndex);
end;


procedure TKMCampaignMapView.StoreNode(aMapIndex, aNodeIndex: Integer);
begin
  fCampaign.Spec.Maps[aMapIndex].Nodes[aNodeIndex].X := fNodes[aNodeIndex].Left + fNodeSize div 2;
  fCampaign.Spec.Maps[aMapIndex].Nodes[aNodeIndex].Y := fNodes[aNodeIndex].Top + fNodeSize div 2;

  PlaceNodeLabel(aNodeIndex);
end;


end.
