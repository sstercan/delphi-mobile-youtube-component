program DemoYouTube;

uses
  System.StartUpCopy,
  FMX.MobilePreview,
  FMX.Forms,
  MainScreen in 'Units\MainScreen.pas' {Form3};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
