unit KM_NetFileTransfer;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, Math, KM_Defaults, KM_CommonClasses, KM_NetworkTypes, KM_MapTypes
  {$IFDEF FPC}, zstream {$ENDIF}
  {$IFDEF WDC}, ZLib {$ENDIF};

const MAX_TRANSFERS = MAX_LOBBY_SLOTS - 1; //One for each player and spectator
type
  TTransferEvent = procedure(aClientIndex: TKMNetHandleIndex) of object;
  TTransferPacketEvent = procedure(aClientIndex: TKMNetHandleIndex; aStream: TKMemoryStream; out SendBufferEmpty: Boolean) of object;
  TTransferProgressEvent = procedure(Total, Progress: Cardinal) of object;
  TTransferProgressPlayerEvent = procedure(aNetPlayerIndex: Integer; Total, Progress: Cardinal) of object;
  TKMTransferType = (kttMap, kttSave);

  TKMFileSender = class
  private
    fReceiverIndex: TKMNetHandleIndex;
    fChunksInFlight: Byte;
    fSendStream: TKMemoryStream;
    procedure AddFileToStream(const aFileName, aPostFix, aExt: UnicodeString);
  public
    constructor Create(aType: TKMTransferType; const aName: UnicodeString; aMapKind: TKMMapKind; aReceiverIndex: TKMNetHandleIndex);
    destructor Destroy; override;
    procedure WriteChunk(aStream: TKMemoryStream; aLength: Cardinal);
    procedure AckReceived;
    function StreamEnd: Boolean;
    property ReceiverIndex: TKMNetHandleIndex read fReceiverIndex;
  end;

  TKMFileReceiver = class
  private
    fReceiveStream: TKMemoryStream;
    fType: TKMTransferType;
    fName: UnicodeString;
    fMapCRC: Cardinal;
    fTotalSize: Cardinal;
    fReceivedSize: Cardinal;
    procedure ClearExistingFiles;
    function ValidExtension(const Ext: UnicodeString): Boolean;
  public
    constructor Create(aType: TKMTransferType; const aName: UnicodeString; aMapCRC: Cardinal = 0);
    destructor Destroy; override;
    procedure DataReceived(aStream: TKMemoryStream);
    property Name: UnicodeString read fName;
    property TotalSize: Cardinal read fTotalSize;
    property ReceivedSize: Cardinal read fReceivedSize;
    function ProcessTransfer: Boolean;
  end;

  TKMFileSenderManager = class
  private
    fSenders: array[1..MAX_TRANSFERS] of TKMFileSender;
    fOnTransferCompleted: TTransferEvent;
    fOnTransferPacket: TTransferPacketEvent;
    function ActiveTransferCount: Byte;
  public
    destructor Destroy; override;
    function StartNewSend(aType: TKMTransferType; const aName: String; aMapKind: TKMMapKind;
                          aReceiverIndex: TKMNetHandleIndex): Boolean;
    procedure AbortAllTransfers;
    procedure AckReceived(aReceiverIndex: TKMNetHandleIndex);
    procedure ClientDisconnected(aReceiverIndex: TKMNetHandleIndex);
    procedure UpdateStateIdle(SendBufferEmpty: Boolean);
    property OnTransferCompleted: TTransferEvent write fOnTransferCompleted;
    property OnTransferPacket: TTransferPacketEvent write fOnTransferPacket;
  end;

implementation
uses
  KromUtils, KM_Maps, KM_Saves,
  KM_ScriptPreProcessor, KM_ScriptFilesCollection,
  KM_Log, KM_FileIO;

const
  //todo: Add LIBX and WAV support for maps
  VALID_MAP_EXTENSIONS:  array[1..5] of UnicodeString =         ('map','dat',EXT_FILE_SCRIPT,'txt','pdf');
  VALID_MAP_EXTENSIONS_POSTFIX:  array[1..4] of UnicodeString = ('libx','wav','ogg','pdf');
//  VALID__MAP_EXT_DOUBLE_POSTFIX
  VALID_SAVE_EXTENSIONS: array[1..3] of UnicodeString =         (EXT_SAVE_MAIN, EXT_SAVE_BASE, EXT_SAVE_REPLAY);


