{$I COMPILER_DIRECTIVES.INC}
unit mainUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Platform;

type
  TMainForm = class(TForm)
    mathLineLabel: TLabel;
    mathLineBG: TRectangle;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FunctionMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FunctionMouseUp(Sender: TObject; Button: TMouseButton;   Shift: TShiftState; X, Y: Single);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure OutputMathResult;
    procedure AdjustResultFontSize;

    {$IFDEF ANDROID}
    function  HandleAppEvent(AAppEvent: TApplicationEvent; AContext: TObject): Boolean;
    {$ENDIF}
  end;

  TCalcKeyRecord =
  Record
    keyFunction : Integer;
    keyText     : String;
    keyColumn   : Integer;
    keyRow      : Integer;
    keyShade    : Integer;
  End;


const
  calcKeyS1L1Grad1  : TAlphaColor = $FFF0F0F0;
  calcKeyS1L1Grad2  : TAlphaColor = $FFC0C0C0;
  calcKeyS1L2Grad1  : TAlphaColor = $FFE0E0E0;
  calcKeyS1L2Grad2  : TAlphaColor = $FFB0B0B0;

  calcKeyS2L1Grad1  : TAlphaColor = $FFB0B0B0;
  calcKeyS2L1Grad2  : TAlphaColor = $FF909090;
  calcKeyS2L2Grad1  : TAlphaColor = $FFA0A0A0;
  calcKeyS2L2Grad2  : TAlphaColor = $FF707070;

  calcKeyS3L1Grad1  : TAlphaColor = $FFEFB000;
  calcKeyS3L1Grad2  : TAlphaColor = $FFAF6000;
  calcKeyS3L2Grad1  : TAlphaColor = $FFEDB000;
  calcKeyS3L2Grad2  : TAlphaColor = $FFAF6000;

  multiplySymbol  = #$00D7;
  divisionSymbol  = #$00F7;
  backspaceSymbol = #$2190;//#$232B;

  keyShade1       =  0;
  keyShade2       =  1;
  keyShade3       =  2;

  funcClear       =  0;
  funcPlus        =  1;
  funcMinus       =  2;
  funcDivide      =  3;
  funcMultiply    =  4;
  funcBackSpace   =  5;
  func0           =  6;
  func1           =  7;
  func2           =  8;
  func3           =  9;
  func4           = 10;
  func5           = 11;
  func6           = 12;
  func7           = 13;
  func8           = 14;
  func9           = 15;
  funcDot         = 16;
  funcMemory      = 17;
  funcRecall      = 18;
  funcEqual       = 19;


  calcKeyCount    = 20;
  calcKeyMap      : Array[0..calcKeyCount-1] of TCalcKeyRecord = (
     (keyFunction : funcClear    ; keyText : 'C';              keyColumn : 0;  keyRow : 0;  KeyShade : keyShade2),
     (keyFunction : funcDivide   ; keyText : divisionSymbol;   keyColumn : 1;  keyRow : 0;  KeyShade : keyShade2),
     (keyFunction : funcMultiply ; keyText : multiplySymbol;   keyColumn : 2;  keyRow : 0;  KeyShade : keyShade2),
     (keyFunction : funcBackSpace; keyText : backspaceSymbol;  keyColumn : 3;  keyRow : 0;  KeyShade : keyShade2),

     (keyFunction : func7        ; keyText : '7';              keyColumn : 0;  keyRow : 1;  KeyShade : keyShade1),
     (keyFunction : func8        ; keyText : '8';              keyColumn : 1;  keyRow : 1;  KeyShade : keyShade1),
     (keyFunction : func9        ; keyText : '9';              keyColumn : 2;  keyRow : 1;  KeyShade : keyShade1),
     (keyFunction : funcMinus    ; keyText : '-';              keyColumn : 3;  keyRow : 1;  KeyShade : keyShade2),

     (keyFunction : func4        ; keyText : '4';              keyColumn : 0;  keyRow : 2;  KeyShade : keyShade1),
     (keyFunction : func5        ; keyText : '5';              keyColumn : 1;  keyRow : 2;  KeyShade : keyShade1),
     (keyFunction : func6        ; keyText : '6';              keyColumn : 2;  keyRow : 2;  KeyShade : keyShade1),
     (keyFunction : funcPlus     ; keyText : '+';              keyColumn : 3;  keyRow : 2;  KeyShade : keyShade2),

     (keyFunction : func1        ; keyText : '1';              keyColumn : 0;  keyRow : 3;  KeyShade : keyShade1),
     (keyFunction : func2        ; keyText : '2';              keyColumn : 1;  keyRow : 3;  KeyShade : keyShade1),
     (keyFunction : func3        ; keyText : '3';              keyColumn : 2;  keyRow : 3;  KeyShade : keyShade1),
     (keyFunction : funcDot      ; keyText : '.';              keyColumn : 3;  keyRow : 3;  KeyShade : keyShade2),

     (keyFunction : funcMemory   ; keyText : 'M';              keyColumn : 0;  keyRow : 4;  KeyShade : keyShade3),
     (keyFunction : func0        ; keyText : '0';              keyColumn : 1;  keyRow : 4;  KeyShade : keyShade1),
     (keyFunction : funcRecall   ; keyText : 'MR';             keyColumn : 2;  keyRow : 4;  KeyShade : keyShade3),
     (keyFunction : funcEqual    ; keyText : '=';              keyColumn : 3;  keyRow : 4;  KeyShade : keyShade2)
      );

  stAdd = 0;
  stSub = 1;
  stMul = 2;
  stDiv = 3;


