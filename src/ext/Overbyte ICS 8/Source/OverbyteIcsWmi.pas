{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Author:       Angus Robertson, Magenta Systems Ltd
Description:  WMI compoments for IP address and DNS server updating.
Creation:     Mar 2020
Updated:      Apr 2020
Version:      8.64
EMail:        francois.piette@overbyte.be  http://www.overbyte.be
Support:      https://en.delphipraxis.net/forum/37-ics-internet-component-suite/
Legal issues: Copyright (C) 2019 by Angus Robertson, Magenta Systems Ltd,
              Croydon, England. delphi@magsys.co.uk, https://www.magsys.co.uk/delphi/

              This software is provided 'as-is', without any express or
              implied warranty.  In no event will the author be held liable
              for any  damages arising from the use of this software.

              Permission is granted to anyone to use this software for any
              purpose, including commercial applications, and to alter it
              and redistribute it freely, subject to the following
              restrictions:

              1. The origin of this software must not be misrepresented,
                 you must not claim that you wrote the original software.
                 If you use this software in a product, an acknowledgment
                 in the product documentation would be appreciated but is
                 not required.

              2. Altered source versions must be plainly marked as such, and
                 must not be misrepresented as being the original software.

              3. This notice may not be removed or altered from any source
                 distribution.

              4. You must register this software by sending a picture postcard
                 to the author. Use a nice stamp and mention your name, street
                 address, EMail address and any comment you like to say.


Overview
--------



Borrowed from Magenta Systems WMI and SMART Component v5.6 magwmi.pas, no disk drive stuff.
Updates:
November 2003 - baseline Magenta Systems Ltd
Apr 21, 2020  - 8.64 - ICS version



}

unit OverbyteIcsWmi;

{$I Include\OverbyteIcsDefs.inc}

{$IFDEF COMPILER14_UP}
  {$IFDEF NO_EXTENDED_RTTI}
    {$RTTI EXPLICIT METHODS([]) FIELDS([]) PROPERTIES([])}
  {$ENDIF}
{$ENDIF}
{$B-}             { Enable partial boolean evaluation   }
{$T-}             { Untyped pointers                    }
{$X+}             { Enable extended syntax              }
{$H+}             { Use long strings                    }
{$IFDEF BCB}
    {$ObjExportAll On}
{$ENDIF}

interface

uses
    {$IFDEF RTL_NAMESPACES}Winapi.Messages{$ELSE}Messages{$ENDIF},
    {$IFDEF RTL_NAMESPACES}Winapi.Windows{$ELSE}Windows{$ENDIF},
    {$Ifdef Rtl_Namespaces}System.Classes{$Else}Classes{$Endif},
    {$Ifdef Rtl_Namespaces}System.Sysutils{$Else}Sysutils{$Endif},
    {$IFDEF RTL_NAMESPACES}System.TypInfo{$ELSE}TypInfo{$ENDIF},
    {$IFDEF RTL_NAMESPACES}System.Types{$ELSE}Types{$ENDIF},
    OverbyteIcsTypes,
    OverbyteIcsUtils,
    WbemScripting_TLB;

const
    RootNameSpace = 'root\CIMV2' ;
    DnsNameSpace = 'root\MicrosoftDns' ;
    WebNameSpace = 'root\WebAdministration' ;
    QueryOneAdaptor = 'SELECT Name, Index FROM Win32_NetworkAdapter WHERE ' +
              'AdapterType = "Ethernet 802.3" AND Name <> "1394 Net Adapter"' ;
    QueryListAdaptors = 'SELECT Name, Index, NetConnectionID FROM ' +
        'Win32_NetworkAdapter WHERE AdapterType = "Ethernet 802.3" AND NetEnabled = True';
    QueryListAddresses = 'SELECT * FROM Win32_NetworkAdapterConfiguration WHERE Index = ';

{ lots of alternate name spaces:

root\wmi
MSNdis_HardwareStatus
MSNdis_80211_TransmitPowerLevel
MSNdis_80211_ReceivedSignalStrength
MSNdis_MediaConnectStatus
MSTapeDriveParam
MSRedbook_DriverInformation
MSSerial_PortName
MSStorageDriver_FailurePredictStatus
MSStorageDriver_ATAPISmartData
}

 //  MicrosoftDNS_Zone.ZoneType values
    ZoneTypeCache = 0 ;
    ZoneTypePrimary = 1 ;
    ZoneTypeSecondary = 2 ;
    ZoneTypeStub = 3 ;
    ZoneTypeForwader = 4 ;

var
    ZoneTypeLits: array [0..4] of string = (
        'Cache', 'Primary', 'Secondary', 'Stub', 'Forwarder');

type
    T2DimStrArray = array of array of string ;

    TWmiAddr = Record
        IpAddr: String;
        Mask: String;
    end;

    TWmiGateway = Record
        IpAddr: String;
        Cost: String;
    end;

    TWmiDnsZone = Record
        ZoneName: String;   { U-Label Unicode }
        PunyName: String;   { A-Label Punycode ASCII }
        ZoneType: Integer;
        Reverse: Boolean;
        Server: String;
    end;

    TWmiDnsRec = Record
        RecType: String;
        HostName: String;   { U-Label Unicode }
        PunyName: String;   { A-Label Punycode ASCII }
        RecData: String;
        Instance: Integer;
        TextRep: String;
     end;

    TWmiAddrs = array of TWmiAddr;
    TWmiGateways = array of TWmiGateway;
    TWmiDnsZones = array of TWmiDnsZone;
    TWmiDnsRecs = array of TWmiDnsRec;

    TWmiEdtFunc = (EdtFuncUpd, EdtFuncAdd, EdtFuncDel);