function GetFullSourceFileName(aType: TKMTransferType; const aName: String; aMapKind: TKMMapKind;
                               const aPostfix, aExt: UnicodeString): String;
begin
  case aType of
    kttMap:  Result := TKMapsCollection.FullPath(aName, aPostfix + '.' + aExt, aMapKind);
    kttSave: Result := TKMSavesCollection.FullPath(aName, aExt, True);
  end;
end;


function GetFullDestFileName(aType: TKMTransferType; const aName, Postfix, aExt: String;
                             const aCustomFileName: UnicodeString = ''): String;
begin
  case aType of
    kttMap:   if aCustomFileName = '' then
                Result := TKMapsCollection.FullPath(aName, Postfix + '.' + aExt, mkDL)
              else
                Result := TKMapsCollection.FullPath(aName, aCustomFileName, Postfix + '.' + aExt, mkDL);
    kttSave: Result := TKMSavesCollection.Path(DOWNLOADED_LOBBY_SAVE, True) + DOWNLOADED_LOBBY_SAVE + '.' + aExt;
  end;
end;


{ TKMFileSender }
constructor TKMFileSender.Create(aType: TKMTransferType; const aName: UnicodeString; aMapKind: TKMMapKind;
                                 aReceiverIndex: TKMNetHandleIndex);
var
  I, J: Integer;
  F: TSearchRec;
  fileName, postfix: UnicodeString;
  sourceStream: TKMemoryStream;
  compressionStream: TCompressionStream;
  scriptPreProcessor: TKMScriptPreProcessor;
  scriptFiles: TKMScriptFilesCollection;
begin
  inherited Create;
  fReceiverIndex := aReceiverIndex;
  fSendStream := TKMemoryStreamBinary.Create;
  fSendStream.PlaceMarker('TransferCompressed');
  fSendStream.Write(aType, SizeOf(aType));
  fSendStream.WriteW(aName);
  //Fill stream with data to be sent
  case aType of
  kttMap: begin
            // Supports next file names:
            // MapName.dat
            // MapName.map
            // MapName.txt
            // MapName.pdf
            // MapName.script + any included script
            for I := Low(VALID_MAP_EXTENSIONS) to High(VALID_MAP_EXTENSIONS) do
            begin
              fileName := GetFullSourceFileName(aType, aName, aMapKind, '', VALID_MAP_EXTENSIONS[I]);
              if FileExists(fileName) then
                AddFileToStream(fileName, '', VALID_MAP_EXTENSIONS[I]);
              //Add all included script files
              if (VALID_MAP_EXTENSIONS[I] = EXT_FILE_SCRIPT) and FileExists(fileName) then
              begin
                scriptPreProcessor := TKMScriptPreProcessor.Create(False);
                try
                  if not scriptPreProcessor.PreProcessFile(fileName) then
                    //throw an Exception if PreProcessor was not successful to cancel FileSender creation
                    raise Exception.Create('Can''n start send file because of error while script pre-processing');
                  scriptFiles := scriptPreProcessor.ScriptFilesInfo;
                  for J := 0 to scriptFiles.IncludedCount - 1 do
                  begin
                    if FileExists(scriptFiles[J].FullFilePath) then
                      AddFileToStream(scriptFiles[J].FullFilePath, '', EXT_FILE_SCRIPT);
                  end;
                finally
                  scriptPreProcessor.Free;
                end;
              end;
            end;
            // Supports next file names:
            // MapName.snd_name.wav / .ogg
            // MapName.snd_name.eng.wav / .ogg
            // MapName.eng.libx
            // MapName.eng.pdf
            for I := Low(fileName) to High(VALID_MAP_EXTENSIONS_POSTFIX) do
            begin
              fileName := GetFullSourceFileName(aType, aName, aMapKind, '.*', VALID_MAP_EXTENSIONS_POSTFIX[I]);
              try
                if FindFirst(fileName, faAnyFile, F) = 0 then
                begin
                  repeat
                    if (F.Attr and faDirectory = 0) then
                    begin
                      // Find everything except map name and extension
                      // Cut ext with dot
                      postfix := ChangeFileExt(F.Name, '');
                      // Find 'MapName.'
                      if Pos(aName + '.', postfix) = 1 then
                        // Copy '.snd_name.eng'
                        postfix := Copy(postfix, Length(aName) + 1, Length(postfix))
                      else
                        // No postfix was found
                        postfix := '';

                      AddFileToStream(ExtractFilePath(fileName) + F.Name, postfix, VALID_MAP_EXTENSIONS_POSTFIX[I]);
                    end;
                  until FindNext(F) <> 0;
                end;
              finally
                FindClose(F);
              end;
            end;
          end;
    kttSave: for I := Low(VALID_SAVE_EXTENSIONS) to High(VALID_SAVE_EXTENSIONS) do
             begin
               fileName := TKMSavesCollection.FullPath(aName, VALID_SAVE_EXTENSIONS[I], True);
               if FileExists(fileName) then
                 AddFileToStream(fileName, '', VALID_SAVE_EXTENSIONS[I]);
             end;
  end;
  //Compress fSendStream
  sourceStream := fSendStream;
  fSendStream := TKMemoryStreamBinary.Create;
  fSendStream.PlaceMarker('Transfer');
  compressionStream := TCompressionStream.Create(cldefault, fSendStream);
  compressionStream.CopyFrom(sourceStream, 0);
  //fSendStream now contains the compressed data from SourceStream
  compressionStream.Free;
  sourceStream.Free;
  fSendStream.Position := 0;