var
  MainForm            : TMainForm;
  clientMemoryValue   : String = '';
  clientScreenService : IFMXScreenService;

implementation

{$R *.fmx}

uses System.Character, FMX.Utils, System.IOUtils, System.Diagnostics, misc_utils;

const
  clientGameName                    : String = 'Elegant Calculator';

var
  UserDataPath                      : String;
  clientStopWatch                   : TStopWatch;
  clientScreenSize                  : TSize;
  clientScreenScale                 : Single      = 1;
  clientScreenScaleSrc              : Single      = 1;
  clientFunctionPressed             : Integer     = -1;
  clientDotEnabled                  : Boolean     = False;
  clientResultShown                 : Boolean     = False;
  lastResizeWidth                   : Integer     = -1;
  lastResizeHeight                  : Integer     = -1;
  calcKeyImages                     : Array[0..calcKeyCount-1] of TImage;


procedure TMainForm.FormCreate(Sender: TObject);
{$IFDEF ANDROID}
var
  FMXApplicationEventService : IFMXApplicationEventService;
{$ENDIF}
begin
  // Initialize the stopwatch used for timestamping
  clientStopWatch := TStopWatch.Create;
  clientStopWatch.Start;

  {$IFDEF ANDROID}
  if TPlatformServices.Current.SupportsPlatformService(IFMXApplicationEventService, IInterface(FMXApplicationEventService)) then
    FMXApplicationEventService.SetApplicationEventHandler(HandleAppEvent);
  {$ENDIF}

  UserDataPath := System.IOUtils.TPath.GetHomePath+System.IOUtils.TPath.DirectorySeparatorChar+clientGameName+System.IOUtils.TPath.DirectorySeparatorChar;

  {$IFDEF ANDROID}
    if TPlatformServices.Current.SupportsPlatformService(IFMXScreenService, IInterface(clientScreenService)) then
    begin
      clientScreenScale       := clientScreenService.GetScreenScale;
      clientScreenScaleSrc    := clientScreenScale;
    end;

    clientScreenSize.CX       := Round(clientScreenService.GetScreenSize.X*clientScreenScale);
    clientScreenSize.CY       := Round(clientScreenService.GetScreenSize.Y*clientScreenScale);

    {$IFDEF LIMITRES}
    If (clientScreenSize.CX >= 1280) or (clientScreenSize.CY >= 1280) then
    begin
      clientScreenScale       := clientScreenScale / 2;
      clientScreenSize.CX     := Round(clientScreenService.GetScreenSize.X*clientScreenScale);
      clientScreenSize.CY     := Round(clientScreenService.GetScreenSize.Y*clientScreenScale);
    end;
    {$ENDIF}

    MainForm.ClientWidth       := clientScreenSize.CX;
    MainForm.ClientHeight      := clientScreenSize.CY;
  {$ELSE}
    {$IFDEF TESTSCALE}
      clientScreenScale       := 2;
      clientScreenScaleSrc    := 4;
    {$ENDIF}

    {$IFDEF FAKEMOBILE}
      {$IFDEF REZ_360x780}  ClientWidth :=  360; ClientHeight :=  780;{$ENDIF}
      {$IFDEF REZ_360x740}  ClientWidth :=  360; ClientHeight :=  740;{$ENDIF}
      {$IFDEF REZ_360x640}  ClientWidth :=  360; ClientHeight :=  640;{$ENDIF}
      {$IFDEF REZ_480x800}  ClientWidth :=  480; ClientHeight :=  800;{$ENDIF}
      {$IFDEF REZ_540x960}  ClientWidth :=  540; ClientHeight :=  960;{$ENDIF}
      {$IFDEF REZ_576x1024} ClientWidth :=  576; ClientHeight := 1024;{$ENDIF}
      {$IFDEF REZ_720x1280} ClientWidth :=  720; ClientHeight := 1280;{$ENDIF}
      {$IFDEF REZ_1080x1920}ClientWidth := 1080; ClientHeight := 1920;{$ENDIF}
      {$IFDEF REZ_1440x2560}ClientWidth := 1440; ClientHeight := 2560;{$ENDIF}
      {$IFDEF REZ_2160x3840}ClientWidth := 2160; ClientHeight := 3840;{$ENDIF}

      //ClientWidth := 240; ClientHeight := 400;
      //ClientWidth := 484; ClientHeight := 800; // test partial pixel magnification rendering
    {$ELSE}
      //ClientWidth   := 1056; ClientHeight  := 594;
      ClientWidth  := Screen.DisplayFromForm(Self).BoundsRect.Width;
      ClientHeight := Screen.DisplayFromForm(Self).BoundsRect.Height;
      //ClientWidth   := 1600; ClientHeight  := 900;
      //ClientWidth   := 1200; ClientHeight  := 980;
    {$ENDIF}
    clientScreenSize.CX     := Trunc(ClientWidth*clientScreenScale);
    clientScreenSize.CY     := Trunc(ClientHeight*clientScreenScale);

    {$IFDEF DISPLAYON4K}
    SetBounds(4600,1240,ClientWidth,ClientHeight);
    {$ELSE}
    SetBounds((Screen.Width-ClientWidth) div 2,(Screen.Height-ClientHeight) div 2,ClientWidth,ClientHeight);
    {$ENDIF}
  {$ENDIF}
