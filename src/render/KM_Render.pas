unit KM_Render;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF WDC} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, OpenGLContext, {$ENDIF}
  dglOpenGL,
  KM_RenderControl, KM_RenderQuery, KM_RenderTypes, KM_CommonTypes;


const
  TEX_FORMAT_SIZE: array [TKMTexFormat] of Byte = (2, 4, 1);
  TEX_FILTER: array [TKMFilterType] of GLint = (GL_NEAREST, GL_LINEAR);

type
  TKMRenderMode = (rm2D, rm3D);

  //General OpenGL handling
  TKMRender = class
  private class var
    fLastBindedTextureId: Cardinal;
    fMaxTextureSize: Cardinal; // Max supported texture size by video adapter
    fMaxViewportDim: Cardinal; // Max Viewport Dimensions, which could be used for FBO render
  private
    // Flag, True when FBO is inited. We don't need to init FBO for every run, since its only used in SaveMapToImageFile feature
    fFBOInited: Boolean;
    // Off-screen buffer, example from https://stackoverflow.com/questions/12157646/how-to-render-offscreen-on-opengl
    fFBO: Cardinal;
    fRenderBuf: Cardinal;

    fRenderControl: TKMRenderControl;
    fOpenGL_Vendor, fOpenGL_Renderer, fOpenGL_Version: UnicodeString;
    fScreenX, fScreenY: Word;
    fBlind: Boolean;
    fQuery: TKMRenderQuery;

    procedure InitFBO;
    procedure SaveBufferToFile(aUseFBOBuffer: Boolean; var aWidth, aHeight: Integer; var aPixelData: TKMCardinalArray);
    function GetMaxFBOSize: Cardinal;
  public
    constructor Create(aRenderControl: TKMRenderControl; aScreenX, aScreenY: Integer; aVSync: Boolean);
    destructor Destroy; override;

    procedure SetRenderMode(aRenderMode: TKMRenderMode); //Switch between 2D and 3D perspectives

    class function GetMaxTexSize: Cardinal; static;
    class function GetMaxViewportDim: Cardinal; static;
    class function GenerateTextureCommon(aMinFilter, aMagFilter: TKMFilterType): GLuint;
    class function GenTexture(DestX, DestY: Word; const Data: Pointer; Mode: TKMTexFormat; aMinFilter, aMagFilter: TKMFilterType): GLUint;
    class procedure DeleteTexture(aTex: GLUint);
    class procedure UpdateTexture(aTexture: GLuint; DestX, DestY: Word; Mode: TKMTexFormat; const Data: Pointer);
    class procedure BindTexture(aTexId: Cardinal);

    class property MaxTextureSize: Cardinal read GetMaxTexSize;
    class property MaxViewportDim: Cardinal read GetMaxViewportDim;

    property MaxFBOSize: Cardinal read GetMaxFBOSize;
    property RendererVersion: UnicodeString read fOpenGL_Version;
    function IsOldGLVersion: Boolean;
    procedure Resize(aWidth, aHeight: Integer);

    procedure ReadRenderedToScreenPixels(var aWidth, aHeight: Integer; var aPixelData: TKMCardinalArray);
    procedure ReadRenderedToFBOPixels(var aWidth, aHeight: Integer; var aPixelData: TKMCardinalArray);

    property ScreenX: Word read fScreenX;
    property ScreenY: Word read fScreenY;
    property Blind: Boolean read fBlind;

    property Query: TKMRenderQuery read fQuery;

    procedure BeginFrame;
    procedure RenderBrightness(aValue: Byte);
    procedure EndFrame;
  end;

var
  gRender: TKMRender;


implementation
uses
  SysUtils, Math,
  KromOGLUtils, KromUtils,
  KM_Log, KM_Defaults, KM_IoPNG, KM_CommonClasses;

const
  // We want to use off-screen FBO buffer to render full map to the file,
  // we are restricted with max file we are able to write via TBitmap or TJpegImage or TPNGImage atm
  // could check https://github.com/graphics32 package to solve this issue with saving ultra large images
  MAX_FBO_BUFFER_SIZE = CELL_SIZE_PX * (MAX_MAP_SIZE - 1); // (10200 = CELL_SIZE=40px)*255