end;


destructor TKMFileSender.Destroy;
begin
  fSendStream.Free;
  inherited;
end;


procedure TKMFileSender.AckReceived;
begin
  Dec(fChunksInFlight);
end;


procedure TKMFileSender.AddFileToStream(const aFileName, aPostFix, aExt: UnicodeString);
var
  FileStream: TKMemoryStream;
begin
  FileStream := TKMemoryStreamBinary.Create;
  FileStream.LoadFromFile(aFileName);

  fSendStream.PlaceMarker('FileStart');
  fSendStream.WriteW(TruncateExt(ExtractFileName(aFileName)));
  fSendStream.WriteW(aPostFix);
  fSendStream.WriteW(aExt);
  fSendStream.Write(Cardinal(FileStream.Size));
  if FileStream.Size > 0 then
    fSendStream.CopyFrom(FileStream, FileStream.Size);

  FileStream.Free;
end;


procedure TKMFileSender.WriteChunk(aStream: TKMemoryStream; aLength: Cardinal);
begin
  if aLength > fSendStream.Size - fSendStream.Position then
    aLength := fSendStream.Size - fSendStream.Position;

  aStream.PlaceMarker('FileChunk');
  aStream.Write(aLength);
  aStream.Write(Cardinal(fSendStream.Size)); //Every chunk includes the total transfer size
  aStream.CopyFrom(fSendStream, aLength);
  Inc(fChunksInFlight);
end;


function TKMFileSender.StreamEnd: Boolean;
begin
  Result := fSendStream.Position = fSendStream.Size;
end;


{ TKMFileReceiver }
constructor TKMFileReceiver.Create(aType: TKMTransferType; const aName: UnicodeString; aMapCRC: Cardinal = 0);
begin
  inherited Create;
  fReceiveStream := TKMemoryStreamBinary.Create;
  fType := aType;
  fName := aName;
  fMapCRC := aMapCRC;
end;


destructor TKMFileReceiver.Destroy;
begin
  fReceiveStream.Free;
  inherited;
end;


procedure TKMFileReceiver.DataReceived(aStream: TKMemoryStream);
var
  chunkSize: Cardinal;
begin
  aStream.CheckMarker('FileChunk');
  aStream.Read(chunkSize);
  aStream.Read(fTotalSize); //Every chunk includes the total transfer size
  Assert(aStream.Size - aStream.Position = chunkSize, 'Chunk corrupted');
  fReceiveStream.CopyFrom(aStream, chunkSize);
  fReceivedSize := fReceivedSize + chunkSize;
end;


procedure TKMFileReceiver.ClearExistingFiles;
var
  F: TSearchRec;
  fileName, saveFolder: UnicodeString;