end;


procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  case Key of
    vkHardwareBack,vkEscape :
    begin
      Key := 0;
      Close;
    end;
  end;
end;


procedure TMainForm.FormResize(Sender: TObject);
const
  keyboardHeight     : Single  = 0.75;
  keyColumns         : Integer = 4;
  keyRows            : Integer = 5;
  keyTextHeight      : Single  = 0.40;

var
  I                  : Integer;
  fullKeyboardHeight : Integer;
  fullKeyboardWidth  : Integer;
  fullKeyboardYOfs   : Integer;
  tmpBM              : TBitmap;
  aRect              : TRectF;
  bShadeL1Grad1      : TAlphaColor;
  bShadeL1Grad2      : TAlphaColor;
  bShadeL2Grad1      : TAlphaColor;
  bShadeL2Grad2      : TAlphaColor;

  CBase              : Integer;
  C1Width            : Integer;
  C2Width            : Integer;
  C3Width            : Integer;
  C4Width            : Integer;

  R1Height           : Integer;
  R2Height           : Integer;
  R3Height           : Integer;
  R4Height           : Integer;
  R5Height           : Integer;
  RBase              : Integer;

  keyWidth           : Integer;
  keyHeight          : Integer;
  keyXOfs            : Integer;
  keyYOfs            : Integer;