{ public functions }

    function IcsWmiDate2DT (S: string; var UtcOffset: integer): TDateTime ;
    function IcsWmiGetPropStr (wmiProp: ISWbemProperty): string ;
    function IcsWmiGetObjs (wmiServices: ISWbemServices; const Arg: string ;
       var WmiResults: T2DimStrArray; var Instances: integer; var Errinfo: string): integer ;
    function IcsWmiConnServer (const Comp, NameSpace, User, Pass: string ;
      var wmiLocator: TSWbemLocator; var wmiServices: ISWbemServices): string;
    function IcsWmiGetInfoEx (const Comp, NameSpace, User, Pass, Arg: string ;
       var WmiResults: T2DimStrArray; var instances: integer; var errinfo: string): integer ;
    function IcsWmiGetInfo (const Comp, NameSpace, User, Pass, Arg: string ;
                       var WmiResults: T2DimStrArray; var instances: integer): integer ;
    function IcsWmiGetOneG (const Arg, Prop: string ; var ResStr, Errinfo: string): integer ;
    function IcsWmiGetOneQ (const Arg, Prop: string ; var ResStr, Errinfo: string): integer ;
    function IcsWmiSearchIdx (const WmiResults: T2DimStrArray; const Prop: string): integer ;
    function IcsWmiSearch1 (const WmiResults: T2DimStrArray; const Prop: string): string ;
    function IcsWmiGetBaseBoard: string ;
    function IcsWmiGetSMBIOS: string ;
    function IcsWmiGetLastBootDT: TDateTime ;
    function IcsWmiFindAdaptor (var AdapterName, Errinfo: string): integer ;
    function IcsWmiRenameComp (const Comp, User, Pass: string; const NewName,
                    DCUserName, DCPassword: string; var Errinfo: string): integer ;
    function IcsWmiGetOSInfo (item: string): string ;
    function IcsWmiCloseWin (const Comp, User, Pass: string ; reboot: boolean;
                                                var errinfo: string): integer ;
    function IcsWmiListAdaptors (const Comp, User, Pass: string; var AdapterList:
                T2DimStrArray; var Errinfo: string; Enabled: Boolean = True): integer ;
    function IcsWmiGetAddresses (const Comp, User, Pass: string; const AdapNum:
             integer; var DhcpFlag: Boolean; var WmiAddrs: TWmiAddrs;
                    var WmiGateways: TWmiGateways; var Errinfo: string): integer ;
    function IcsWmiSetAddresses (const Comp, User, Pass: string; const AdapNum:
            integer; DhcpFlag: Boolean; WmiAddrs: TWmiAddrs;
                        WmiGateways: TWmiGateways; var Errinfo: string): LongWord ;
    function IcsWmiChkDnsSrv (const Comp, User, Pass: string; var IpAddrs, Errinfo: string): String ;
    function IcsWmiListDnsZones (const Comp, User, Pass: string ;
                         var WmiDnsZones: TWmiDnsZones; var Errinfo: string): integer ;
    function IcsWmiListDnsRecs (const Comp, User, Pass, Zone, RRType: string;
                         var WmiDnsRecs: TWmiDnsRecs; var Errinfo: string): integer ;
    function IcsWmiUpdDnsRec (const Comp, User, Pass, Zone: string;
        WmiDnsRec: TWmiDnsRec; WmiEdtFunc: TWmiEdtFunc; var Errinfo: string): Integer;


implementation

uses ActiveX, ComObj, Variants;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

function IcsWmiDate2DT (S: string; var UtcOffset: integer): TDateTime ;
// yyyymmddhhnnss.zzzzzzsUUU  +60 means 60 mins of UTC time
// 20030709091030.686000+060
// 1234567890123456789012345
var
    yy, mm, dd, hh, nn, ss, zz: integer ;
    timeDT: TDateTime ;

    function GetNum (offset, len: integer): integer ;
    var
        E: Integer;
    begin
        Val (copy (S, offset, len), result, E) ;
    end ;

begin
    result := 0 ;
    UtcOffset := 0 ;
    if length (S) <> 25 then exit ;   // fixed length
    yy := GetNum (1, 4) ;
    mm := GetNum (5, 2) ;
    if (mm = 0) or (mm > 12) then exit ;
    dd := GetNum (7, 2) ;
    if (dd = 0) or (dd > 31) then exit ;
    if NOT TryEncodeDate (yy, mm, dd, result) then
    begin
        result := -1 ;
        exit ;
    end ;
    hh := GetNum (9, 2) ;
    nn := GetNum (11, 2) ;
    ss := GetNum (13, 2) ;
    zz := 0 ;
    if Length (S) >= 18 then zz := GetNum (16, 3) ;
    if NOT TryEncodeTime (hh, nn, ss, zz, timeDT) then exit ;
    result := result + timeDT ;
    UtcOffset := GetNum (22, 4) ; // including sign
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// convert a single property into a string, including arrays which become | separated

function IcsWmiGetPropStr (wmiProp: ISWbemProperty): string ;
var
    I: integer ;
begin
    result := '';
    if VarIsNull(wmiProp.Get_Value) then
        result := 'NULL'
    else
    begin
        case wmiProp.CIMType of
            wbemCimtypeSint8, wbemCimtypeUint8, wbemCimtypeSint16,
            wbemCimtypeUint16, wbemCimtypeSint32, wbemCimtypeUint32,
            wbemCimtypeSint64:
                if VarIsArray(wmiProp.Get_Value) then
                begin
                    for I := 0 to VarArrayHighBound (wmiProp.Get_Value, 1) do
                    begin
                        if I > 0 then result := result + '|' ;
                        result := result + IntToStr (wmiProp.Get_Value [I]) ;
                    end ;
                end
                else
                    result := IntToStr (wmiProp.Get_Value);

            wbemCimtypeReal32, wbemCimtypeReal64:
                result := FloatToStr (wmiProp.Get_Value);

            wbemCimtypeBoolean:
                if wmiProp.Get_Value then result := 'True' else result := 'False';

            wbemCimtypeString, wbemCimtypeUint64:
                if VarIsArray(wmiProp.Get_Value) then
                begin
                    for I := 0 to VarArrayHighBound (wmiProp.Get_Value, 1) do
                    begin
                        if I > 0 then result := result + '|' ;
                        result := result + wmiProp.Get_Value [I] ;
                    end ;
                end
                else
                    result := wmiProp.Get_Value;

            wbemCimtypeDatetime:
                result := wmiProp.Get_Value;

            wbemCimtypeReference:
            begin
                result := wmiProp.Get_Value ;
            // Services.Get(result, 0, nil).GetObjectText_(0));  another query
            end;

            wbemCimtypeChar16:
                result := '<16-bit character>';

            wbemCimtypeObject:
                result := '<CIM Object>';
        end ;
    end;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// get all instances and properties from a class or command line

function IcsWmiGetObjs (wmiServices: ISWbemServices; const Arg: string ;
    var WmiResults: T2DimStrArray; var Instances: integer; var Errinfo: string): integer ;
var
    wmiObjectSet: ISWbemObjectSet;
    wmiObject: ISWbemObject;
    propSet: ISWbemPropertySet;
    wmiProp: ISWbemProperty;
    propEnum, Enum: IEnumVariant;
    ovVar1, ovVar2: OleVariant;
    lwValue: LongWord;
    sValue: String;
    inst, row: integer ;
    dimmed: boolean ;
