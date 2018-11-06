unit optimizedscanlineunit;

interface

uses
  FMX.Utils, FMX.Types, System.UITypes;

procedure OptimizedAlphaColorToScanline(Input: PAlphaColor; Output: Pointer; PixelCount: Integer; OutputFormat: TPixelFormat);
procedure OptimizedScanlineToAlphaColor(Input: Pointer; Output: PAlphaColor; PixelCount: Integer; InputFormat: TPixelFormat);

implementation


procedure OptimizedAlphaColorToScanline(Input: PAlphaColor; Output: Pointer; PixelCount: Integer; OutputFormat: TPixelFormat);
var
  InpData          : PAlphaColor;
  OutData          : Pointer;
  Index, DestPitch : Integer;
  tmpByte          : Byte;
begin
  Case OutputFormat of
    TPixelFormat.BGRA:
    begin
      // Same image color space we're using, just copy
      Move(Input^,Output^,PixelCount*4);
    end;
    TPixelFormat.RGBA:
    begin
      Move(Input^,Output^,PixelCount*4);
      // Convert BGRA to RGBA
      For Index := 0 to PixelCount-1 do
      begin
        tmpByte := TAlphaColorRec(PAlphaColorArray(Output)[Index]).R;
        TAlphaColorRec(PAlphaColorArray(Output)[Index]).R := TAlphaColorRec(PAlphaColorArray(Output)[Index]).B;
        TAlphaColorRec(PAlphaColorArray(Output)[Index]).B := tmpByte;
      end;
    end;
    else
    begin
      // Case else - other color formats
      DestPitch := PixelFormatBytes[OutputFormat];
      if DestPitch < 1 then
        Exit;

      InpData := Input;
      OutData := Output;

      for Index := 0 to PixelCount - 1 do
      begin
        AlphaColorToPixel(InpData^, OutData, OutputFormat);

        Inc(InpData);
        Inc(NativeInt(OutData), DestPitch);
      end;
    end;
  End;
end;


procedure OptimizedScanlineToAlphaColor(Input: Pointer; Output: PAlphaColor; PixelCount: Integer; InputFormat: TPixelFormat);
var
  InpMem          : Pointer;
  OutColor        : PAlphaColor;
  Index, SrcPitch : Integer;
  tmpByte         : Byte;
begin
  Case InputFormat of
    TPixelFormat.BGRA:
    begin
      // Same image color space we're using, just copy
      Move(Input^,Output^,PixelCount*4);
    end;
    TPixelFormat.RGBA:
    begin
      // Convert BGRA to RGBA
      Move(Input^,Output^,PixelCount*4);
      For Index := 0 to PixelCount-1 do
      begin
        tmpByte := TAlphaColorRec(PAlphaColorArray(Output)[Index]).R;
        TAlphaColorRec(PAlphaColorArray(Output)[Index]).R := TAlphaColorRec(PAlphaColorArray(Output)[Index]).B;
        TAlphaColorRec(PAlphaColorArray(Output)[Index]).B := tmpByte;
      end;
    end;
    else
    begin
      // Case else - other color formats
      SrcPitch := PixelFormatBytes[InputFormat];
      if SrcPitch < 1 then Exit;

      InpMem := Input;
      OutColor := Output;

      for Index := 0 to PixelCount - 1 do
      begin
        OutColor^ := PixelToAlphaColor(InpMem, InputFormat);

        Inc(NativeInt(InpMem), SrcPitch);
        Inc(OutColor);
      end;
    end;
  End;
end;


end.