begin
  If (clientWidth = 0) or (clientHeight = 0) then
  Begin
    {$IFDEF TRACEDEBUG}AddDebugEntry('FormResize exit on zero width or height');{$ENDIF}
    Exit;
  End;

  If (lastResizeWidth = clientWidth) and (lastResizeHeight = clientHeight) then
  Begin
    {$IFDEF TRACEDEBUG}AddDebugEntry('FormResize exit on same resolution');{$ENDIF}
    Exit;
  End;

  {$IFDEF TRACEDEBUG}AddDebugEntry('FormResize (before)');{$ENDIF}

  lastResizeWidth  := Trunc(clientWidth);
  lastResizeHeight := Trunc(clientHeight);

  // Make sure there's no extra spaces
  fullKeyboardHeight := Trunc(clientHeight*keyboardHeight);
  RBase    := Trunc(fullKeyboardHeight/5);
  R1Height := RBase;
  R2Height := RBase;
  R3Height := RBase;
  R4Height := RBase;
  R5Height := RBase;
  While R1Height+R2Height+R3Height+R4Height+R5Height < fullKeyboardHeight do
  Begin
    If R1Height = RBase then Inc(R1Height) else
      If R2Height = RBase then Inc(R2Height) else
        If R3Height = RBase then Inc(R3Height) else
          If R4Height = RBase then Inc(R4Height) else
            If R5Height = RBase then Inc(R5Height) else Break;
  End;

  fullKeyboardWidth := Trunc(clientWidth);
  CBase    := Trunc(fullKeyboardWidth/4);
  C1Width  := CBase;
  C2Width  := CBase;
  C3Width  := CBase;
  C4Width  := CBase;
  While C1Width+C2Width+C3Width+C4Width < fullKeyboardWidth do
  Begin
    If C1Width = CBase then Inc(C1Width) else
      If C2Width = CBase then Inc(C2Width) else
        If C3Width = CBase then Inc(C3Width) else
          If C4Width = CBase then Inc(C4Width) else Break;
  End;
  fullKeyboardYOfs := Trunc(clientHeight-(R1Height+R2Height+R3Height+R4Height+R5Height));

  tmpBM := TBitmap.Create;
  For I := 0 to calcKeyCount-1 do
  Begin
    Case calcKeyMap[I].keyRow of
      0 :  Begin keyHeight := R1Height; keyYOfs := 0; End;
      1 :  Begin keyHeight := R2Height; keyYOfs := R1Height; End;
      2 :  Begin keyHeight := R3Height; keyYOfs := R1Height+R2Height; End;
      3 :  Begin keyHeight := R4Height; keyYOfs := R1Height+R2Height+R3Height; End;
      else Begin keyHeight := R5Height; keyYOfs := R1Height+R2Height+R3Height+R4Height; End;
    End;

    Case calcKeyMap[I].keyColumn of
      0 :  Begin keyWidth := C1Width; keyXOfs := 0; End;
      1 :  Begin keyWidth := C2Width; keyXOfs := C1Width; End;
      2 :  Begin keyWidth := C3Width; keyXOfs := C1Width+C2Width; End;
      else Begin keyWidth := C4Width; keyXOfs := C1Width+C2Width+C3Width; End;
    End;

    calcKeyImages[I]             := TImage.Create(MainForm);
    calcKeyImages[I].Parent      := MainForm;
    calcKeyImages[I].Tag         := calcKeyMap[I].keyFunction;
    calcKeyImages[I].OnMouseDown := FunctionMouseDown;
    calcKeyImages[I].OnMouseUp   := FunctionMouseUp;
    calcKeyImages[I].SetBounds(
      KeyXOfs,
      fullKeyboardYOfs+KeyYOfs,
      keyWidth,
      keyHeight);
    calcKeyImages[I].Bitmap.SetSize(Trunc(calcKeyImages[I].Width*clientScreenScaleSrc),Trunc(calcKeyImages[I].Height*clientScreenScaleSrc));

    Case calcKeyMap[I].keyShade of
      KeyShade1 :
      Begin
        bShadeL1Grad1 := calcKeyS1L1Grad1;
        bShadeL1Grad2 := calcKeyS1L1Grad2;
        bShadeL2Grad1 := calcKeyS1L2Grad1;
        bShadeL2Grad2 := calcKeyS1L2Grad2;
      End;
      KeyShade2 :
      Begin
        bShadeL1Grad1 := calcKeyS2L1Grad1;
        bShadeL1Grad2 := calcKeyS2L1Grad2;
        bShadeL2Grad1 := calcKeyS2L2Grad1;
        bShadeL2Grad2 := calcKeyS2L2Grad2;
      End;
      else
      Begin
        bShadeL1Grad1 := calcKeyS3L1Grad1;
        bShadeL1Grad2 := calcKeyS3L1Grad2;
        bShadeL2Grad1 := calcKeyS3L2Grad1;
        bShadeL2Grad2 := calcKeyS3L2Grad2;
      End;
    End;

    GradientRectH(calcKeyImages[I].Bitmap,0,0,calcKeyImages[I].Bitmap.Width,calcKeyImages[I].Bitmap.Height,bShadeL1Grad1,bShadeL1Grad2);
    tmpBM.SetSize(calcKeyImages[I].Bitmap.Width,calcKeyImages[I].Bitmap.Height);
    GradientRectV(tmpBM,0,0,tmpBM.Width,tmpBM.Height,bShadeL2Grad1,bShadeL2Grad2);

    {f calcKeyMap[I].keyShade = KeyShade3 then
    Begin
      calcKeyImages[I].Bitmap.SaveToFile('d:\test1.png');
      tmpBM.SaveToFile('d:\test2.png');
    End;}

    MergeBitmap(tmpBM,calcKeyImages[I].Bitmap,0,0);

    aRect := TRectF.Create(0,0,calcKeyImages[I].Width,calcKeyImages[I].Height);

    calcKeyImages[I].Bitmap.Canvas.BeginScene;
    calcKeyImages[I].Bitmap.Canvas.Fill.Color  := $FF000000;
    calcKeyImages[I].Bitmap.Canvas.Stroke.Kind := TBrushKind.Solid;
    calcKeyImages[I].Bitmap.Canvas.Font.Size   := Trunc(calcKeyImages[I].Height*keyTextHeight);
    //calcKeyImages[I].Bitmap.Canvas.Font.Family := 'Tahoma';
    calcKeyImages[I].Bitmap.Canvas.FillText(
      aRect,
      calcKeyMap[I].KeyText,
      False,
      0.6,
      [],
      TTextAlign.Center,
      TTextAlign.Center);
    calcKeyImages[I].Bitmap.Canvas.EndScene;
  End;
  tmpBM.Free;

  mathLineBG.SetBounds(0,0,clientWidth,fullKeyboardYOfs);
  mathLineLabel.SetBounds(0,0,clientWidth,mathLineBG.Height);