begin
    Result := 0 ;
    Errinfo := '' ;
    if NOT Assigned(wmiServices) then Exit;
    Instances := 0 ;
    SetLength (WmiResults, 0, 0) ;
    dimmed := false ;
    VarClear (ovVar1) ;
    VarClear (ovVar2) ;
    try
        try
            if Pos ('select', IcsLowerCase(Arg)) = 1 then
                wmiObjectSet := wmiServices.ExecQuery (Arg, 'WQL', wbemFlagReturnImmediately, nil)
            else
                wmiObjectSet := wmiServices.InstancesOf (Arg, wbemFlagReturnImmediately or
                                                                        wbemQueryFlagShallow, nil) ;
            Instances := wmiObjectSet.Count ;
            if Instances = 0 then exit ;

            // Replicate VBScript's "for each" construct
            Enum := (wmiObjectSet._NewEnum) as IEnumVariant;
            inst := 0 ;
            while (Enum.Next (1, ovVar1, lwValue) = S_OK) do  // each row
            begin
                wmiObject := IUnknown(ovVar1) as SWBemObject;
                propSet := wmiObject.Properties_;
                Result := propSet.Count ;
                if NOT dimmed then
                begin
                    SetLength (WmiResults, Instances + 1, Result + 1) ;
                    WmiResults [0, 0] := 'Instance' ;
                    dimmed := true ;
                end ;
                propEnum := (propSet._NewEnum) as IEnumVariant;
                inc (inst) ;
                row := 1 ;
                WmiResults [inst, 0] := IntToStr (inst) ;

           // Replicate VBScript's "for each" construct
                while (propEnum.Next (1, ovVar2, lwValue) = S_OK) do  // each column
                begin
                    wmiProp := IUnknown(ovVar2) as SWBemProperty;
                    sValue := IcsWmiGetPropStr (wmiProp) ;
                    if inst = 1 then WmiResults [0, row] := wmiProp.Name ;
                    WmiResults [inst, row] := sValue ;
                    inc (row) ;
                    VarClear (ovVar2);
                end;
                VarClear (ovVar1); // clear for each interation, not just once
            end;
        except
            Result := -1 ;
            Errinfo := IcsGetExceptMess (ExceptObject) ;
        end ;
    finally
        VarClear (ovVar1) ;
        VarClear (ovVar2) ;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// connect to a WMI server
// Comp may be blank for local computer, user and pass optional

function IcsWmiConnServer (const Comp, NameSpace, User, Pass: string ;
      var wmiLocator: TSWbemLocator; var wmiServices: ISWbemServices): string;
begin
    result := '' ;
    try
        wmiServices := wmiLocator.ConnectServer (Comp, Namespace, User, Pass, '', '', 0, nil) ;
        if NOT Assigned (wmiServices) then
            result := 'Failed to Connect to WMI Server Namespace';
    except
        result := IcsGetExceptMess (ExceptObject) ;
    end ;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// Comp may be blank for local computer, user and pass optional
// results returned in two dimensioned dynamic string array with rows/columns
// NOTE - array is transposed from normal rows/columns, instances=columns, properties=rows
// Instances is 1 or greater, result is number of properties, 0 for none, -1 for error
// The size of the dynamic array may also be checked with Low/High

function IcsWmiGetInfoEx (const Comp, NameSpace, User, Pass, Arg: string ;
      var WmiResults: T2DimStrArray; var Instances: integer; var Errinfo: string): integer ;
var
    wmiLocator: TSWbemLocator;
    wmiServices: ISWbemServices;
begin
    Result := -1 ;
    Errinfo := '' ;
    wmiLocator := TSWbemLocator.Create (Nil) ;
    try
        try
            Errinfo := IcsWmiConnServer (Comp, Namespace, User, Pass, wmiLocator, wmiServices);
            if Errinfo = '' then
                Result := IcsWmiGetObjs (wmiServices, Arg, WmiResults, Instances, Errinfo) ;
        except
            result := -1 ;
            errinfo := IcsGetExceptMess (ExceptObject) ;
        end ;
    finally
        wmiLocator.Free;
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// Comp may be blank for local computer, user and pass optional
// results returned in two dimensioned array, properties as instance/column 0
// Instances is 1 or greater, result is number of rows, 0 for none, -1 for error
// The size of the dynamic array may also be checked with Low/High

function IcsWmiGetInfo (const Comp, NameSpace, User, Pass, Arg: string ;
                   var WmiResults: T2DimStrArray; var Instances: integer): integer ;
var
    Errinfo: string ;
begin
    result := IcsWmiGetInfoEx (Comp, NameSpace, User, Pass, Arg,
                                                WmiResults, instances, Errinfo) ;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// get a single property, argument is Get which seems very unprectictable

function IcsWmiGetOneG (const Arg, Prop: string ; var ResStr, Errinfo: string): integer ;
var
    wmiLocator: TSWbemLocator;
    wmiServices: ISWbemServices;
    wmiObject: ISWbemObject;
    wmiProp: ISWbemProperty;
begin
    result := 0 ;
    ResStr := '' ;
    Errinfo := '' ;
    wmiLocator := TSWbemLocator.Create (Nil);
    try
    try
        wmiServices := wmiLocator.ConnectServer ('', RootNameSpace, '', '', '', '', 0, nil);
        wmiObject := wmiServices.Get (Arg, 0, Nil) ;
        wmiProp := wmiObject.Properties_.Item (Prop, 0) ;
        if wmiProp.Name <> Prop then exit ;
        ResStr := IcsWmiGetPropStr (wmiProp) ;
        if ResStr <> 'NULL' then result := 1 ;
    except
        result := -1 ;
        Errinfo := IcsGetExceptMess (ExceptObject) ;
    end ;
    finally
        wmiLocator.Free;
    end;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// get a single property, argument is a WQL query, lengthy, but reliable
// fails if more than one instance returned by query

function IcsWmiGetOneQ (const Arg, Prop: string ; var ResStr, Errinfo: string): integer ;
var
    wmiLocator: TSWbemLocator;
    wmiServices: ISWbemServices;
    wmiObjectSet: ISWbemObjectSet;
    wmiObject: ISWbemObject;
    wmiProp: ISWbemProperty;
    ovVar: OleVariant;
    lwValue: LongWord;
    Enum: IEnumVariant;
begin
    ResStr := '' ;
    Errinfo := '' ;
    VarClear (ovVar);
    wmiLocator := TSWbemLocator.Create (Nil);
    try
        try
            wmiServices := wmiLocator.ConnectServer ('', RootNameSpace, '', '', '', '', 0, nil);
            wmiObjectSet := wmiServices.ExecQuery (Arg, 'WQL', wbemFlagReturnImmediately, nil) ;
            result := wmiObjectSet.Count ;
            if (result <> 1) then exit ;  // can only handle a single instance
            Enum := (wmiObjectSet._NewEnum) as IEnumVariant;
            if (Enum.Next (1, ovVar, lwValue) <> S_OK) then Exit;
            wmiObject := IUnknown(ovVar) as SWBemObject;
            wmiProp := wmiObject.Properties_.Item (Prop, 0) ;
            if wmiProp.Name = Prop then
            begin
                ResStr := IcsWmiGetPropStr (wmiProp) ;
                if ResStr <> 'NULL' then result := 1 ;
            end ;
        except
            result := -1 ;
            Errinfo := IcsGetExceptMess (ExceptObject) ;
        end ;
    finally
        VarClear (ovVar);
        wmiLocator.Free;
    end;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}



function IcsWmiSearchIdx (const WmiResults: T2DimStrArray; const Prop: string): integer ;
var
    I: integer ;
