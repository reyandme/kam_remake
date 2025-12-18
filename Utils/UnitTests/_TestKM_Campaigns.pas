unit TestKM_Campaigns;
interface
uses
  TestFramework, SysUtils, KM_Points, KM_Defaults, KM_CommonClasses, Classes, KromUtils,
  KM_Campaigns, KM_ResLocales, KM_Log, KM_ResTexts, KM_Resource, Math;

type
  // Test methods for class TKMCampaign
  TestTKMCampaign = class(TTestCase)
  strict private
    FKMCampaign: TKMCampaign;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestLoadFromFile;
    procedure TestSaveToFile;
    procedure TestLoadFromPath;
    procedure TestMissionFile;
    procedure TestMissionTitle;
    procedure TestMissionText;
  end;

implementation
uses
  KM_ResTypes;

procedure TestTKMCampaign.SetUp;
begin
  ExeDir := ExtractFilePath(ParamStr(0)) + '..\';
  FKMCampaign := TKMCampaign.Create;
  gLog := TKMLog.Create(ExtractFilePath(ParamStr(0)) + 'Temp\temp.log');
  gRes := TKMResource.Create(nil, nil);
end;

procedure TestTKMCampaign.TearDown;
begin
  gRes.Free;
  gLog.Free;
  FKMCampaign.Free;
  FKMCampaign := nil;
end;

procedure TestTKMCampaign.TestLoadFromFile;
begin
  FKMCampaign.LoadFromFile('..\Campaigns\The Shattered Kingdom\info.cmp');

  Check(FKMCampaign.MapCount = 20);
  Check(FKMCampaign.Maps[0].NodeCount > 0);
  Check(FKMCampaign.ShortName <> '');
  Check(FKMCampaign.UnlockedMap = 0);
  Check(FKMCampaign.GetMissionFile(0) <> '');

  //Pic is assigned in LoadFromPath
  Check(FKMCampaign.BackGroundPic.RX = rxTrees);
  Check(FKMCampaign.BackGroundPic.ID = 0);
end;

procedure TestTKMCampaign.TestSaveToFile;
var
  FileLoad, FileSave: string;
begin
  //Test with sample file
  FileLoad := ExtractFilePath(ParamStr(0)) + '..\Campaigns\The Shattered Kingdom\info.cmp';
  FileSave := ExtractFilePath(ParamStr(0)) + 'Temp\campaign.tmp';
  ForceDirectories(ExtractFilePath(FileSave));
  FKMCampaign.LoadFromFile(FileLoad);
  FKMCampaign.SaveToFile(FileSave);
  Check(CheckSameContents(FileLoad, FileSave));
end;

procedure TestTKMCampaign.TestLoadFromPath;
begin
  //
end;

procedure TestTKMCampaign.TestMissionFile;
begin
  FKMCampaign.LoadFromFile('..\Campaigns\The Shattered Kingdom\info.cmp');
  Check(FKMCampaign.GetMissionFile(0) = 'TSK01\TSK01.dat', 'Unexpected result: ' + FKMCampaign.GetMissionFile(0));
  FKMCampaign.LoadFromFile('..\Campaigns\The Peasants Rebellion\info.cmp');
  Check(FKMCampaign.GetMissionFile(0) = 'TPR01\TPR01.dat', 'Unexpected result: ' + FKMCampaign.GetMissionFile(0));
end;

procedure TestTKMCampaign.TestMissionTitle;
begin
  //FKMCampaign.MissionTitle(aIndex);
end;

procedure TestTKMCampaign.TestMissionText;
begin
  //ReturnValue := FKMCampaign.MissionText(aIndex);
end;

initialization
  // Register any test cases with the test runner
  RegisterTest(CAMPAIGNS_FOLDER_NAME, TestTKMCampaign.Suite);

end.

