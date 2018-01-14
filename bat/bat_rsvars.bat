call bat_rsvars_local.bat

@SET BDS=%BDS_LOCAL%
@SET BDSCOMMONDIR=%BDSCOMMONDIR_LOCAL%
@SET FrameworkDir=%FrameworkDir_LOCAL%
@SET FrameworkVersion=%FrameworkVersion_LOCAL%
@SET FrameworkSDKDir=%FrameworkSDKDir_LOCAL%
@SET KaMOrigDir=%KaMOrigDir_LOCAL%
@SET KMRPrevVersionDir=%KMRPrevVersionDir_LOCAL%
@SET BuildFullDir=%BuildFullDir_LOCAL%
@SET PATH=%FrameworkDir%;%FrameworkSDKDir%;%BDS%\bin;%BDS%\bin64;%PATH%
@SET kam_version=Alpha 8k+