end;


procedure TMainForm.FunctionMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  clientFunctionPressed := TImage(Sender).Tag;
end;


procedure TMainForm.FunctionMouseUp(Sender: TObject; Button: TMouseButton;   Shift: TShiftState; X, Y: Single);
var
  I : Integer;
begin
  If clientResultShown = True then
  Begin
    Case TImage(Sender).Tag of
      func0..func9 :
      Begin
        clientResultShown  := False;
        mathLineLabel.Text := '';
      End;
      else clientResultShown  := False;
    End;
  End;
  If clientFunctionPressed = TImage(Sender).Tag then
  Case TImage(Sender).Tag of
    funcClear     :
    Begin
      mathLineLabel.Text := '';
      clientDotEnabled   := False;
    End;
    funcPlus      :
    begin
      If mathLineLabel.Text <> '' then If mathLineLabel.Text[High(mathLineLabel.Text)].IsInArray([divisionSymbol,multiplySymbol,'+','-']) = False then
      Begin
        If mathLineLabel.Text[High(mathLineLabel.Text)] = '.' then mathLineLabel.Text := mathLineLabel.Text+'0';
        mathLineLabel.Text := mathLineLabel.Text+'+';
        clientDotEnabled   := False;
      End;
    end;
    funcMinus     :
    Begin
      If mathLineLabel.Text <> '' then If mathLineLabel.Text[High(mathLineLabel.Text)].IsInArray([divisionSymbol,multiplySymbol,'+','-']) = False then
      Begin
        If mathLineLabel.Text[High(mathLineLabel.Text)] = '.' then mathLineLabel.Text := mathLineLabel.Text+'0';
        mathLineLabel.Text := mathLineLabel.Text+'-';
        clientDotEnabled   := False;
      End;
    End;
    funcDivide    :
    Begin
      If mathLineLabel.Text <> '' then If mathLineLabel.Text[High(mathLineLabel.Text)].IsInArray([divisionSymbol,multiplySymbol,'+','-']) = False then
      Begin
        If mathLineLabel.Text[High(mathLineLabel.Text)] = '.' then mathLineLabel.Text := mathLineLabel.Text+'0';
        mathLineLabel.Text := mathLineLabel.Text+divisionSymbol;
        clientDotEnabled   := False;
      End;
    End;
    funcMultiply  :
    Begin
      If mathLineLabel.Text <> '' then If mathLineLabel.Text[High(mathLineLabel.Text)].IsInArray([divisionSymbol,multiplySymbol,'+','-']) = False then
      Begin
        If mathLineLabel.Text[High(mathLineLabel.Text)] = '.' then mathLineLabel.Text := mathLineLabel.Text+'0';
        mathLineLabel.Text := mathLineLabel.Text+multiplySymbol;
        clientDotEnabled   := False;
      End;
    End;
    funcBackSpace :
    Begin
      If mathLineLabel.Text <> '' then
      Begin
        Case mathLineLabel.Text[High(mathLineLabel.Text)] of
          '.'            : clientDotEnabled := False;
          '+',
          '-',
          divisionSymbol,
          multiplySymbol :
          Begin
            For I := High(mathLineLabel.Text)-1 downto Low(mathLineLabel.Text) do
            Begin
              Case mathLineLabel.Text[I] of
                '.'            :
                Begin
                  clientDotEnabled := True;
                  Break;
                End;
                '+',
                '-',
                divisionSymbol,
                multiplySymbol :
                Begin
                  clientDotEnabled := False;
                  Break;
                End;
              End;
            End;
          End;
        End;
        mathLineLabel.Text := Copy(mathLineLabel.Text,Low(mathLineLabel.Text),High(mathLineLabel.Text)-Low(mathLineLabel.Text));
      End;
    End;
    func0         : mathLineLabel.Text := mathLineLabel.Text+'0';
    func1         : mathLineLabel.Text := mathLineLabel.Text+'1';
    func2         : mathLineLabel.Text := mathLineLabel.Text+'2';
    func3         : mathLineLabel.Text := mathLineLabel.Text+'3';
    func4         : mathLineLabel.Text := mathLineLabel.Text+'4';
    func5         : mathLineLabel.Text := mathLineLabel.Text+'5';
    func6         : mathLineLabel.Text := mathLineLabel.Text+'6';
    func7         : mathLineLabel.Text := mathLineLabel.Text+'7';
    func8         : mathLineLabel.Text := mathLineLabel.Text+'8';
    func9         : mathLineLabel.Text := mathLineLabel.Text+'9';
    funcDot       :
    Begin
      If mathLineLabel.Text = '' then
      Begin
        mathLineLabel.Text := '0.';
        clientDotEnabled   := True;
      End
        else
      If (clientDotEnabled = False) and (mathLineLabel.Text[High(mathLineLabel.Text)].IsInArray([divisionSymbol,multiplySymbol,'+','-','.']) = False) then
      Begin
        mathLineLabel.Text := mathLineLabel.Text+'.';
        clientDotEnabled   := True;
      End;
    End;
    funcMemory    :
    Begin
      If (Pos(multiplySymbol,mathLineLabel.Text) > 0) or (Pos(divisionSymbol,mathLineLabel.Text) > 0) or
         (Pos('+',mathLineLabel.Text) > 0) or (Pos('-',mathLineLabel.Text) > 0) then OutputMathResult;
      clientMemoryValue := mathLineLabel.Text;
    End;
    funcRecall    :
    If clientMemoryValue <> '' then
    Begin
      If mathLineLabel.Text <> '' then
      Begin
        //If CharInSet(mathLineLabel.Text[High(mathLineLabel.Text)],[divisionSymbol,multiplySymbol,'+','-']) = True then
        If mathLineLabel.Text[High(mathLineLabel.Text)].IsInArray([divisionSymbol,multiplySymbol,'+','-']) = True then
          mathLineLabel.Text := mathLineLabel.Text+clientMemoryValue;
      End
      Else mathLineLabel.Text := clientMemoryValue;
    End;
    funcEqual     : OutputMathResult;
  End;
  AdjustResultFontSize;
