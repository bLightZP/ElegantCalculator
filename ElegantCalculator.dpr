program ElegantCalculator;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Types,
  mainUnit in 'mainUnit.pas' {MainForm},
  misc_utils in 'misc_utils.pas';

{$R *.res}

begin
  FMX.Types.GlobalUseGPUCanvas  := True; // 25->840fps! but messes with font rendering?!?

  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Portrait];
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