{ TKMRender }
constructor TKMRender.Create(aRenderControl: TKMRenderControl; aScreenX, aScreenY: Integer; aVSync: Boolean);
begin
  inherited Create;

  gLog.AddTime('Init Render started');

  fFBOInited := False;
  fBlind := aRenderControl = nil;
  fRenderControl := aRenderControl;

  if not fBlind then
  begin
    fQuery := TKMRenderQuery.Create;

    fRenderControl.CreateRenderContext;

    fMaxTextureSize := GetMaxTexSize;
    gLog.AddTime('GL_MAX_TEXTURE_SIZE = ' + IntToStr(fMaxTextureSize));
    fMaxViewportDim := GetMaxViewportDim;
    gLog.AddTime('GL_MAX_VIEWPORT_DIM = ' + IntToStr(fMaxViewportDim));

    glClearColor(0, 0, 0, 0); 	   //Background
    glClearStencil(0);
    glDepthFunc(GL_LEQUAL);
    glShadeModel(GL_SMOOTH);                 //Enables Smooth Color Shading
    glPolygonMode(GL_FRONT, GL_FILL);
    glEnable(GL_NORMALIZE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); //Set alpha mode
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
    glEnable(GL_COLOR_MATERIAL);                 //Enable Materials
    glEnable(GL_TEXTURE_2D);                     // Enable Texture Mapping
    glDisable(GL_LIGHTING); //We don't need it
    //glEnable(GL_CULL_FACE);
    //glCullFace(GL_FRONT);

    fOpenGL_Vendor   := UnicodeString(glGetString(GL_VENDOR));   gLog.AddNoTime('OpenGL Vendor: '   + fOpenGL_Vendor);
    fOpenGL_Renderer := UnicodeString(glGetString(GL_RENDERER)); gLog.AddNoTime('OpenGL Renderer: ' + fOpenGL_Renderer);
    fOpenGL_Version  := UnicodeString(glGetString(GL_VERSION));  gLog.AddNoTime('OpenGL Version: '  + fOpenGL_Version);

    SetupVSync(aVSync);

    Resize(aScreenX, aScreenY);
  end;
  gLog.AddTime('Init Render Done');
end;


destructor TKMRender.Destroy;
begin
  if not fBlind then
  begin
    fRenderControl.DestroyRenderContext;
    fQuery.Free;

    if fFBOInited then
    begin
      glDeleteFramebuffers(1,@fFBO);
      glDeleteRenderbuffers(1,@fRenderBuf);
    end;
  end;

  inherited;
end;


procedure TKMRender.InitFBO;
begin
  if fFBOInited then Exit;

  fFBOInited := True;

  glGenFramebuffers(1, @fFBO);
  glGenRenderbuffers(1, @fRenderBuf);
  glBindRenderbuffer(GL_RENDERBUFFER, fRenderBuf);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, GetMaxFBOSize, GetMaxFBOSize);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fFBO);
  glFramebufferRenderbuffer(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, fRenderBuf);
end;


//We have to use this method EVERY time we want to bind texture. Otherwise collisions could happen
//
//Do not bind same texture again, it can drastically change render performance
//F.e. on an average Map (Cube 256x256) when full map is shown in viewport
//there are only ~10k new texture binds, when all other ~30k binds can be skipped
class procedure TKMRender.BindTexture(aTexId: Cardinal);
begin
  if aTexId <> fLastBindedTextureId then
  begin
    glBindTexture(GL_TEXTURE_2D, aTexId);
    fLastBindedTextureId := aTexId;
  end;
end;


procedure TKMRender.Resize(aWidth, aHeight: Integer);
begin
  if fBlind then Exit;

  fScreenX := max(aWidth, 1);
  fScreenY := max(aHeight, 1);
  glViewport(0, 0, fScreenX, fScreenY);
end;


procedure TKMRender.SetRenderMode(aRenderMode: TKMRenderMode);
begin
  if fBlind then Exit;

  glMatrixMode(GL_PROJECTION); //Change Matrix Mode to Projection
  glLoadIdentity; //Reset View

  //In 2D mode we use Z-test to clip terrain shadows behind mountains
  //1 unit for each tile strip. 512 means we can handle up to 512x512 maps
  case aRenderMode of
    rm2D: glOrtho(0, fScreenX, fScreenY, 0, -100, 100);
    rm3D: gluPerspective(80, -fScreenX/fScreenY, 0.1, 5000);
  end;
  glMatrixMode(GL_MODELVIEW); //Return to the modelview matrix
  glLoadIdentity; //Reset View
end;


class function TKMRender.GenerateTextureCommon(aMinFilter, aMagFilter: TKMFilterType): GLuint;
var
  texture: GLuint;
begin
  Result := 0;
  if not Assigned(glGenTextures) then Exit;

  glGenTextures(1, @texture);
  BindTexture(texture);

  {Enable color blending into texture}
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  //GL_MODULATE is our choice
  //GL_REPLACE is also available since version 1.1
  //can't use GL_REPLACE cos it disallows blending of texture with custom color (e.g. trees in FOW)

  {Use nearest filter to keep original KaM grainy look}
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, TEX_FILTER[aMinFilter]);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, TEX_FILTER[aMagFilter]);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);

  {Clamping UVs solves edge artifacts}
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
  Result := texture;
end;


//Generate texture out of TCardinalArray
class function TKMRender.GenTexture(DestX, DestY: Word; const Data: Pointer; Mode: TKMTexFormat; aMinFilter, aMagFilter: TKMFilterType): GLUint;
begin
  Result := GenerateTextureCommon(aMinFilter, aMagFilter);
  UpdateTexture(Result, DestX, DestY, Mode, Data);
end;


class procedure TKMRender.DeleteTexture(aTex: GLUint);
begin
  glDeleteTextures(1, @aTex);
end;


function TKMRender.GetMaxFBOSize: Cardinal;
begin
  Result := Min(fMaxViewportDim, MAX_FBO_BUFFER_SIZE);
end;