begin
  //Prepare destination
  case fType of
    kttMap:   begin
                //Create downloads folder if it's missing
                fileName := ExeDir + MAPS_DL_FOLDER_NAME;
                if not DirectoryExists(fileName) then
                  CreateDir(fileName);
                //Create map folder if it is missing
                fileName := fileName + PathDelim + fName;
                if not DirectoryExists(fileName) then
                  CreateDir(fileName)
                else
                  try
                    //If any files already exist in the folder, delete them
                    if FindFirst(fileName + PathDelim + fName + '*.*', faAnyFile, F) = 0 then
                    begin
                      repeat
                        if (F.Attr and faDirectory = 0) then
                          KMDeleteFile(fileName + PathDelim + F.Name);
                      until FindNext(F) <> 0;
                    end;
                  finally
                    FindClose(F);
                  end;
              end;
    kttSave:  begin
                saveFolder := TKMSavesCollection.Path(DOWNLOADED_LOBBY_SAVE, True);
                KMDeleteFolder(saveFolder);   // Delete old folder
                ForceDirectories(saveFolder); // Create new
              end;
  end;
end;


function TKMFileReceiver.ValidExtension(const Ext: UnicodeString): Boolean;
var 
  I: Integer;
begin
  case fType of
    kttMap: begin
               for I := Low(VALID_MAP_EXTENSIONS) to High(VALID_MAP_EXTENSIONS) do
                 if Ext = VALID_MAP_EXTENSIONS[I] then
                 begin
                   Result := True;
                   Exit;
                 end;
               for I := Low(VALID_MAP_EXTENSIONS_POSTFIX) to High(VALID_MAP_EXTENSIONS_POSTFIX) do
                 if Ext = VALID_MAP_EXTENSIONS_POSTFIX[I] then
                 begin
                   Result := True;
                   Exit;
                 end;
            end;
    kttSave: for I := Low(VALID_SAVE_EXTENSIONS) to High(VALID_SAVE_EXTENSIONS) do
               if Ext = VALID_SAVE_EXTENSIONS[I] then
               begin
                 Result := True;
                 Exit;
               end;
  end;
  Result := False;
end;


function TKMFileReceiver.ProcessTransfer: Boolean;
var
  readType: TKMTransferType;
  readName, ext, postfix, transferedFileName, fileName: UnicodeString;
  readSize: Cardinal;
  fileStream: TKMemoryStream;
  decompressionStream: TDecompressionStream;
  readStream: TKMemoryStream;
begin
  Result := False;
  if fReceiveStream.Size = 0 then Exit; //Transfer was aborted

  //Decompress the stream
  fReceiveStream.Position := 0;
  fReceiveStream.CheckMarker('Transfer');
  decompressionStream := TDecompressionStream.Create(fReceiveStream);
  //We need custom methods like ReadAssert, ReadW, etc. so we need to read from a TKMemoryStream
  readStream := TKMemoryStreamBinary.Create;
  readStream.CopyFromDecompression(decompressionStream);
  decompressionStream.Free;
  readStream.Position := 0;

  //Read from the stream
  readStream.CheckMarker('TransferCompressed');
  readStream.Read(readType, SizeOf(readType));
  Assert(readType = fType, 'Unexpected transfer type received');
  readStream.ReadW(readName);
  if (readName <> fName) and (readName + '_' + IntToHex(fMapCRC, 8) <> fName) then
    raise Exception.Create('Unexpected transfer name received');

  ClearExistingFiles;

  //Load each file
  while readStream.Position < readStream.Size do
  begin
    readStream.CheckMarker('FileStart');
    readStream.ReadW(transferedFileName);
    readStream.ReadW(postfix);
    readStream.ReadW(ext);
    //Check EXT is valid (so we don't allow EXEs and stuff)
    Assert(ValidExtension(ext), 'Unexpected file extension received');

    readStream.Read(readSize);
    fileStream := TKMemoryStreamBinary.Create;
    // Don't try to CopyFrom, if file is empty!
    // because, according to http://docwiki.embarcadero.com/Libraries/Sydney/en/System.Classes.TStream.CopyFrom
    // > If Count is 0, CopyFrom sets Source position to 0 before reading and then copies the entire contents of Source into the stream
    if readSize > 0 then
      fileStream.CopyFrom(readStream, readSize);

    // Scripts can have arbitrary names
    if (ext = EXT_FILE_SCRIPT) and (transferedFileName <> readName) then
      fileName := GetFullDestFileName(fType, fName, postfix, ext, transferedFileName)
    else
      fileName := GetFullDestFileName(fType, fName, postfix, ext);

    // Sometimes the file is not deleted yet. Probably OS glitches
    if FileExists(fileName) then
      KMDeleteFile(fileName);

    fileStream.SaveToFile(fileName);
    fileStream.Free;
  end;
  readStream.Free;
  Result := True;
