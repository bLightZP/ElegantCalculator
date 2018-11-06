{$I COMPILER_DIRECTIVES.INC}
unit misc_utils;

interface

uses
  System.UITypes, FMX.Graphics;


procedure MergeBitmap(sBitmap,mBitmap : TBitmap; xOfs,yOfs : Integer);
procedure GradientRectV(destBitmap : TBitmap; xOfs,yOfs,Width,Height : Integer; sRGB32,dRGB32 : TAlphaColor);
procedure GradientRectH(destBitmap : TBitmap; xOfs,yOfs,Width,Height : Integer; sRGB32,dRGB32 : TAlphaColor);


implementation

uses
  FMX.Utils, FMX.Types, optimizedscanlineunit;


procedure GradientRectH(destBitmap : TBitmap; xOfs,yOfs,Width,Height : Integer; sRGB32,dRGB32 : TAlphaColor);
var
  bitmapData   : FMX.Graphics.TBitmapData;
  gradientLine : Array of TAlphaColor;
  tmpScanLine  : PAlphaColorArray;
  Speed1       : Integer;
  Speed2       : Integer;
  Y,X          : Integer;
  tmpByte      : Byte;
begin
  If yOfs+1 > DestBitmap.Height-1 then Exit;

  // Switch Blue <-> Red if needed
  If destBitmap.PixelFormat = TPixelFormat.RGBA then
  begin
    tmpByte := TAlphaColorRec(sRGB32).R;
    TAlphaColorRec(sRGB32).R := TAlphaColorRec(sRGB32).B;
    TAlphaColorRec(sRGB32).B := tmpByte;
    tmpByte := TAlphaColorRec(dRGB32).R;
    TAlphaColorRec(dRGB32).R := TAlphaColorRec(dRGB32).B;
    TAlphaColorRec(dRGB32).B := tmpByte;
  end;

  // Calculate gradient
  SetLength(gradientLine,Width);
  For X := 1 to Width do
  Begin
    // Pre-calculate some more repeated math
    Speed1 := Width-X;
    Speed2 := xOfs+X-1;
    TAlphaColorRec(gradientLine[Speed2]).R := ((Speed1*TAlphaColorRec(sRGB32).R) + (X*TAlphaColorRec(dRGB32).R)) div Width;
    TAlphaColorRec(gradientLine[Speed2]).G := ((Speed1*TAlphaColorRec(sRGB32).G) + (X*TAlphaColorRec(dRGB32).G)) div Width;
    TAlphaColorRec(gradientLine[Speed2]).B := ((Speed1*TAlphaColorRec(sRGB32).B) + (X*TAlphaColorRec(dRGB32).B)) div Width;
    TAlphaColorRec(gradientLine[Speed2]).A := ((Speed1*TAlphaColorRec(sRGB32).A) + (X*TAlphaColorRec(dRGB32).A)) div Width;
  End;

  If destBitmap.Map(TMapAccess.Write, bitmapData) then
  try
    Case destBitmap.PixelFormat of
      TPixelFormat.BGRA, TPixelFormat.RGBA:
      begin
        For Y := yOfs to yOfs+Height-1 do
        Begin
          tmpScanLine := bitmapData.GetScanline(Y);
          Move(gradientLine[0],tmpScanLine^[xOfs],Width*4);
        End;
      end;
      else
      Begin // Case else
        For Y := yOfs to yOfs+Height-1 do
        Begin
          tmpScanLine := bitmapData.GetScanline(Y);
          OptimizedAlphaColorToScanLine(@gradientLine[0],@tmpScanLine^[xOfs],Width,destBitmap.PixelFormat);
        End;
      End;
    End;
  finally
    destBitmap.Unmap(bitmapData);
  end;
end;


procedure GradientRectV(destBitmap : TBitmap; xOfs,yOfs,Width,Height : Integer; sRGB32,dRGB32 : TAlphaColor);
var
  bitmapData   : FMX.Graphics.TBitmapData;
  tmpByte      : Byte;
  tmpScanLine  : PAlphaColorArray;
  fColor       : TAlphaColor;
  tmpLine      : Array of TAlphaColor;
  Speed1       : Integer;
  Y,X          : Integer;