begin
    result := 0 ;
    for I := 1 to High (WmiResults [0]) do
    begin
        if WmiResults [0, I] = Prop then
        begin
            result := I ;
            exit ;
        end ;
    end ;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

function IcsWmiSearch1 (const WmiResults: T2DimStrArray; const Prop: string): string ;
var
    I: integer ;
begin
    result := '' ;
    I := IcsWmiSearchIdx (WmiResults, Prop) ;
    if I >= 1 then result := WmiResults [1, I] ;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

function IcsWmiGetBaseBoard: string ;
var
    rows, instances: integer ;
    WmiResults: T2DimStrArray ;
begin
    result := '' ;
    try
        rows := IcsWmiGetInfo ('', RootNameSpace, '', '',
            'SELECT Manufacturer, Product FROM Win32_BaseBoard', WmiResults, instances) ;
        if (instances = 1) and (rows > 1) then
            result := IcsWmiSearch1 (WmiResults, 'Manufacturer') + ' ' +
                                                  IcsWmiSearch1 (WmiResults, 'Product') ;
    finally
        WmiResults := Nil ;
    end ;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

function IcsWmiGetSMBIOS: string ;
var
    rows, instances: integer ;
    WmiResults: T2DimStrArray ;
begin
    result := '' ;
    try
        rows := IcsWmiGetInfo ('', RootNameSpace, '', '', 'Win32_BIOS', WmiResults, instances) ;
        if (instances = 1) and (rows > 1) then
            result := IcsWmiSearch1 (WmiResults, 'SMBIOSBIOSVersion') + ' v' +
                        IcsWmiSearch1 (WmiResults, 'SMBIOSMajorVersion') + '.' +
                               IcsWmiSearch1 (WmiResults, 'SMBIOSMinorVersion') ;
    finally
        WmiResults := Nil ;
    end ;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

function IcsWmiGetLastBootDT: TDateTime ;
var
    Errinfo: string ;
    rawdate: string ;
    utcoffset: integer ;
begin
    result := 0 ;
    if IcsWmiGetOneQ ('SELECT LastBootUpTime FROM Win32_OperatingSystem',
                                   'LastBootUpTime', rawdate, Errinfo) <> 1 then exit ;
    result := IcsWmiDate2DT (rawdate, utcoffset) ;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

function IcsWmiGetOSInfo (item: string): string ;
var
    Errinfo: string ;
begin
    result := '' ;
    IcsWmiGetOneQ ('SELECT ' + item + ' FROM Win32_OperatingSystem', item, Result, Errinfo) ;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// find the name and index of a unique Ethernet 802.3 adaptor (except 1394 Net Adapter)
// there may be other hidden adapters but they have null AdapterTypes (luckily)

function IcsWmiFindAdaptor (var AdapterName, Errinfo: string): integer ;
var
    I, rows, instances: integer ;
    WmiResults: T2DimStrArray ;
begin
    result := -1 ;
    Errinfo := '' ;
    AdapterName := '' ;
    try
        rows := IcsWmiGetInfoEx ('', RootNameSpace, '', '', QueryOneAdaptor,
                                                    WmiResults, instances, ErrInfo) ;
        if (instances = 1) and (rows > 1) then
        begin
            I := IcsWmiSearchIdx (WmiResults, 'Name') ;
            if I >= 1 then AdapterName := WmiResults [1, I] ;
            I := IcsWmiSearchIdx (WmiResults, 'Index') ;
            if I >= 1 then result := atoi (WmiResults [1, I]) ;
        end ;
    finally
        WmiResults := Nil ;
    end ;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// find the index, name and connectionId of all enabled Ethernet 802.3 adaptors
// there may be other hidden adapters but they have null AdapterTypes (luckily)
// returns two dimension array, with index, name and connectionId columns, result is total

function IcsWmiListAdaptors (const Comp, User, Pass: string; var AdapterList:
            T2DimStrArray; var Errinfo: string; Enabled: Boolean = True): integer ;
var
    J, rows, instances: integer ;
    WmiResults: T2DimStrArray ;
    Query: string;
begin
    result := 0 ;
    Errinfo := '' ;
    SetLength (AdapterList, 0, 0) ;
    try
        Query := 'SELECT Name, Index, NetConnectionID ' +
            'FROM Win32_NetworkAdapter WHERE AdapterType = "Ethernet 802.3"';
        if Enabled then Query := Query + ' AND NetEnabled = True' ;
        rows := IcsWmiGetInfoEx (Comp, RootNameSpace, User, Pass, Query, WmiResults,
                                                                  instances, ErrInfo) ;
        if (instances >= 1) and (rows > 1) then
        begin
            SetLength (AdapterList, instances, 3) ;

         // WmiResults comes back with row and column headers,
         // and extra column DeviceId which is same and Index
            for J := 1 to instances do
            begin
                AdapterList [Result, 0] := WmiResults [J, 2] ;
                AdapterList [Result, 1] := WmiResults [J, 3] ;
                AdapterList [Result, 2] := WmiResults [J, 4] ;
                Result := Result + 1;
            end;
        end ;
    finally
        WmiResults := Nil ;
    end ;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// find the IP addresses for an adapter by index

function IcsWmiGetAddresses (const Comp, User, Pass: string; const AdapNum: integer;
                var DhcpFlag: Boolean; var WmiAddrs: TWmiAddrs;
                    var WmiGateways: TWmiGateways; var Errinfo: string): integer ;
var
    wmiLocator: TSWbemLocator;
    wmiServices: ISWbemServices;
    wmiObjectSet: ISWbemObjectSet;
    wmiObject: ISWbemObject;
    ovVar: OleVariant;
    Enum: IEnumVariant;
    wmiProperty: SWbemProperty;
    lwValue: LongWord;
    ArrayVariant: Variant;
    Tot, I: Integer;