end;


{ TKMFileSenderManager }
procedure TKMFileSenderManager.AbortAllTransfers;
var 
  I: Integer;
begin
  for I := Low(fSenders) to High(fSenders) do
    FreeAndNil(fSenders[I]);
end;


procedure TKMFileSenderManager.AckReceived(aReceiverIndex: TKMNetHandleIndex);
var 
  I: Integer;
begin
  for I := Low(fSenders) to High(fSenders) do
    if (fSenders[I] <> nil) and (fSenders[I].ReceiverIndex = aReceiverIndex) then
      fSenders[I].AckReceived;
end;


procedure TKMFileSenderManager.ClientDisconnected(aReceiverIndex: TKMNetHandleIndex);
var 
  I: Integer;
begin
  for I := Low(fSenders) to High(fSenders) do
    if (fSenders[I] <> nil) and (fSenders[I].ReceiverIndex = aReceiverIndex) then
      FreeAndNil(fSenders[I]);
end;


destructor TKMFileSenderManager.Destroy;
var 
  I: Integer;
begin
  for I := Low(fSenders) to High(fSenders) do
    FreeAndNil(fSenders[I]);
  inherited;
end;


function TKMFileSenderManager.StartNewSend(aType: TKMTransferType; const aName: String; aMapKind: TKMMapKind;
                                           aReceiverIndex: TKMNetHandleIndex): Boolean;
var
  I: Integer;
  name: String;
begin
  name := aName; //To save const String param locally

  for I := Low(fSenders) to High(fSenders) do
    if (fSenders[I] = nil) or (fSenders[I].ReceiverIndex = aReceiverIndex) then
    begin
      if fSenders[I] <> nil then
        //There is an existing transfer to this client, so free it
        fSenders[I].Free;
      try
        fSenders[I] := TKMFileSender.Create(aType, name, aMapKind, aReceiverIndex);
      except
        on E: Exception do
        begin
          gLog.AddTime(E.Message);
          Result := False; // Ignore exception, just return False
          Exit;
        end;
      end;
      Result := True;
      Exit;
    end;
  Result := False;
end;


function TKMFileSenderManager.ActiveTransferCount: Byte;
var 
  I: Integer;
begin
  Result := 0;
  for I := Low(fSenders) to High(fSenders) do
    if fSenders[I] <> nil then
      Inc(Result);
end;


procedure TKMFileSenderManager.UpdateStateIdle(SendBufferEmpty: Boolean);
var
  I: Integer;
  stream: TKMemoryStream;
  clientIndex: TKMNetHandleIndex;
  maxChunksInFlightPerSender: Byte;
begin
  //Reserve some bandwidth for each sender
  maxChunksInFlightPerSender := Max(1, MAX_CHUNKS_BEFORE_ACK div Max(1, ActiveTransferCount));
  for I := Low(fSenders) to High(fSenders) do
    while (fSenders[I] <> nil) and (fSenders[I].fChunksInFlight < maxChunksInFlightPerSender) and SendBufferEmpty do
    begin
      stream := TKMemoryStreamBinary.Create;
      fSenders[I].WriteChunk(stream, FILE_CHUNK_SIZE);
      fOnTransferPacket(fSenders[I].ReceiverIndex, stream, SendBufferEmpty); //Updates SendBufferEmpty
      stream.Free;
      if fSenders[I].StreamEnd then
      begin
        clientIndex := fSenders[I].ReceiverIndex;
        FreeAndNil(fSenders[I]); //We must free it before calling OnTransferCompleted
        fOnTransferCompleted(clientIndex);
      end;
    end;
end;


end.