end;


function PerformMathAction(wString : String; var wValue : Extended; wState : Integer{; var firstValue : Boolean}) : Integer;
var
  nValue  : Extended;
begin
  Result := S_OK;
  Try
    nValue  := StrToFloat(wString);
    Case wState of
      stAdd : wValue := wValue+nValue;
      stSub : wValue := wValue-nValue;
      stMul : wValue := wValue*nValue;
      stDiv : If nValue > 0 then wValue := wValue/nValue else Result := S_FALSE;
    End;
  Finally
  End;
end;


function ParseMathForumla(S : String) : String;
var
  I       : Integer;
  cValue  : Extended;
  cString : String;
  cState  : Integer;
  ErrCode : Integer;
begin
  ErrCode := S_OK;
  cString := '';
  cValue  := 0;
  cState  := stAdd;
  For I := Low(S) to High(S) do
  Begin
    If S[I].IsInArray([divisionSymbol,multiplySymbol,'-','+']) = False then
    Begin
      cString := cString+S[I];
    End
      else
    Begin
      If Length(cString) > 0 then
      Begin
        ErrCode := PerformMathAction(cString,cValue,cState);
        cString := '';
      End;
      Case S[I] of
        divisionSymbol : cState := stDiv;
        multiplySymbol : cState := stMul;
        '-'            : cState := stSub;
        '+'            : cState := stAdd;
      End;
    End;
  End;
  If Length(cString) > 0 then ErrCode := PerformMathAction(cString,cValue,cState);
  If ErrCode = S_OK then Result := FloatToStr(cValue) else Result := S;