begin
    SetLength (WmiAddrs, 0) ;
    SetLength (WmiGateways, 0) ;
    DhcpFlag := False;
    Result := -1 ;
    Errinfo := '' ;
    VarClear (ovVar);
    wmiLocator := TSWbemLocator.Create (Nil);
    try
        try
            wmiServices := wmiLocator.ConnectServer (Comp, RootNameSpace,
                                                            User, Pass, '', '', 0, nil);
            wmiObjectSet := wmiServices.ExecQuery (QueryListAddresses +
                                IntToStr (AdapNum), 'WQL', wbemFlagReturnImmediately, nil) ;
            if (wmiObjectSet.Count <> 1) then exit ;  // can only handle a single instance
            Enum := (wmiObjectSet._NewEnum) as IEnumVariant;
            if (Enum.Next (1, ovVar, lwValue) <> S_OK) then exit;
            wmiObject := IUnknown(ovVar) as SWBemObject;
            wmiProperty := wmiObject.Properties_.Item ('DHCPEnabled', 0) ;
            DhcpFlag := wmiProperty.Get_Value ;
            wmiProperty := wmiObject.Properties_.Item ('IPAddress', 0) ;
            ArrayVariant := wmiProperty.Get_Value;
            if VarIsArray (ArrayVariant) then
            begin
                Result := VarArrayHighBound (ArrayVariant, 1) + 1 ;
                if Result <= 0 then Exit;
                SetLength (WmiAddrs, Result) ;
                for I := 0 to Result - 1 do
                    WmiAddrs [I].IpAddr := ArrayVariant [I] ;

                wmiProperty := wmiObject.Properties_.Item ('IPSubnet', 0) ;
                ArrayVariant := wmiProperty.Get_Value;
                if VarIsArray (ArrayVariant) then
                begin
                    for I := 0 to Result - 1 do
                        WmiAddrs [I].Mask := ArrayVariant [I] ;
                end;

                wmiProperty := wmiObject.Properties_.Item ('DefaultIPGateway', 0) ;
                ArrayVariant := wmiProperty.Get_Value;
                if VarIsArray (ArrayVariant) then
                begin
                    Tot := VarArrayHighBound (ArrayVariant, 1) + 1 ;
                    SetLength (WmiGateways, Tot) ;
                    for I := 0 to Tot - 1 do
                        WmiGateways [I].IpAddr := ArrayVariant [I] ;

                    wmiProperty := wmiObject.Properties_.Item ('GatewayCostMetric', 0) ;
                    ArrayVariant := wmiProperty.Get_Value;
                    if VarIsArray (ArrayVariant) then
                    begin
                        for I := 0 to Tot - 1 do
                            WmiGateways [I].Cost := ArrayVariant [I] ;
                    end;
                end
            end
            else
                Result := 0 ;
        except
            result := -1 ;
            Errinfo := IcsGetExceptMess (ExceptObject) ;
        end ;
    finally
        VarClear (ovVar);
        VarClear (ArrayVariant);
        wmiLocator.Free;
    end;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// change network adaptor static IP addresses and masks
// this disables DHCP, multiple IP addresses may be supplied, with matching masks
// program requires ADMIN rights to update IP addresses

function IcsWmiSetAddresses (const Comp, User, Pass: string; const AdapNum: integer;
                DhcpFlag: Boolean; WmiAddrs: TWmiAddrs;
                        WmiGateways: TWmiGateways; var Errinfo: string): LongWord ;
var
    wmiLocator: TSWbemLocator;
    wmiServices: ISWbemServices;
    wmiObjectSet: ISWbemObjectSet;
    wmiObject, wmiInst, wmiInParams, wmiOutParams: ISWbemObject;
    wmiProp: ISWbemProperty;
    ovVar, propValue: OleVariant;
    Enum: IEnumVariant;
    wmiMethod: SWbemMethod;
    wmiProperty: SWbemProperty;
    lwValue: LongWord;
    AddrArrayVar, MaskArrayVar, CostArrayVar: Variant;
    I, TotAddr, TotGate: integer;
begin
    Result := 2 ;  // unused error
    Errinfo := '' ;
    VarClear (ovVar);
    wmiLocator := TSWbemLocator.Create (Nil);
    try
        try
            wmiServices := wmiLocator.ConnectServer (Comp, RootNameSpace, User,
                                                            Pass, '', '', 0, nil);
            wmiObjectSet := wmiServices.ExecQuery (QueryListAddresses +
                            IntToStr (AdapNum), 'WQL', wbemFlagReturnImmediately, nil) ;
            if (wmiObjectSet.Count <> 1) then exit ;  // can only handle a single instance
            Enum := (wmiObjectSet._NewEnum) as IEnumVariant;
            if (Enum.Next (1, ovVar, lwValue) <> S_OK) then exit;
            wmiObject := IUnknown(ovVar) as SWBemObject;
            if DhcpFlag then
            begin
                wmiMethod := wmiObject.Methods_.Item ('EnableDHCP', 0) ;
                wmiOutParams := wmiObject.ExecMethod_ ('EnableDHCP', Nil, 0, nil) ;
                wmiProp := wmiOutParams.Properties_.Item ('ReturnValue', 0) ;
                result := wmiProp.Get_Value ;
             // 0=OK no reboot, 1=ok reboot, 64 to 100 various errors, see MSDN
             // 68 = bad input parameter, 84=IP not enabled (ie wrong adaptor)
            end
            else
            begin

            // IP address and masks
                TotAddr := Length(WmiAddrs);
                TotGate := Length(WmiGateways);
                if TotAddr > 0 then
                begin
                    AddrArrayVar := VarArrayCreate([0, TotAddr - 1], varOleStr);
                    MaskArrayVar := VarArrayCreate([0, TotAddr - 1], varOleStr);
                    for I := 0 to TotAddr - 1 do
                    begin
                        AddrArrayVar [I] := WmiAddrs [I].IpAddr;
                        MaskArrayVar [I] := WmiAddrs [I].Mask;
                    end;
                    wmiMethod := wmiObject.Methods_.Item ('EnableStatic', 0) ;
                    wmiInParams := wmiMethod.InParameters ;
                    wmiInst := wmiInParams.SpawnInstance_(0) ;
                    wmiProperty := wmiInst.Properties_.Add ('IPAddress', wbemCimtypeString, True, 0) ;
                    propValue := AddrArrayVar ;
                    wmiProperty.Set_Value (propValue);
                    wmiProperty := wmiInst.Properties_.Add ('SubnetMask', wbemCimtypeString, True, 0) ;
                    propValue := MaskArrayVar ;
                    wmiProperty.Set_Value (propValue);
                    wmiOutParams := wmiObject.ExecMethod_ ('EnableStatic', wmiInst, 0, nil) ;
                    wmiProp := wmiOutParams.Properties_.Item ('ReturnValue', 0) ;
                    result := wmiProp.Get_Value ;
               //     if Result > 1 then Exit;
                 // 0=OK no reboot, 1=ok reboot, 64 to 100 various errors, see MSDN
                 // 68 = bad input parameter, 84=IP not enabled (ie wrong adaptor)
                 end;

             // gateway and cost
                if TotGate > 0 then
                begin
                    AddrArrayVar := VarArrayCreate([0, TotGate - 1], varOleStr);
                    CostArrayVar := VarArrayCreate([0, TotGate - 1], varInteger);
                    for I := 0 to TotGate - 1 do
                    begin
                        AddrArrayVar [I] := WmiGateways [I].IpAddr;
                        CostArrayVar [I] := atoi(WmiGateways [I].Cost);
                    end;
                    wmiMethod := wmiObject.Methods_.Item ('SetGateways', 0) ;
                    wmiInParams := wmiMethod.InParameters ;
                    wmiInst := wmiInParams.SpawnInstance_(0) ;
                    wmiProperty := wmiInst.Properties_.Add ('DefaultIPGateway', wbemCimtypeString, True, 0) ;
                    propValue := AddrArrayVar ;
                    wmiProperty.Set_Value (propValue);
                    wmiProperty := wmiInst.Properties_.Add ('GatewayCostMetric', wbemCimtypeUint16, True, 0) ;
                    propValue := CostArrayVar ;
                    wmiProperty.Set_Value (propValue);
                    wmiOutParams := wmiObject.ExecMethod_ ('SetGateways', wmiInst, 0, nil) ;
                    wmiProp := wmiOutParams.Properties_.Item ('ReturnValue', 0) ;
                    result := wmiProp.Get_Value ;
                end ;
            end;
        except
            result := 2 ;
            Errinfo := IcsGetExceptMess (ExceptObject) ;
        end ;
    finally
        wmiLocator.Free;
        VarClear (ovVar);
        VarClear (propValue);
        VarClear (AddrArrayVar);
        VarClear (MaskArrayVar);
        VarClear (CostArrayVar);
    end;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// rename Computer Name, always needs reboot - account info is for domain controller