begin
  If yOfs+1 > destBitmap.Height-1 then Exit;

  // Switch Blue <-> Red if needed
  If destBitmap.PixelFormat = TPixelFormat.RGBA then
  begin
    tmpByte := TAlphaColorRec(sRGB32).R;
    TAlphaColorRec(sRGB32).R := TAlphaColorRec(sRGB32).B;
    TAlphaColorRec(sRGB32).B := tmpByte;
    tmpByte := TAlphaColorRec(dRGB32).R;
    TAlphaColorRec(dRGB32).R := TAlphaColorRec(dRGB32).B;
    TAlphaColorRec(dRGB32).B := tmpByte;
  end;

  If destBitmap.Map(TMapAccess.Write, bitmapData) then
  try
    Case destBitmap.PixelFormat of
      TPixelFormat.BGRA, TPixelFormat.RGBA:
      begin
        For Y := 0 to Height-1 do
        Begin
          tmpScanLine := bitmapData.GetScanline(Y+yOfs);
          Speed1 := ((Height-Y));
          TAlphaColorRec(fColor).R :=((Speed1*TAlphaColorRec(sRGB32).R) + (Y*TAlphaColorRec(dRGB32).R)) div Height;
          TAlphaColorRec(fColor).G :=((Speed1*TAlphaColorRec(sRGB32).G) + (Y*TAlphaColorRec(dRGB32).G)) div Height;
          TAlphaColorRec(fColor).B :=((Speed1*TAlphaColorRec(sRGB32).B) + (Y*TAlphaColorRec(dRGB32).B)) div Height;
          TAlphaColorRec(fColor).A :=((Speed1*TAlphaColorRec(sRGB32).A) + (Y*TAlphaColorRec(dRGB32).A)) div Height;
          For X := 0 to Width-1 do tmpScanLine^[xOfs+X] := fColor;
        End;
      end;
      else
      Begin // Case else
        SetLength(tmpLine,Width);
        For Y := 0 to Height-1 do
        Begin
          tmpScanLine := bitmapData.GetScanline(Y+yOfs);
          Speed1 := ((Height-Y));
          TAlphaColorRec(fColor).R :=((Speed1*TAlphaColorRec(sRGB32).R) + (Y*TAlphaColorRec(dRGB32).R)) div Height;
          TAlphaColorRec(fColor).G :=((Speed1*TAlphaColorRec(sRGB32).G) + (Y*TAlphaColorRec(dRGB32).G)) div Height;
          TAlphaColorRec(fColor).B :=((Speed1*TAlphaColorRec(sRGB32).B) + (Y*TAlphaColorRec(dRGB32).B)) div Height;
          TAlphaColorRec(fColor).A :=((Speed1*TAlphaColorRec(sRGB32).A) + (Y*TAlphaColorRec(dRGB32).A)) div Height;
          For X := 0 to Width-1 do tmpLine[X] := fColor;
          OptimizedAlphaColorToScanLine(@tmpLine[0],@tmpScanLine^[xOfs],Width,destBitmap.PixelFormat);
        End;
      End;
    End;
  finally
    destBitmap.Unmap(bitmapData);
  end;
end;


procedure MergeBitmap(sBitmap,mBitmap : TBitmap; xOfs,yOfs : Integer);
const
  MaxPixelCount  = 65536;
var
  sBitmapData  : TBitmapData;
  mBitmapData  : TBitmapData;
  tmpScanLineS : PAlphaColorArray;
  tmpScanLineM : PAlphaColorArray;
  tmpLineS     : Array of TAlphaColor;
  tmpLineM     : Array of TAlphaColor;
  X,Y          : Integer;
  sWidth       : Integer;
  sHeight      : Integer;
  mWidth       : Integer;
  mHeight      : Integer;
  Speed2       : Integer;