class function TKMRender.GetMaxTexSize: Cardinal;
begin
  if fMaxTextureSize > 0 then Exit(fMaxTextureSize);

  //Get max supported texture size by video adapter
  glGetIntegerv(GL_MAX_TEXTURE_SIZE, @fMaxTextureSize);
  Result := fMaxTextureSize;
end;


class function TKMRender.GetMaxViewportDim: Cardinal;
begin
  if fMaxViewportDim > 0 then Exit(fMaxViewportDim);

  //Get max supported dimensions for viewport (used in off-screen render, FBO)
  glGetIntegerv(GL_MAX_VIEWPORT_DIMS, @fMaxViewportDim);
  Result := fMaxViewportDim;
end;


//Update texture with TCardinalArray
class procedure TKMRender.UpdateTexture(aTexture: GLuint; DestX, DestY: Word; Mode: TKMTexFormat; const Data: Pointer);
begin
  if not Assigned(glTexImage2D) then Exit;

  Assert((DestX * DestY > 0) and (DestX = MakePOT(DestX)) and (DestY = MakePOT(DestY)),
         Format('Game designed to handle only POT textures. Texture size: [%d:%d]', [DestX,DestY]));

  BindTexture(aTexture);

  //GL_ALPHA   (0-0-0-8 bit) - 
  //GL_RGB5_A1 (5-5-5-1 bit) - 
  //GL_RGBA    (8-8-8-8 bit) - allows fuzzy shadows
  //Figures are before trimming - only ratio matters
  case Mode of
    //Base layer
    tfRGB5A1:  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB5_A1, DestX, DestY, 0, GL_RGBA, GL_UNSIGNED_BYTE, Data);
    //Base layer with alpha channel for shadows
    tfRGBA8:   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, DestX, DestY, 0, GL_RGBA, GL_UNSIGNED_BYTE, Data);
    //Team color layer (4 bit would be okay), but house construction steps need 8bit resolution
    tfAlpha8:  glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA,  DestX, DestY, 0, GL_RGBA, GL_UNSIGNED_BYTE, Data);
  end;
  BindTexture(0);
end;


//1.4 is considered to be our minimal requirement
function TKMRender.IsOldGLVersion: Boolean;
begin
  Result := not fBlind and not GL_VERSION_1_4;
end;


procedure TKMRender.ReadRenderedToScreenPixels(var aWidth, aHeight: Integer; var aPixelData: TKMCardinalArray);
begin
  SaveBufferToFile(False, aWidth, aHeight, aPixelData);
end;


procedure TKMRender.ReadRenderedToFBOPixels(var aWidth, aHeight: Integer; var aPixelData: TKMCardinalArray);
begin
  SaveBufferToFile(True, aWidth, aHeight, aPixelData);
end;


procedure TKMRender.SaveBufferToFile(aUseFBOBuffer: Boolean; var aWidth, aHeight: Integer; var aPixelData: TKMCardinalArray);
{$IFDEF WDC}
var
  I, K: Integer;
{$ENDIF}
begin
{$IFDEF WDC}
  aWidth := ScreenX;
  aHeight := ScreenY;

  if aUseFBOBuffer then
  begin
    // Read from offscreen buffer
    glReadBuffer(GL_COLOR_ATTACHMENT0);
    // Bind to FBO framebuffer
    glBindFramebuffer(GL_READ_FRAMEBUFFER, fFBO);
  end
  else
    // Read from onscreen buffer
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);

  SetLength(aPixelData, aWidth * aHeight + 1);
  glReadPixels(0, 0, aWidth, aHeight, GL_BGRA, GL_UNSIGNED_BYTE, @aPixelData[0]);

  if aUseFBOBuffer then
    // Return to onscreen rendering:
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

  //Mirror verticaly
  for i := 0 to (aHeight div 2) - 1 do
    for K := 0 to aWidth - 1 do
      SwapInt(aPixelData[i * aWidth + K], aPixelData[((aHeight - 1) - i) * aWidth + K]);
{$ENDIF}
end;


procedure TKMRender.BeginFrame;
begin
  if fBlind then Exit;

  if SAVE_MAP_TO_FBO_RENDER then
  begin
    if not fFBOInited then
      // Init once
      InitFBO // glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fFBO) is called while initialization
    else
      glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fFBO);
  end;

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
  SetRenderMode(rm2D);

  //RC.Activate for OSX
end;


//Render highlight overlay to make whole picture look brighter (more saturated)
procedure TKMRender.RenderBrightness(aValue: Byte);
begin
  if fBlind then Exit;

  //There will be no change to image anyway
  if aValue = 0 then Exit;

  BindTexture(0); // We have to reset texture to default (0), because it could be bind to any other texture (atlas)

  glLoadIdentity;
  glBlendFunc(GL_DST_COLOR, GL_ONE);
  glColor4f(aValue/20, aValue/20, aValue/20, aValue/20);
  glBegin(GL_QUADS);
    glkRect(0, 0, ScreenX, ScreenY);
  glEnd;

  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
end;


procedure TKMRender.EndFrame;
begin
  if fBlind then Exit;

  glFinish;
  fRenderControl.SwapBuffers;
end;


end.