function IcsWmiRenameComp (const Comp, User, Pass: string; const NewName,
                    DCUserName, DCPassword: string; var Errinfo: string): integer ;
var
    wmiLocator: TSWbemLocator;
    wmiServices: ISWbemServices;
    wmiObjectSet: ISWbemObjectSet;
    wmiObject, wmiInst, wmiInParams, wmiOutParams: ISWbemObject;
    wmiProp: ISWbemProperty;
    ovVar, propValue: OleVariant;
    Enum: IEnumVariant;
    wmiMethod: SWbemMethod;
    wmiProperty: SWbemProperty;
    lwValue: LongWord;
begin
    Result := -1 ;
    Errinfo := '' ;
    if NewName = '' then exit ;
 // should validate new name for no control chars, spaces, / \ [ ]
    wmiLocator := TSWbemLocator.Create (Nil);
    try
        try
            wmiServices := wmiLocator.ConnectServer (Comp, RootNameSpace, User,
                                                             Pass, '', '', 0, nil);
            wmiObjectSet := wmiServices.InstancesOf ('Win32_ComputerSystem',
                                 wbemFlagReturnImmediately or wbemQueryFlagShallow, nil) ;
            if (wmiObjectSet.Count <> 1) then exit ;  // can only handle a single instance
            Enum := (wmiObjectSet._NewEnum) as IEnumVariant;
            if (Enum.Next (1, ovVar, lwValue) <> S_OK) then Exit;
            wmiObject := IUnknown(ovVar) as SWBemObject;
            wmiMethod := wmiObject.Methods_.Item ('Rename', 0) ;
            wmiInParams := wmiMethod.InParameters ;
            wmiInst := wmiInParams.SpawnInstance_(0) ;
            wmiProperty := wmiInst.Properties_.Add ('Name', wbemCimtypeString, False, 0) ;
            propValue := NewName ;
            wmiProperty.Set_Value (propValue);
            if DCUserName <> '' then
            begin
                wmiProperty := wmiInst.Properties_.Add ('UserName', wbemCimtypeString, False, 0) ;
                propValue := DCUserName ;
                wmiProperty.Set_Value (propValue);
                wmiProperty := wmiInst.Properties_.Add ('Password', wbemCimtypeString, False, 0) ;
                propValue := DCPassword ;
                wmiProperty.Set_Value (propValue);
            end ;
            wmiOutParams := wmiObject.ExecMethod_ ('Rename', wmiInst, 0, nil) ;
            wmiProp := wmiOutParams.Properties_.Item ('ReturnValue', 0) ;
            result := wmiProp.Get_Value ;
         // 0=OK reboot needed, non 0 various errors, see MSDN
        except
            result := -1 ;
            Errinfo := IcsGetExceptMess (ExceptObject) ;
        end ;
    finally
        wmiLocator.Free;
        VarClear (ovVar);
        VarClear (propValue);
    end;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// reboot or close down PC

function IcsWmiCloseWin (const Comp, User, Pass: string ; reboot: boolean;
                                                    var Errinfo: string): integer ;
var
    wmiLocator: TSWbemLocator;
    wmiServices: ISWbemServices;
    wmiObjectSet: ISWbemObjectSet;
    wmiObject, wmiInst, wmiInParams, wmiOutParams: ISWbemObject;
    wmiProp: ISWbemProperty;
    wmiProperty: SWbemProperty;
    wmiMethod: SWbemMethod;
    ovVar, propValue: OleVariant;
    Enum: IEnumVariant;
    Arg: string ;
    lwValue, flags: LongWord;
begin
    Errinfo := '' ;
    Result := -1 ;
    wmiLocator := TSWbemLocator.Create (Nil);
    try
        try
            wmiServices := wmiLocator.ConnectServer (Comp, RootNameSpace, User, Pass, '', '', 0, nil);
            wmiServices.Security_.Privileges.Add(wbemPrivilegeShutdown, True);
            Arg := 'SELECT * FROM Win32_OperatingSystem WHERE Primary=True' ;
            wmiObjectSet := wmiServices.ExecQuery (Arg, 'WQL', wbemFlagReturnImmediately, nil) ;
            if (wmiObjectSet.Count < 1) then exit ;  // expect a single instance
            Enum := (wmiObjectSet._NewEnum) as IEnumVariant;
            if (Enum.Next (1, ovVar, lwValue) <> S_OK) then Exit;
            wmiObject := IUnknown(ovVar) as SWBemObject;
            wmiMethod := wmiObject.Methods_.Item ('Win32Shutdown', 0) ;
            wmiInParams := wmiMethod.InParameters ;
            wmiInst := wmiInParams.SpawnInstance_(0) ;
            flags := EWX_SHUTDOWN + EWX_FORCE ;  // forced shutdown
            if reboot then flags := EWX_REBOOT + EWX_FORCE ;  // forced reboot
            wmiProperty := wmiInst.Properties_.Add ('Flags', wbemCimtypeSint32, False, 0) ;
            propValue := flags ;
            wmiProperty.Set_Value (propValue);
            wmiOutParams := wmiObject.ExecMethod_ ('Win32Shutdown', wmiInst, 0, nil);
            wmiProp := wmiOutParams.Properties_.Item ('ReturnValue', 0) ;
            result := wmiProp.Get_Value ;
            if result <> 0 then errinfo := 'PC Close Down Failed: ' +
                         SysErrorMessage (result) + ' [' + IntToStr (result) + ']' ;
        except
            result := -1 ;
            Errinfo := IcsGetExceptMess (ExceptObject) ;
        end ;
    finally
        wmiLocator.Free;
        VarClear (ovVar);
        VarClear (propValue);
    end;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// check DNS server exists, Windows Server only, returns name

function IcsWmiChkDnsSrv (const Comp, User, Pass: string; var IpAddrs, Errinfo: string): String ;
var
    rows, instances: integer ;
    WmiResults: T2DimStrArray ;
    Query: string;