end;


procedure TMainForm.OutputMathResult;
begin
  mathLineLabel.Text    := ParseMathForumla(mathLineLabel.Text);

  clientResultShown     := True;
end;


{$IFDEF ANDROID}
function TMainForm.HandleAppEvent(AAppEvent: TApplicationEvent; AContext: TObject): Boolean;
begin
  Result := False;
  case AAppEvent of
    TApplicationEvent.FinishedLaunching:
    Begin
    End;
    TApplicationEvent.BecameActive:
    Begin
      Result := True;
    End;
    TApplicationEvent.WillBecomeInactive:
    Begin
    End;
    TApplicationEvent.EnteredBackground:
    Begin
      Result := True;
    End;
    TApplicationEvent.WillBecomeForeground:
    Begin
      Result := True;
    End;
    TApplicationEvent.WillTerminate:
    Begin
    End;
    TApplicationEvent.LowMemory:
    Begin
    End;
  end;
end;
{$ENDIF}


procedure TMainForm.AdjustResultFontSize;
const
  maxTextHeight : Single = 0.5;
  maxTextWidth  : Single = 0.9;
var
  S         : String;
begin
  S := mathLineLabel.Text;
  mathLineLabel.Font.Size := Trunc(mathLineLabel.Height)*maxTextHeight;
  mathLineLabel.Canvas.Font.Assign(mathLineLabel.Font);
  While (mathLineLabel.Canvas.TextWidth(S) > mathLineLabel.Width*maxTextWidth) or (mathLineLabel.Canvas.TextHeight(S) > mathLineLabel.Height*maxTextHeight) do
  Begin
    mathLineLabel.Font.Size := mathLineLabel.Font.Size-1;
    mathLineLabel.Canvas.Font.Size := mathLineLabel.Font.Size;
  End;
end;




end.