begin
  sWidth  := sBitmap.Width;
  sHeight := sBitmap.Height;
  mWidth  := mBitmap.Width;
  mHeight := mBitmap.Height;

  If (yOfs+sBitmap.Height > mBitmap.Height) or (sHeight <= 2) or (yOfs < 0) then Exit;

  If sBitmap.Map(TMapAccess.Read, sBitmapData) = True then
  try
    If mBitmap.Map(TMapAccess.Write, mBitmapData) = True then
    try
      Case sBitmap.PixelFormat of
        TPixelFormat.BGRA, TPixelFormat.RGBA:
        begin
          For Y := 0 to sHeight-1 do If (Y >= 0) and (Y < sHeight) and (Y+yOfs >= 0) and (Y+yOfs < mHeight) then
          Begin
            tmpScanLineS := sBitmapData.GetScanline(Y);
            tmpScanLineM := mBitmapData.GetScanline(Y+yOfs);
            For X := 0 to sWidth-1 do If (X >= 0) and (X < sWidth) and (X+xOfs >= 0) and (X+xOfs < mWidth) then
            Begin
              Speed2 := X+xOfs;
              TAlphaColorRec(tmpScanLineM^[Speed2]).R := ((TAlphaColorRec(tmpScanLineM^[Speed2]).R+TAlphaColorRec(tmpScanLineS^[X]).R)) shr 1;
              TAlphaColorRec(tmpScanLineM^[Speed2]).G := ((TAlphaColorRec(tmpScanLineM^[Speed2]).G+TAlphaColorRec(tmpScanLineS^[X]).G)) shr 1;
              TAlphaColorRec(tmpScanLineM^[Speed2]).B := ((TAlphaColorRec(tmpScanLineM^[Speed2]).B+TAlphaColorRec(tmpScanLineS^[X]).B)) shr 1;
              TAlphaColorRec(tmpScanLineM^[Speed2]).A := ((TAlphaColorRec(tmpScanLineM^[Speed2]).A+TAlphaColorRec(tmpScanLineS^[X]).A)) shr 1;
            End;
          End;
        end;
          else
        Begin // case else
          SetLength(tmpLineS,sWidth);
          SetLength(tmpLineM,sWidth);
          For Y := 0 to sHeight-1 do If (Y >= 0) and (Y < sHeight) and (Y+yOfs >= 0) and (Y+yOfs < mHeight) then
          Begin
            tmpScanLineS := sBitmapData.GetScanline(Y);
            tmpScanLineM := mBitmapData.GetScanline(Y+yOfs);

            OptimizedScanLineToAlphaColor(@tmpScanLineS^[   0],@tmpLineS[0],sWidth,sBitmap.PixelFormat);
            OptimizedScanLineToAlphaColor(@tmpScanLineM^[xOfs],@tmpLineM[0],sWidth,mBitmap.PixelFormat);

            For X := 0 to sWidth-1 do If (X >= 0) and (X < sWidth) and (X+xOfs >= 0) and (X+xOfs < mWidth) then
            Begin
              TAlphaColorRec(tmpLineM[X]).R := ((TAlphaColorRec(tmpLineM[X]).R+TAlphaColorRec(tmpLineS[X]).R)) shr 1;
              TAlphaColorRec(tmpLineM[X]).G := ((TAlphaColorRec(tmpLineM[X]).G+TAlphaColorRec(tmpLineS[X]).G)) shr 1;
              TAlphaColorRec(tmpLineM[X]).B := ((TAlphaColorRec(tmpLineM[X]).B+TAlphaColorRec(tmpLineS[X]).B)) shr 1;
              TAlphaColorRec(tmpLineM[X]).A := ((TAlphaColorRec(tmpLineM[X]).A+TAlphaColorRec(tmpLineS[X]).A)) shr 1;
            End;

            OptimizedAlphaColorToScanLine(@tmpLineM[0],@tmpScanLineM^[xOfs],sWidth,mBitmap.PixelFormat);
          End;
        End;
      End;
    finally
      mBitmap.Unmap(mBitmapData);
    end;
  finally
    sBitmap.Unmap(sBitmapData);
  end;
end;


end.