begin
    result := '' ;
    Errinfo := '' ;
    IpAddrs := '';
    try
        Query := 'SELECT IsSlave,Name,ServerAddresses FROM MicrosoftDNS_Server';
        rows := IcsWmiGetInfoEx (Comp, DnsNameSpace, User, Pass, Query, WmiResults, instances, Errinfo) ;
        if (instances >= 1) and (rows > 1) then
        begin

         // WmiResults comes back with row and column headers,
         // comes back with instance as first column
            Result := WmiResults [1, 2] ;
            IpAddrs := WmiResults [1, 3] ;
        end ;
    finally
        WmiResults := Nil ;
    end ;
end ;


{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// get a list of zones on DNS server, Windows Server only

function IcsWmiListDnsZones (const Comp, User, Pass: string;
                    var WmiDnsZones: TWmiDnsZones; var Errinfo: string): integer ;
var
    J, rows, instances: integer ;
    WmiResults: T2DimStrArray ;
    Query: string;
begin
    result := 0 ;
    Errinfo := '' ;
    SetLength (WmiDnsZones, 0) ;
    try
        Query := 'SELECT ContainerName,DnsServerName,Name,Reverse,ZoneType FROM MicrosoftDNS_Zone';
        rows := IcsWmiGetInfoEx (Comp, DnsNameSpace, User, Pass, Query, WmiResults, instances, Errinfo) ;
        if (instances >= 1) and (rows > 1) then
        begin
            SetLength (WmiDnsZones, instances) ;

         // WmiResults comes back with row and column headers,
         // comes back with instance as first column
            for J := 1 to instances do
            begin
                WmiDnsZones [Result].PunyName := WmiResults [J, 1] ;
                WmiDnsZones [Result].ZoneName := IcsIDNAToUnicode(WmiDnsZones [Result].PunyName) ;
                WmiDnsZones [Result].Server := WmiResults [J, 2] ;
                WmiDnsZones [Result].Reverse := (WmiResults [J, 4] = 'True') ;
                WmiDnsZones [Result].ZoneType := atoi(WmiResults [J, 5]) ;
                Result := Result + 1;
            end;
        end ;
    finally
        WmiResults := Nil ;
    end ;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}
 // get a list of one or manu records for a single zone on DNS server, Windows Server only

function IcsWmiListDnsRecs (const Comp, User, Pass, Zone, RRType: string;
                            var WmiDnsRecs: TWmiDnsRecs; var Errinfo: string): integer ;
var
    WmiResults: T2DimStrArray ;
    wmiLocator: TSWbemLocator;
    wmiServices: ISWbemServices;
    DnsNr: Integer;

    procedure GetRecs (RType: String);
    var
        Arg: String;
        J, rows, instances: integer ;
    begin
        Arg := 'SELECT DomainName,OwnerName,RecordData,TextRepresentation,TTL FROM MicrosoftDNS_' +
                                 RType + 'Type WHERE DomainName = "' + Zone + '"';
        rows := IcsWmiGetObjs (wmiServices, Arg, WmiResults, Instances, Errinfo) ;
        if (Instances < 1) or (rows < 1) then Exit;
        if (DnsNr + Instances) >= Length (WmiDnsRecs) then
             SetLength (WmiDnsRecs, DnsNr + Instances + 20);
        for J := 1 to Instances do
        begin
            WmiDnsRecs[DnsNr].RecType := RType ;
            WmiDnsRecs[DnsNr].PunyName := WmiResults [J, 4] ;
            WmiDnsRecs[DnsNr].HostName := IcsIDNAToUnicode(WmiDnsRecs[DnsNr].PunyName) ;
            WmiDnsRecs[DnsNr].RecData := WmiResults [J, 6] ;
            WmiDnsRecs[DnsNr].Instance := atoi(WmiResults [J, 0]) ;
            WmiDnsRecs[DnsNr].TextRep  := WmiResults [J, 7] ;
            DnsNr := DnsNr + 1;
        end;
    end;

begin
    Result := -1 ;
    Errinfo := '' ;
    SetLength (WmiDnsRecs, 0);
    wmiLocator := TSWbemLocator.Create (Nil) ;
    DnsNr := 0;
    try
        try
            Errinfo := IcsWmiConnServer (Comp, DnsNameSpace, User, Pass, wmiLocator, wmiServices);
            if Errinfo <> '' then Exit;
            SetLength (WmiDnsRecs, 20);
            if RRType <> '' then  // just one
                GetRecs (RRType)
            else
            begin
                GetRecs ('A');
                GetRecs ('AAAA');
                GetRecs ('CNAME');
                GetRecs ('NS');
                GetRecs ('MX');
                GetRecs ('PTR');
                GetRecs ('TXT');
                GetRecs ('SRV');
            end;
            Result := DnsNr ;
        except
            result := -1 ;
            Errinfo := IcsGetExceptMess (ExceptObject) ;
        end ;
    finally
        wmiLocator.Free;
        SetLength (WmiDnsRecs, DnsNr);
    end;
end;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

// add, update or delete DNS resource record for a zone in a Windows DNS Server

function IcsWmiUpdDnsRec (const Comp, User, Pass, Zone: string; WmiDnsRec: TWmiDnsRec;
                                   WmiEdtFunc: TWmiEdtFunc; var Errinfo: string): Integer;
var
    wmiLocator: TSWbemLocator;
    wmiServices: ISWbemServices;
    wmiDNSRRObj, wmiServerObj, wmiInst, wmiOutParams: ISWbemObject;
    ovVar, propValue: OleVariant;
    wmiMethod: SWbemMethod;
    wmiObjectSet: ISWbemObjectSet;
    Enum: IEnumVariant;
//    wmiProp: ISWbemProperty;
//    wmiProperty: SWbemProperty;
    NewRRRec, OutRRObj, MClass, Arg, PropName, PunyZone: String;
    lwValue: LongWord;
    ErrFlag, CheckFlag: Boolean;
begin
    Result := 1 ;  // error
    Errinfo := '' ;
    if (Pos ('.'+ Zone, WmiDnsRec.HostName) = 0) or (Zone = '') then
    begin
        Errinfo := 'Host Name Should Include Zone Domain Name - ' + WmiDnsRec.HostName ;
        Exit;
    end;
    PunyZone := IcsToASCII(Zone);
    WmiDnsRec.HostName := IcsLowerCase(WmiDnsRec.HostName);
  // don't check illegal characters _ at start of name, used for ACME DNS challenges
    CheckFlag := (Pos('_', WmiDnsRec.HostName) = 0);
    if (Pos('._', WmiDnsRec.HostName) > 1) then CheckFlag := False;
    WmiDnsRec.PunyName := IcsIDNAToASCII(WmiDnsRec.HostName, CheckFlag, ErrFlag);
    if ErrFlag then begin
        Errinfo := 'Host Name Contains Invalid Characters - ' + WmiDnsRec.HostName ;
        Exit;
    end;
    if WmiDnsRec.RecType = 'TXT' then begin // make sure TXT is dellmited else delete fails
        if WmiDnsRec.RecData = '' then
            WmiDnsRec.RecData := IcsDQUOTE + IcsDQUOTE
         else begin
             if WmiDnsRec.RecData[1] <> IcsDQUOTE then
                                WmiDnsRec.RecData := IcsDQUOTE + WmiDnsRec.RecData;
             if WmiDnsRec.RecData[Length(WmiDnsRec.RecData)] <> IcsDQUOTE then
                                WmiDnsRec.RecData := WmiDnsRec.RecData + IcsDQUOTE;
         end;
    end;
    NewRRRec := WmiDnsRec.PunyName + ' IN ' + WmiDnsRec.RecType + ' ' + WmiDnsRec.RecData;
    MClass := 'MicrosoftDNS_' + WmiDnsRec.RecType + 'Type';
    wmiLocator := TSWbemLocator.Create (Nil);
    try
        try
            wmiServices := wmiLocator.ConnectServer (Comp, DnsNameSpace, User, Pass, '', '', 0, nil);

        // add a nww resource record, no error if it already exists
            if WmiEdtFunc = EdtFuncAdd then
            begin
                wmiDNSRRObj := wmiServices.Get ('MicrosoftDNS_ResourceRecord', 0, nil) ;
                wmiServerObj := wmiServices.Get ('MicrosoftDNS_Server.Name="."', 0, nil) ;

           { prepare method of MicrosoftDNS_ResourceRecord class
            void CreateInstanceFromTextRepresentation(
              [in]       string                      DnsServerName,
              [in]       string                      ContainerName,
              [in]       string                      TextRepresentation,
              [out, ref] MicrosoftDNS_ResourceRecord &RR
             );   }
                wmiMethod := wmiDNSRRObj.Methods_.Item ('CreateInstanceFromTextRepresentation', 0) ;
                wmiInst := wmiMethod.InParameters.SpawnInstance_(0) ;

                propValue := wmiServerObj.Properties_.Item ('Name', 0).Get_Value ;
                wmiInst.Properties_.Add ('DnsServerName', wbemCimtypeString, False, 0).Set_Value (propValue);

                propValue := NewRRRec;
                wmiInst.Properties_.Add ('TextRepresentation', wbemCimtypeString, False, 0).Set_Value (propValue);

                propValue := PunyZone;
                wmiInst.Properties_.Add ('ContainerName', wbemCimtypeString, False, 0).Set_Value (propValue);

            // execute method and get out parameter, no returncode
                wmiOutParams := wmiDNSRRObj.ExecMethod_ ('CreateInstanceFromTextRepresentation', wmiInst, 0, nil) ;
                if NOT Assigned (wmiOutParams) then
                begin
                    Errinfo := 'No Output Parameters from Add RR Record' ;
                    Exit;
                end;
                OutRRObj := wmiOutParams.Properties_.Item ('RR', 0).Get_Value ;
               // not sure what form the RR comes back in...
               // MicrosoftDNS_TXTType.RecordData="\"mydata4\"",RecordClass=1,DnsServerName="PC18",ContainerName="magenta",DomainName="magenta",OwnerName="myname4.magenta"
                if Pos(MClass, OutRRObj) > 0 then
                    Result := 0
                else
                    Errinfo := 'Output RR Record Mismatch: ' + OutRRObj;
            end
            else
            begin
                Arg := 'SELECT * FROM ' + MClass + ' WHERE DomainName = "' + PunyZone + '"';
                wmiObjectSet := wmiServices.ExecQuery (Arg, 'WQL', wbemFlagReturnImmediately, nil) ;
                if (wmiObjectSet.Count = 0) then
                begin
                    Errinfo := 'RR Record Not Found';
                    exit
                end;
                Enum := (wmiObjectSet._NewEnum) as IEnumVariant;
                while (Enum.Next (1, ovVar, lwValue) = S_OK) do
                begin
                    wmiDNSRRObj := IUnknown(ovVar) as SWBemObject;
                    if wmiDNSRRObj.Properties_.Item ('OwnerName', 0).Get_Value = WmiDnsRec.PunyName then
///                    propValue := wmiDNSRRObj.Properties_.Item ('OwnerName', 0).Get_Value;
//                    if propValue = WmiDnsRec.OwnerName then
                    begin
                        if WmiEdtFunc = EdtFuncDel then
                        begin
                             if wmiDNSRRObj.Properties_.Item ('RecordData', 0).Get_Value = WmiDnsRec.RecData then
                             begin
                                  wmiDNSRRObj.Delete_(0, Nil);
                                  Result := 0;
                                  Exit;      // only one to delete
                             end;
                        end
                        else if WmiEdtFunc = EdtFuncUpd then
                        begin
                    { prepare method of MicrosoftDNS_xxType class, slightly different for reach RR type
                            void Modify(
                                   [in, optional] uint32               TTL,
                                   [in]           string               DescriptiveText,
                                  [out, ref]     MicrosoftDNS_TXTType &RR
                              );       }
                            wmiMethod := wmiDNSRRObj.Methods_.Item ('Modify', 0) ;
                            wmiInst := wmiMethod.InParameters.SpawnInstance_(0) ;
                            PropName := 'IPAddress';   // A
                            if WmiDnsRec.RecType = 'AAAA' then PropName := 'IPv6Address';
                            if WmiDnsRec.RecType = 'CNAME' then PropName := 'PrimaryName';
                            if WmiDnsRec.RecType = 'MX' then PropName := 'MailExchange';  // FAILS, needs Preference as well
                            if WmiDnsRec.RecType = 'NS' then PropName := 'NSHost';
                            if WmiDnsRec.RecType = 'PTR' then PropName := 'PTRDomainName';
                            if WmiDnsRec.RecType = 'TXT' then PropName := 'TextRepresentation';
                            propValue := WmiDnsRec.RecData;

                        // !! currently failing here  !!!
                            wmiInst.Properties_.Item (PropName, 0).Set_Value (propValue);

                        // execute method and get out parameter, no returncode
                            wmiOutParams := wmiDNSRRObj.ExecMethod_ ('Modify', wmiInst, 0, nil) ;
                            if NOT Assigned (wmiOutParams) then
                            begin
                                Errinfo := 'No Output Parameters from Update RR Record' ;
                                Exit;
                            end;
                            OutRRObj := wmiOutParams.Properties_.Item ('RR', 0).Get_Value ;
                            if Pos(MClass, OutRRObj) > 0 then
                                Result := 0
                            else
                                Errinfo := 'Output RR Record Mismatch: ' + OutRRObj;
                            Exit;
                        end;
                    end;
                    VarClear (ovVar);
                end;
                if Result <> 0 then Errinfo := 'RR Record Not Found';
            end;
        except
            result := 1 ;
            Errinfo := IcsGetExceptMess (ExceptObject) ;
        end ;
    finally
        wmiLocator.Free;
        VarClear (propValue);
        VarClear (ovVar);
    end;
end ;

{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

end.
